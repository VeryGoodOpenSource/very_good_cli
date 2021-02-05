import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:io/ansi.dart';
import 'package:io/io.dart';
import 'package:mason/mason.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;

const _veryGoodCoreGitPath = GitPath(
  'git@github.com:VeryGoodOpenSource/very_good_cli.git',
  path: 'bricks/very_good_core',
);

// A valid Dart identifier that can be used for a package, i.e. no
// capital letters.
// https://dart.dev/guides/language/language-tour#important-concepts
final RegExp _identifierRegExp = RegExp('[a-z_][a-z0-9_]*');

/// A method which returns a [Future<MasonGenerator>] given a [GitPath].
typedef GeneratorBuilder = Future<MasonGenerator> Function(GitPath);

/// {@template create_command}
/// `very_good create` command creates a new very good flutter app.
/// {@endtemplate}
class CreateCommand extends Command<int> {
  /// {@macro create_command}
  CreateCommand({
    Logger logger,
    GeneratorBuilder generator,
  })  : _logger = logger ?? Logger(),
        _generator = generator ?? MasonGenerator.fromGitPath {
    argParser.addOption(
      'project-name',
      help: 'The project name for this new Flutter project. '
          'This must be a valid dart package name.',
      defaultsTo: null,
    );
  }

  final Logger _logger;
  final Future<MasonGenerator> Function(GitPath) _generator;

  @override
  final String description =
      'Creates a new very good flutter application in seconds.';

  @override
  final String name = 'create';

  /// [ArgResults] which can be overridden for testing.
  @visibleForTesting
  ArgResults argResultOverrides;

  ArgResults get _argResults => argResultOverrides ?? argResults;

  @override
  Future<int> run() async {
    final outputDirectory = _outputDirectory;
    final projectName = _projectName;
    final generateDone = _logger.progress('Bootstrapping');
    final generator = await _generator(_veryGoodCoreGitPath);
    final target = DirectoryGeneratorTarget(outputDirectory, _logger);
    final fileCount = await generator.generate(
      target,
      vars: {'project_name': projectName},
    );
    generateDone('Bootstrapping complete');
    _logger
      ..info(
        '${lightGreen.wrap('✓')} '
        'Generated $fileCount file(s):',
      )
      ..flush(_logger.success)
      ..alert('Created a Very Good App! 🦄');
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
