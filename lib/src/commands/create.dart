import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:io/io.dart';
import 'package:mason/mason.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import 'package:universal_io/io.dart';
import 'package:usage/usage_io.dart';
import 'package:very_good_analysis/very_good_analysis.dart';
import 'package:very_good_cli/src/command_runner.dart';
import 'package:very_good_cli/src/templates/templates.dart';

const _defaultOrgName = 'com.example.verygoodcore';
const _defaultDescription = 'A Very Good Project created by Very Good CLI.';
final _defaultTemplate = CoreTemplate();

final _templates = [_defaultTemplate, DartPkgTemplate(), FlutterPkgTemplate()];

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
        'org-name',
        help: 'The organization for this new project.',
        defaultsTo: _defaultOrgName,
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
      );
  }

  final Analytics _analytics;
  final Logger _logger;
  final Future<MasonGenerator> Function(MasonBundle) _generator;

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
    final generateDone = _logger.progress('Bootstrapping');
    final generator = await _generator(template.bundle);
    final fileCount = await generator.generate(
      DirectoryGeneratorTarget(outputDirectory, _logger),
      vars: {
        'project_name': projectName,
        'description': description,
        'org_name': orgName
      },
    );
    generateDone('Generated $fileCount file(s)');

    await template.onGenerateComplete(_logger, outputDirectory);

    unawaited(_analytics.sendEvent(
      'create',
      generator.id,
      label: generator.description,
    ));
    await _analytics.waitForLastPing(timeout: VeryGoodCommandRunner.timeout);

    return ExitCode.success.code;
  }

  /// Gets the project name.
  ///
  /// Uses the current directory path name
  /// if the `--project-name` option is not explicitly specified.
  String get _projectName {
    final projectName = _argResults['project-name'] ??
        path.basename(path.normalize(_outputDirectory.absolute.path));
    _validateProjectName(projectName);
    return projectName;
  }

  //// Gets the description for the project
  String get _description => _argResults['desc'] as String? ?? '';

  /// Gets the organization name.
  List<Map<String, String>> get _orgName {
    final orgName = _argResults['org-name'] as String? ?? _defaultOrgName;
    _validateOrgName(orgName);
    final segments = orgName.replaceAll(RegExp(r'-|_'), ' ').split('.');
    final org = <Map<String, String>>[];
    for (var i = 0; i < segments.length; i++) {
      final segment = segments[i];
      org.add(
        {'value': segment, 'separator': i == segments.length - 1 ? '' : '.'},
      );
    }
    return org;
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
      throw UsageException(
        '"$name" is not a valid org name.\n\n'
        'A valid org name has at least 2 parts separated by "."\n'
        'Each part must start with a letter and only include '
        'alphanumeric characters (A-Z, a-z, 0-9), underscores (_), '
        'and hyphens (-)\n'
        '(ex. very.good.org)',
        usage,
      );
    }
  }

  void _validateProjectName(String name) {
    final isValidProjectName = _isValidPackageName(name);
    if (!isValidProjectName) {
      throw UsageException(
        '"$name" is not a valid package name.\n\n'
        'See https://dart.dev/tools/pub/pubspec#name for more information.',
        usage,
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
      throw UsageException(
        'No option specified for the output directory.',
        usage,
      );
    }

    if (args.length > 1) {
      throw UsageException('Multiple output directories specified.', usage);
    }
  }
}
