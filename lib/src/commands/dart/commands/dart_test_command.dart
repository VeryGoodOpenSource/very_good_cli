import 'dart:io';
import 'dart:math';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:mason/mason.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import 'package:very_good_cli/src/cli/cli.dart';

/// Signature for the [Dart.installed] method.
typedef DartInstalledCommand = Future<bool> Function({required Logger logger});

/// Signature for the [Dart.test] method.
typedef DartTestCommandCall =
    Future<List<int>> Function({
      required Logger logger,
      String cwd,
      bool recursive,
      bool collectCoverage,
      bool optimizePerformance,
      double? minCoverage,
      String? excludeFromCoverage,
      String? randomSeed,
      bool? forceAnsi,
      List<String>? arguments,
      void Function(String)? stdout,
      void Function(String)? stderr,
    });

/// {@template dart_test_command}
/// `very_good dart test` command for running dart tests.
/// {@endtemplate}
class DartTestCommand extends Command<int> {
  /// {@macro packages_command}
  DartTestCommand({
    required Logger logger,
    DartTestCommandCall? dartTest,
    DartInstalledCommand? dartInstalled,
  }) : _logger = logger,
       _dartTest = dartTest ?? Dart.test,
       _dartInstalled = dartInstalled ?? Dart.installed {
    argParser
      ..addFlag(
        'coverage',
        help: 'Whether to collect coverage information.',
        negatable: false,
      )
      ..addFlag(
        'recursive',
        abbr: 'r',
        help: 'Run tests recursively for all nested packages.',
        negatable: false,
      )
      ..addFlag(
        'optimization',
        defaultsTo: true,
        help: 'Whether to apply optimizations for test performance.',
      )
      ..addOption(
        'concurrency',
        abbr: 'j',
        defaultsTo: '4',
        help: 'The number of concurrent test suites run.',
      )
      ..addOption(
        'tags',
        abbr: 't',
        help: 'Run only tests associated with the specified tags.',
      )
      ..addOption(
        'exclude-coverage',
        help:
            'A glob which will be used to exclude files that match from the '
            'coverage.',
      )
      ..addOption(
        'exclude-tags',
        abbr: 'x',
        help: 'Run only tests that do not have the specified tags.',
      )
      ..addOption(
        'min-coverage',
        help: 'Whether to enforce a minimum coverage percentage.',
      )
      ..addOption(
        'test-randomize-ordering-seed',
        help:
            'The seed to randomize the execution order of test cases '
            'within test files.',
      )
      ..addFlag(
        'force-ansi',
        defaultsTo: null,
        help:
            'Whether to force ansi output. If not specified, '
            'it will maintain the default behavior based on stdout and stderr.',
        negatable: false,
      );
  }

  final Logger _logger;
  final DartTestCommandCall _dartTest;
  final DartInstalledCommand _dartInstalled;

  @override
  String get description => 'Run tests in a Dart project.';

  @override
  String get name => 'test';

  /// [ArgResults] which can be overridden for testing.
  @visibleForTesting
  ArgResults? argResultOverrides;

  ArgResults get _argResults => argResultOverrides ?? argResults!;

  @override
  Future<int> run() async {
    final targetPath = path.normalize(Directory.current.absolute.path);
    final pubspec = File(path.join(targetPath, 'pubspec.yaml'));
    final recursive = _argResults['recursive'] as bool;

    if (!recursive && !pubspec.existsSync()) {
      _logger.err('''
Could not find a pubspec.yaml in $targetPath.
This command should be run from the root of your Dart project.''');
      return ExitCode.noInput.code;
    }

    final concurrency = _argResults['concurrency'] as String;
    final collectCoverage = _argResults['coverage'] as bool;
    final minCoverage = double.tryParse(
      _argResults['min-coverage'] as String? ?? '',
    );
    final excludeTags = _argResults['exclude-tags'] as String?;
    final tags = _argResults['tags'] as String?;
    final isDartInstalled = await _dartInstalled(logger: _logger);
    final excludeFromCoverage = _argResults['exclude-coverage'] as String?;
    final randomOrderingSeed =
        _argResults['test-randomize-ordering-seed'] as String?;
    final randomSeed = randomOrderingSeed == 'random'
        ? Random().nextInt(4294967295).toString()
        : randomOrderingSeed;
    final optimizePerformance = _argResults['optimization'] as bool;
    final forceAnsi = _argResults['force-ansi'] as bool?;
    final rest = _argResults.rest;

    if (isDartInstalled) {
      try {
        final results = await _dartTest(
          optimizePerformance:
              optimizePerformance && !TestCLIRunner.isTargettingTestFiles(rest),
          recursive: recursive,
          logger: _logger,
          stdout: _logger.write,
          stderr: _logger.err,
          collectCoverage: collectCoverage || minCoverage != null,
          minCoverage: minCoverage,
          excludeFromCoverage: excludeFromCoverage,
          randomSeed: randomSeed,
          forceAnsi: forceAnsi,
          arguments: [
            if (excludeTags != null) ...['-x', excludeTags],
            if (tags != null) ...['-t', tags],
            ...['-j', concurrency],
            ...rest,
          ],
        );
        if (results.any((code) => code != ExitCode.success.code)) {
          return ExitCode.unavailable.code;
        }
      } on MinCoverageNotMet catch (e) {
        TestCLIRunner.handleMinCoverageNotMet(
          logger: _logger,
          minCoverage: minCoverage,
          e: e,
        );
        return ExitCode.unavailable.code;
      } on Exception catch (error) {
        _logger.err('$error');
        return ExitCode.unavailable.code;
      }
    }
    return ExitCode.success.code;
  }
}
