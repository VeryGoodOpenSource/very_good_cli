import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:io/ansi.dart';
import 'package:io/io.dart';
import 'package:mason/mason.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import 'package:universal_io/io.dart';
import 'package:usage/usage_io.dart';
import 'package:very_good_analysis/very_good_analysis.dart';
import 'package:very_good_cli/src/command_runner.dart';
import 'package:very_good_cli/src/flutter_cli.dart';
import 'package:very_good_cli/src/templates/very_good_core_bundle.dart';

const _defaultOrgName = 'com.example.verygoodcore';

// A valid Dart identifier that can be used for a package, i.e. no
// capital letters.
// https://dart.dev/guides/language/language-tour#important-concepts
final RegExp _identifierRegExp = RegExp('[a-z_][a-z0-9_]*');
final RegExp _orgNameRegExp =
    RegExp(r'[a-zA-Z0-9-]+\.[a-zA-Z0-9-]+\.[a-zA-Z0-9-]+');

/// A method which returns a [Future<MasonGenerator>] given a [MasonBundle].
typedef GeneratorBuilder = Future<MasonGenerator> Function(MasonBundle);

/// {@template create_command}
/// `very_good create` command creates a new very good flutter app.
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
        help: 'The project name for this new Flutter project. '
            'This must be a valid dart package name.',
        defaultsTo: null,
      )
      ..addOption(
        'org-name',
        help: 'The organization for this new Flutter project.',
        defaultsTo: 'com.example.verygoodcore',
      );
  }

  final Analytics _analytics;
  final Logger _logger;
  final Future<MasonGenerator> Function(MasonBundle) _generator;

  @override
  String get description =>
      'Creates a new very good flutter project in the specified directory.';

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
    final orgName = _orgName;
    final generateDone = _logger.progress('Bootstrapping');
    final generator = await _generator(veryGoodCoreBundle);
    final fileCount = await generator.generate(
      DirectoryGeneratorTarget(outputDirectory, _logger),
      vars: {'project_name': projectName, 'org_name': orgName},
    );
    generateDone('Generated $fileCount file(s)');

    final isFlutterInstalled = await Flutter.installed();
    if (isFlutterInstalled) {
      final installDependenciesDone = _logger.progress(
        'Running "flutter packages get" in ${outputDirectory.path}',
      );
      await Flutter.packagesGet(outputDirectory.path);
      installDependenciesDone();
    }

    _logSummary();

    unawaited(_analytics.sendEvent(
      'create',
      generator.id,
      label: generator.description,
    ));
    await _analytics.waitForLastPing(timeout: VeryGoodCommandRunner.timeout);

    return ExitCode.success.code;
  }

  void _logSummary() {
    _logger
      ..info('\n')
      ..alert('Created a Very Good App! 🦄')
      ..info('\n')
      ..info(
        lightGray.wrap(
          '''+----------------------------------------------------+
| Looking for more features?                         |
| We have an enterprise-grade solution for companies |
| called Very Good Start.                            |
|                                                    |
| For more info visit:                               |
| https://verygood.ventures/solution/very-good-start |
+----------------------------------------------------+''',
        ),
      );
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

  /// Gets the organization name.
  List<String> get _orgName {
    if (_argResults['org-name'] == null) return _defaultOrgName.split('.');

    final orgName = _argResults['org-name'] as String;
    _validateOrgName(orgName);
    return orgName.split('.');
  }

  void _validateOrgName(String name) {
    final isValidOrgName = _isValidOrgName(name);
    if (!isValidOrgName) {
      throw UsageException(
        '"$name" is not a valid org name.\n\n'
        'A valid org name has 3 parts separated by "."'
        'and only includes alphanumeric characters and underscores' 
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
    final match = _orgNameRegExp.matchAsPrefix(name);
    return match != null && match.end == name.length;
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
