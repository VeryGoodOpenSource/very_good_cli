import 'dart:io';
import 'dart:math';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:mason/mason.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import 'package:very_good_cli/src/cli/cli.dart';

/// Options for configuring the Dart test command.
class DartTestOptions {
  DartTestOptions._({
    required this.concurrency,
    required this.collectCoverage,
    required this.minCoverage,
    required this.excludeTags,
    required this.tags,
    required this.excludeFromCoverage,
    required this.randomSeed,
    required this.optimizePerformance,
    required this.failFast,
    required this.forceAnsi,
    required this.platform,
    required this.rest,
    required this.reportOn,
  });

  /// Parses [ArgResults] into a [DartTestOptions] instance.
  factory DartTestOptions.parse(ArgResults argResults) {
    final concurrency = argResults['concurrency'] as String;
    final collectCoverage = argResults['coverage'] as bool;
    final minCoverage = double.tryParse(
      argResults['min-coverage'] as String? ?? '',
    );
    final excludeTags = argResults['exclude-tags'] as String?;
    final tags = argResults['tags'] as String?;
    final excludeFromCoverage = argResults['exclude-coverage'] as String?;
    final randomOrderingSeed =
        argResults['test-randomize-ordering-seed'] as String?;
    final randomSeed = randomOrderingSeed == 'random'
        ? Random().nextInt(4294967295).toString()
        : randomOrderingSeed;
    final optimizePerformance = argResults['optimization'] as bool;
    final failFast = argResults['fail-fast'] as bool;
    final forceAnsi = argResults['force-ansi'] as bool?;
    final platform = argResults['platform'] as String?;
    final reportOn = argResults['report-on'] as String?;
    final rest = argResults.rest;

    return DartTestOptions._(
      concurrency: concurrency,
      collectCoverage: collectCoverage,
      minCoverage: minCoverage,
      excludeTags: excludeTags,
      tags: tags,
      excludeFromCoverage: excludeFromCoverage,
      randomSeed: randomSeed,
      optimizePerformance: optimizePerformance,
      failFast: failFast,
      forceAnsi: forceAnsi,
      platform: platform,
      reportOn: reportOn,
      rest: rest,
    );
  }

  /// The number of concurrent test suites run.
  final String concurrency;

  /// Whether to collect coverage information.
  final bool collectCoverage;

  /// Whether to enforce a minimum coverage percentage.
  final double? minCoverage;

  /// Run only tests that do not have the specified tags.
  final String? excludeTags;

  /// Run only tests associated with the specified tags.
  final String? tags;

  /// A glob which will be used to exclude files that match from the coverage.
  final String? excludeFromCoverage;

  /// The seed to randomize the execution order of test cases within test files.
  final String? randomSeed;

  /// Whether to apply optimizations for test performance.
  final bool optimizePerformance;

  /// Whether to stop running tests after the first failure.
  final bool failFast;

  /// Whether to force ansi output. If not specified, it will maintain the
  /// default behavior based on stdout and stderr.
  final bool? forceAnsi;

  /// The platform to run tests on (e.g., 'chrome', 'vm').
  final String? platform;

  /// An optional file path to report coverage information to.
  final String? reportOn;

  /// The remaining arguments passed to the `dart test` command.
  final List<String> rest;
}

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
      String? reportOn,
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
        help:
            'Whether to apply optimizations for test performance.\n'
            'Automatically disabled when --platform is specified.\n'
            'Add the `skip_very_good_optimization` tag to specific test files '
            'to disable them individually.',
      )
      ..addOption(
        'concurrency',
        abbr: 'j',
        defaultsTo: '4',
        help:
            'The number of concurrent test suites run. '
            'Automatically set to 1 when --platform is specified.',
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
            "coverage (e.g. '**/*.g.dart').",
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
        'fail-fast',
        help: 'Stop running tests after the first failure.',
        negatable: false,
      )
      ..addFlag(
        'force-ansi',
        defaultsTo: null,
        help:
            'Whether to force ansi output. If not specified, '
            'it will maintain the default behavior based on stdout and stderr.',
        negatable: false,
      )
      ..addOption(
        'report-on',
        help:
            'An optional file path to report coverage information to. '
            'This should be a path relative to the current working directory.',
        valueHelp: 'lib/',
      )
      ..addOption(
        'platform',
        help: 'The platform to run tests on. ',
        valueHelp: 'chrome|vm',
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

    final isDartInstalled = await _dartInstalled(logger: _logger);

    final options = DartTestOptions.parse(_argResults);

    if (isDartInstalled) {
      try {
        final results = await _dartTest(
          optimizePerformance:
              options.optimizePerformance &&
              !TestCLIRunner.isTargettingTestFiles(options.rest) &&
              // Disabled optimization when platform is specified
              // https://github.com/VeryGoodOpenSource/very_good_cli/issues/1363
              options.platform == null,
          recursive: recursive,
          logger: _logger,
          stdout: _logger.write,
          stderr: _logger.err,
          collectCoverage:
              options.collectCoverage || options.minCoverage != null,
          minCoverage: options.minCoverage,
          excludeFromCoverage: options.excludeFromCoverage,
          randomSeed: options.randomSeed,
          forceAnsi: options.forceAnsi,
          arguments: [
            if (options.excludeTags != null) ...['-x', options.excludeTags!],
            if (options.tags != null) ...['-t', options.tags!],
            if (options.failFast) '--fail-fast',
            if (options.platform != null) ...['--platform', options.platform!],
            if (options.platform == null) ...['-j', options.concurrency],
            ...options.rest,
          ],
          reportOn: options.reportOn,
        );
        if (results.any((code) => code != ExitCode.success.code)) {
          return ExitCode.unavailable.code;
        }
      } on MinCoverageNotMet catch (e) {
        TestCLIRunner.handleMinCoverageNotMet(
          logger: _logger,
          minCoverage: options.minCoverage,
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
