import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:mason/mason.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import 'package:universal_io/io.dart';
import 'package:usage/usage_io.dart';
import 'package:very_good_analysis/very_good_analysis.dart';
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
];

final _defaultTemplate = _templates.first;

// A valid Dart identifier that can be used for a package, i.e. no
// capital letters.
// https://dart.dev/guides/language/language-tour#important-concepts
final RegExp _identifierRegExp = RegExp('[a-z_][a-z0-9_]*');
final RegExp _orgNameRegExp = RegExp(r'^[a-zA-Z][\w-]*(\.[a-zA-Z][\w-]*)+$');

/// A method which returns a [Future<MasonGenerator>] given a [MasonBundle].
typedef GeneratorBuilder = Future<MasonGenerator> Function(MasonBundle);

/// {@template create_command}
/// `very_good create` command creates code from various built-in templates.
/// {@endtemplate}
class CreateCommand extends Command<int> {
  /// {@macro create_command}
  CreateCommand({
    required Analytics analytics,
    Logger? logger,
    GeneratorBuilder? generator,
  })  : _analytics = analytics,
        _logger = logger ?? Logger(),
        _generator = generator ?? MasonGenerator.fromBundle {
    argParser
      ..addOption(
        'project-name',
        help: 'The project name for this new project. '
            'This must be a valid dart package name.',
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
      );
  }

  final Analytics _analytics;
  final Logger _logger;
  final GeneratorBuilder _generator;

  @override
  String get description =>
      'Creates a new very good project in the specified directory.';

  @override
  String get summary => '$invocation\n$description';

  @override
  String get name => 'create';

  @override
  String get invocation => 'very_good create <output directory>';

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
    final generator = await _generator(template.bundle);
    final android = _argResults['android'] as String? ?? 'true';
    final ios = _argResults['ios'] as String? ?? 'true';
    final web = _argResults['web'] as String? ?? 'true';
    final linux = _argResults['linux'] as String? ?? 'true';
    final macos = _argResults['macos'] as String? ?? 'true';
    final windows = _argResults['windows'] as String? ?? 'true';
    final executableName =
        _argResults['executable-name'] as String? ?? projectName;
    var vars = <String, dynamic>{
      'project_name': projectName,
      'description': description,
      'executable_name': executableName,
      'org_name': orgName,
      'android': android.toBool(),
      'ios': ios.toBool(),
      'web': web.toBool(),
      'linux': linux.toBool(),
      'macos': macos.toBool(),
      'windows': windows.toBool(),
    };
    await generator.hooks.preGen(vars: vars, onVarsChanged: (v) => vars = v);
    final files = await generator.generate(
      DirectoryGeneratorTarget(outputDirectory),
      vars: vars,
      logger: _logger,
    );
    generateProgress.complete('Generated ${files.length} file(s)');

    await template.onGenerateComplete(_logger, outputDirectory);

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

  /// Gets the project name.
  ///
  /// Uses the current directory path name
  /// if the `--project-name` option is not explicitly specified.
  String get _projectName {
    final projectName = _argResults['project-name'] as String? ??
        path.basename(path.normalize(_outputDirectory.absolute.path));
    _validateProjectName(projectName);
    return projectName;
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

  void _validateProjectName(String name) {
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
    final rest = _argResults.rest;
    _validateOutputDirectoryArg(rest);
    return Directory(rest.first);
  }

  void _validateOutputDirectoryArg(List<String> args) {
    if (args.isEmpty) {
      usageException('No option specified for the output directory.');
    }

    if (args.length > 1) {
      usageException('Multiple output directories specified.');
    }
  }
}

extension on String {
  bool toBool() => toLowerCase() == 'true';
}
