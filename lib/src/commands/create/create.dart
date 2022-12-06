import 'dart:async';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:mason/mason.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import 'package:universal_io/io.dart';
import 'package:usage/usage_io.dart';
import 'package:very_good_cli/src/command_runner.dart';
import 'package:very_good_cli/src/commands/create/templates/templates.dart';

const _defaultOrgName = 'com.example.verygoodcore';
const _defaultDescription = 'A Very Good Project created by Very Good CLI.';

final _templates = [
  VeryGoodCoreTemplate(),
  DartPkgTemplate(),
  FlutterPkgTemplate(),
  FlutterPluginTemplate(),
  VeryGoodDartCLITemplate(),
  VeryGoodDocsSiteTemplate(),
  VeryGoodFlameGameTemplate(),
];

final _defaultTemplate = _templates.first;

// A valid Dart identifier that can be used for a package, i.e. no
// capital letters.
// https://dart.dev/guides/language/language-tour#important-concepts
final RegExp _identifierRegExp = RegExp('[a-z_][a-z0-9_]*');
final RegExp _orgNameRegExp = RegExp(r'^[a-zA-Z][\w-]*(\.[a-zA-Z][\w-]*)+$');

/// A method which returns a [Future<MasonGenerator>] given a [MasonBundle].
typedef MasonGeneratorFromBundle = Future<MasonGenerator> Function(MasonBundle);

/// A method which returns a [Future<MasonGenerator>] given a [Brick].
typedef MasonGeneratorFromBrick = Future<MasonGenerator> Function(Brick);

/// {@template create_command}
/// `very_good create` command creates code from various built-in templates.
/// {@endtemplate}
class CreateCommand extends Command<int> {
  /// {@macro create_command}
  CreateCommand({
    required Analytics analytics,
    required Logger logger,
    MasonGeneratorFromBundle? generatorFromBundle,
    MasonGeneratorFromBrick? generatorFromBrick,
  })  : _analytics = analytics,
        _logger = logger,
        _generatorFromBundle = generatorFromBundle ?? MasonGenerator.fromBundle,
        _generatorFromBrick = generatorFromBrick ?? MasonGenerator.fromBrick {
    argParser
      ..addOption(
        'output-directory',
        abbr: 'o',
        help: 'The desired output directory when creating a new project.',
      )
      ..addOption(
        'desc',
        help: 'The description for this new project.',
        defaultsTo: _defaultDescription,
      )
      ..addOption(
        'executable-name',
        help: 'Used by the dart_cli template, the CLI executable name '
            '(defaults to the project name)',
      )
      ..addOption(
        'org-name',
        help: 'The organization for this new project.',
        defaultsTo: _defaultOrgName,
        aliases: ['org'],
      )
      ..addOption(
        'template',
        abbr: 't',
        help: 'The template used to generate this new project.',
        defaultsTo: _defaultTemplate.name,
        allowed: _templates.map((element) => element.name).toList(),
        allowedHelp: _templates.fold<Map<String, String>>(
          {},
          (previousValue, element) => {
            ...previousValue,
            element.name: element.help,
          },
        ),
      )
      ..addOption(
        'android',
        help: 'The plugin supports the Android platform.',
        defaultsTo: 'true',
      )
      ..addOption(
        'ios',
        help: 'The plugin supports the iOS platform.',
        defaultsTo: 'true',
      )
      ..addOption(
        'web',
        help: 'The plugin supports the Web platform.',
        defaultsTo: 'true',
      )
      ..addOption(
        'linux',
        help: 'The plugin supports the Linux platform.',
        defaultsTo: 'true',
      )
      ..addOption(
        'macos',
        help: 'The plugin supports the macOS platform.',
        defaultsTo: 'true',
      )
      ..addOption(
        'windows',
        help: 'The plugin supports the Windows platform.',
        defaultsTo: 'true',
      )
      ..addOption(
        'application-id',
        help: 'The bundle identifier on iOS or application id on Android. '
            '(defaults to <org-name>.<project-name>)',
      )
      ..addFlag(
        'publishable',
        negatable: false,
        help: 'Whether the generated project is intended to be published '
            '(Does not affect flutter application templates)',
      );
  }

  final Analytics _analytics;
  final Logger _logger;
  final MasonGeneratorFromBundle _generatorFromBundle;
  final MasonGeneratorFromBrick _generatorFromBrick;

  @override
  String get description =>
      'Creates a new very good project in the specified directory.';

  @override
  String get summary => '$invocation\n$description';

  @override
  String get name => 'create';

  @override
  String get invocation => 'very_good create <project name>';

  /// [ArgResults] which can be overridden for testing.
  @visibleForTesting
  ArgResults? argResultOverrides;

  ArgResults get _argResults => argResultOverrides ?? argResults!;

  @override
  Future<int> run() async {
    final outputDirectory = _outputDirectory;
    final projectName = _projectName;
    final description = _description;
    final orgName = _orgName;
    final template = _template;
    final generateProgress = _logger.progress('Bootstrapping');
    final generator = await _getGeneratorForTemplate(template);
    final android = _argResults['android'] as String? ?? 'true';
    final ios = _argResults['ios'] as String? ?? 'true';
    final web = _argResults['web'] as String? ?? 'true';
    final linux = _argResults['linux'] as String? ?? 'true';
    final macos = _argResults['macos'] as String? ?? 'true';
    final windows = _argResults['windows'] as String? ?? 'true';
    final executableName =
        _argResults['executable-name'] as String? ?? projectName;
    final applicationId = _argResults['application-id'] as String?;
    final publishable = _argResults['publishable'] as bool?;
    var vars = <String, dynamic>{
      'project_name': projectName,
      'description': description,
      'executable_name': executableName,
      'org_name': orgName,
      if (applicationId != null) 'application_id': applicationId,
      'platforms': <String>[
        if (android.toBool()) 'android',
        if (ios.toBool()) 'ios',
        if (web.toBool()) 'web',
        if (linux.toBool()) 'linux',
        if (macos.toBool()) 'macos',
        if (windows.toBool()) 'windows',
      ],
      if (publishable != null) 'publishable': publishable,
    };
    await generator.hooks.preGen(vars: vars, onVarsChanged: (v) => vars = v);
    final target = DirectoryGeneratorTarget(outputDirectory);
    final files = await generator.generate(target, vars: vars, logger: _logger);
    generateProgress.complete('Generated ${files.length} file(s)');

    await template.onGenerateComplete(
      _logger,
      Directory(path.join(target.dir.path, projectName)),
    );

    unawaited(
      _analytics.sendEvent(
        'create',
        generator.id,
        label: generator.description,
      ),
    );
    await _analytics.waitForLastPing(timeout: VeryGoodCommandRunner.timeout);

    return ExitCode.success.code;
  }

  Future<MasonGenerator> _getGeneratorForTemplate(Template template) async {
    try {
      final brick = Brick.version(
        name: template.bundle.name,
        version: '^${template.bundle.version}',
      );
      _logger.detail(
        '''Building generator from brick: ${brick.name} ${brick.location.version}''',
      );
      return await _generatorFromBrick(brick);
    } catch (_) {
      _logger.detail('Building generator from brick failed: $_');
    }
    _logger.detail(
      '''Building generator from bundle ${template.bundle.name} ${template.bundle.version}''',
    );
    return _generatorFromBundle(template.bundle);
  }

  /// Gets the project name.
  ///
  /// `very_good create <project name>`
  String get _projectName {
    final args = _argResults.rest;
    _validateProjectName(args);
    return args.first;
  }

  /// Gets the description for the project.
  String get _description => _argResults['desc'] as String? ?? '';

  /// Gets the organization name.
  String get _orgName {
    final orgName = _argResults['org-name'] as String? ?? _defaultOrgName;
    _validateOrgName(orgName);
    return orgName;
  }

  Template get _template {
    final templateName = _argResults['template'] as String?;

    return _templates.firstWhere(
      (element) => element.name == templateName,
      orElse: () => _defaultTemplate,
    );
  }

  void _validateOrgName(String name) {
    _logger.detail('Validating org name; $name');
    final isValidOrgName = _isValidOrgName(name);
    if (!isValidOrgName) {
      usageException(
        '"$name" is not a valid org name.\n\n'
        'A valid org name has at least 2 parts separated by "."\n'
        'Each part must start with a letter and only include '
        'alphanumeric characters (A-Z, a-z, 0-9), underscores (_), '
        'and hyphens (-)\n'
        '(ex. very.good.org)',
      );
    }
  }

  void _validateProjectName(List<String> args) {
    _logger.detail('Validating project name; args: $args');

    if (args.isEmpty) {
      usageException('No option specified for the project name.');
    }

    if (args.length > 1) {
      usageException('Multiple project names specified.');
    }

    final name = args.first;
    final isValidProjectName = _isValidPackageName(name);
    if (!isValidProjectName) {
      usageException(
        '"$name" is not a valid package name.\n\n'
        'See https://dart.dev/tools/pub/pubspec#name for more information.',
      );
    }
  }

  bool _isValidOrgName(String name) {
    return _orgNameRegExp.hasMatch(name);
  }

  bool _isValidPackageName(String name) {
    final match = _identifierRegExp.matchAsPrefix(name);
    return match != null && match.end == name.length;
  }

  Directory get _outputDirectory {
    final directory = _argResults['output-directory'] as String? ?? '.';
    return Directory(directory);
  }
}

extension on String {
  bool toBool() => toLowerCase() == 'true';
}
