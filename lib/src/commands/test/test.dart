import 'dart:math';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:mason/mason.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import 'package:universal_io/io.dart';
import 'package:very_good_cli/src/cli/cli.dart';
import 'package:very_good_cli/src/very_good_config/very_good_config.dart';

/// Options for configuring the Flutter test command.
class FlutterTestOptions {
  FlutterTestOptions._({
    required this.concurrency,
    required this.collectCoverage,
    required this.minCoverage,
    required this.showUncovered,
    required this.excludeTags,
    required this.tags,
    required this.excludeFromCoverage,
    required this.collectCoverageFrom,
    required this.randomSeed,
    required this.optimizePerformance,
    required this.updateGoldens,
    required this.failFast,
    required this.forceAnsi,
    required this.dartDefine,
    required this.dartDefineFromFile,
    required this.platform,
    required this.reportOn,
    required this.runSkipped,
    required this.flavor,
    required this.timeout,
    required this.fileReporter,
    required this.shardIndex,
    required this.totalShards,
    required this.rest,
  });

  /// Parses [ArgResults] into a [FlutterTestOptions] instance.
  ///
  /// When [config] is provided, its values are used as defaults for any
  /// option that was not explicitly parsed on the command line.
  factory FlutterTestOptions.parse(
    ArgResults argResults, {
    VeryGoodConfig config = VeryGoodConfig.empty,
  }) {
    final testConfig = config.test;

    final concurrency = argResults.resolve(
      'concurrency',
      testConfig.concurrency,
    );
    final collectCoverage = argResults.resolve('coverage', testConfig.coverage);
    final minCoverage = argResults.resolve<String?>(
      'min-coverage',
      testConfig.minCoverage,
    );
    final effectiveMinCoverage = double.tryParse(minCoverage ?? '');
    final showUncovered = argResults.resolve(
      'show-uncovered',
      testConfig.showUncovered,
    );
    final excludeTags = argResults.resolve<String?>(
      'exclude-tags',
      testConfig.excludeTags,
    );
    final tags = argResults.resolve<String?>('tags', testConfig.tags);
    final excludeFromCoverage = argResults.resolve<String?>(
      'exclude-coverage',
      testConfig.excludeCoverage,
    );
    final collectCoverageFrom = argResults.resolve<String>(
      'collect-coverage-from',
      testConfig.collectCoverageFrom,
      fallbackValue: 'imports',
    );
    final effectiveCollectCoverageFrom = CoverageCollectionMode.fromString(
      collectCoverageFrom,
    );
    final randomOrderingSeed =
        argResults['test-randomize-ordering-seed'] as String?;
    final randomSeed = randomOrderingSeed == 'random'
        ? Random().nextInt(4294967295).toString()
        : randomOrderingSeed;
    final optimizePerformance = argResults.resolve(
      'optimization',
      testConfig.optimization,
    );
    final updateGoldens = argResults.resolve(
      'update-goldens',
      testConfig.updateGoldens,
    );
    final failFast = argResults.resolve('fail-fast', testConfig.failFast);
    final forceAnsi = argResults['force-ansi'] as bool?;
    final dartDefine = argResults.resolve<List<String>?>(
      'dart-define',
      testConfig.dartDefine,
    );
    final dartDefineFromFile = argResults.resolve<List<String>?>(
      'dart-define-from-file',
      testConfig.dartDefineFromFile,
    );
    final platform = argResults.resolve<String?>(
      'platform',
      testConfig.platform,
    );
    final reportOn = argResults.resolve<List<String>>(
      'report-on',
      testConfig.reportOn,
    );
    final effectiveReportOn = reportOn
        .expand((e) => e.split(RegExp(r'[,\s]+')))
        .where((e) => e.isNotEmpty)
        .toList();

    final runSkipped = argResults.resolve('run-skipped', testConfig.runSkipped);
    final flavor = argResults.resolve<String?>('flavor', testConfig.flavor);
    final timeout = argResults.resolve<String?>('timeout', testConfig.timeout);
    final timeoutSeconds = int.tryParse(timeout ?? '');
    final effectiveTimeout = timeoutSeconds != null
        ? Duration(seconds: timeoutSeconds)
        : null;
    final fileReporter = argResults.resolve<String?>(
      'file-reporter',
      testConfig.fileReporter,
    );
    final shardIndex = argResults['shard-index'] as String?;
    final totalShards = argResults['total-shards'] as String?;
    final rest = argResults.rest;

    return FlutterTestOptions._(
      concurrency: concurrency,
      collectCoverage: collectCoverage,
      minCoverage: effectiveMinCoverage,
      showUncovered: showUncovered,
      excludeTags: excludeTags,
      tags: tags,
      excludeFromCoverage: excludeFromCoverage,
      collectCoverageFrom: effectiveCollectCoverageFrom,
      randomSeed: randomSeed,
      optimizePerformance: optimizePerformance,
      updateGoldens: updateGoldens,
      failFast: failFast,
      forceAnsi: forceAnsi,
      dartDefine: dartDefine,
      dartDefineFromFile: dartDefineFromFile,
      platform: platform,
      reportOn: effectiveReportOn,
      runSkipped: runSkipped,
      flavor: flavor,
      timeout: effectiveTimeout,
      fileReporter: fileReporter,
      shardIndex: shardIndex,
      totalShards: totalShards,
      rest: rest,
    );
  }

  /// The number of concurrent test suites run.
  final String concurrency;

  /// Whether to collect coverage information.
  final bool collectCoverage;

  /// Whether to enforce a minimum coverage percentage.
  final double? minCoverage;

  /// Whether to show uncovered lines when coverage is below 100%.
  final bool showUncovered;

  /// Run only tests that do not have the specified tags.
  final String? excludeTags;

  /// Run only tests associated with the specified tags.
  final String? tags;

  /// A glob which will be used to exclude files that match from the coverage.
  final String? excludeFromCoverage;

  /// How to collect coverage.
  final CoverageCollectionMode collectCoverageFrom;

  /// The seed to randomize the execution order of test cases within test files.
  final String? randomSeed;

  /// Whether to apply optimizations for test performance.
  final bool optimizePerformance;

  /// Whether "matchesGoldenFile()" calls within your test methods should update
  /// the golden files.
  final bool updateGoldens;

  /// Whether to stop running tests after the first failure.
  final bool failFast;

  /// Whether to force ansi output. If not specified, it will maintain the
  /// default behavior based on stdout and stderr.
  final bool? forceAnsi;

  /// Optional list of dart defines
  final List<String>? dartDefine;

  /// Optional list of dart define from files
  final List<String>? dartDefineFromFile;

  /// The platform to run tests on (e.g., 'chrome', 'vm', 'android', 'ios').
  final String? platform;

  /// An optional list of file paths to report coverage information to.
  final List<String> reportOn;

  /// Whether to run skipped tests instead of skipping them.
  final bool runSkipped;

  /// The flavor to build for testing.
  final String? flavor;

  /// Maximum time to let tests run before killing the process.
  final Duration? timeout;

  /// Additional reporter that writes test results to a file, expressed as
  /// `<name>:<path>` (e.g. `json:reports/tests.json`).
  final String? fileReporter;

  /// The raw `--shard-index` value, validated by [validateSharding].
  final String? shardIndex;

  /// The raw `--total-shards` value, validated by [validateSharding].
  final String? totalShards;

  /// The remaining arguments passed to the test command.
  final List<String> rest;
}

/// Validates the `--shard-index` / `--total-shards` combination.
///
/// Returns an error message describing the problem, or `null` when the
/// configuration is valid.
///
/// [rawShardIndex] and [rawTotalShards] are the unparsed command line values,
/// so that "not provided" can be told apart from "provided but not a number".
String? validateSharding({
  required String? rawShardIndex,
  required String? rawTotalShards,
  required bool optimizePerformance,
  required double? minCoverage,
}) {
  if (rawShardIndex == null && rawTotalShards == null) return null;

  if (rawShardIndex == null || rawTotalShards == null) {
    return '--shard-index and --total-shards must be used together.';
  }

  final totalShards = int.tryParse(rawTotalShards);
  if (totalShards == null || totalShards < 1) {
    return '--total-shards must be a positive integer, '
        'but got "$rawTotalShards".';
  }

  final shardIndex = int.tryParse(rawShardIndex);
  if (shardIndex == null || shardIndex < 1) {
    return '--shard-index must be a positive integer, '
        'but got "$rawShardIndex".';
  }

  if (shardIndex > totalShards) {
    return '--shard-index ($shardIndex) must be less than or equal to '
        '--total-shards ($totalShards).';
  }

  // Sharding partitions the test files consolidated by the optimizer, so it
  // cannot work when the optimization is turned off.
  if (!optimizePerformance) {
    return 'Sharding requires optimization to be enabled. '
        'Remove --no-optimization or --platform to use sharding.';
  }

  // Each shard only exercises a fraction of the codebase, so its coverage is
  // not representative of the whole suite. Merge the lcov files from every
  // shard and enforce the threshold in a separate job instead.
  if (minCoverage != null) {
    return '--min-coverage cannot be combined with sharding. Collect coverage '
        'per shard with --coverage, merge the lcov reports, then check the '
        'threshold in a separate job.';
  }

  return null;
}

/// Signature for the [Flutter.installed] method.
typedef FlutterInstalledCommand = Future<bool> Function({
  required Logger logger,
});

/// Signature for the [Flutter.test] method.
typedef FlutterTestCommand = Future<List<int>> Function({
  required Logger logger,
  String cwd,
  bool recursive,
  bool collectCoverage,
  bool optimizePerformance,
  double? minCoverage,
  bool showUncovered,
  String? excludeFromCoverage,
  CoverageCollectionMode collectCoverageFrom,
  String? randomSeed,
  bool? forceAnsi,
  List<String>? arguments,
  void Function(String)? stdout,
  void Function(String)? stderr,
  List<String>? reportOn,
  int? shardIndex,
  int? totalShards,
});

/// {@template test_command}
/// `very_good test` command for running tests.
/// {@endtemplate}
class TestCommand extends Command<int> {
  /// {@macro test_command}
  TestCommand({
    required this._logger,
    @visibleForTesting FlutterTestCommand? flutterTest,
    @visibleForTesting FlutterInstalledCommand? flutterInstalled,
  }) : _flutterTest = flutterTest ?? Flutter.test,
       _flutterInstalled = flutterInstalled ?? Flutter.installed {
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
        help:
            'Whether to enforce a minimum coverage percentage. '
            'Implicitly enables coverage collection when used alone.',
      )
      ..addFlag(
        'show-uncovered',
        help:
            'Whether to show uncovered lines when coverage is below 100%. '
            'Implicitly enables coverage collection when used alone.',
        negatable: false,
      )
      ..addOption(
        'collect-coverage-from',
        help:
            'Whether to collect coverage from imported files only or all '
            'files.',
        allowed: collectCoverageFromAllowedValues,
        defaultsTo: 'imports',
        valueHelp: 'imports|all',
      )
      ..addOption(
        'test-randomize-ordering-seed',
        help:
            'The seed to randomize the execution order of test cases '
            'within test files.',
      )
      ..addFlag(
        'update-goldens',
        help:
            'Whether "matchesGoldenFile()" calls within your test methods '
            'should update the golden files.',
        negatable: false,
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
      ..addMultiOption(
        'dart-define',
        help:
            'Additional key-value pairs that will be available as constants '
            'from the String.fromEnvironment, bool.fromEnvironment, '
            'int.fromEnvironment, and double.fromEnvironment constructors. '
            'Multiple defines can be passed by repeating '
            '"--dart-define" multiple times.',
        valueHelp: 'foo=bar',
      )
      ..addMultiOption(
        'dart-define-from-file',
        help:
            'The path of a .json or .env file containing key-value pairs '
            'that will be available as environment variables. '
            'These can be accessed using the String.fromEnvironment, '
            'bool.fromEnvironment, and int.fromEnvironment constructors. '
            'Multiple defines can be passed by repeating '
            '"--dart-define-from-file" multiple times. '
            'Entries from "--dart-define" with identical keys take '
            'precedence over entries from these files.',
        valueHelp: 'use-define-config.json|.env',
      )
      ..addOption(
        'platform',
        help: 'The platform to run tests on. ',
        valueHelp: 'chrome|vm|android|ios',
      )
      ..addMultiOption(
        'report-on',
        help:
            'Optional file paths to report coverage information to. '
            'This should be paths relative to the current working directory. '
            'Can be passed multiple times.',
        valueHelp: 'lib/',
      )
      ..addFlag(
        'run-skipped',
        help: 'Run skipped tests instead of skipping them.',
        negatable: false,
      )
      ..addOption(
        'flavor',
        help:
            'Build a custom app flavor as defined by platform-specific build '
            'setup. Supports the use of product flavors in Android Gradle '
            'scripts, and the use of custom Xcode schemes.',
      )
      ..addOption(
        'timeout',
        help:
            'Maximum seconds to let tests run before killing the process. '
            'Useful when tests hang due to an unbounded pumpAndSettle() call.',
        valueHelp: 'seconds',
      )
      ..addOption(
        'file-reporter',
        help:
            'Enable an additional reporter writing test results to a file. '
            'Should be in the form <name>:<path> (e.g. "json:reports/tests.json").',
        valueHelp: 'name:path',
      )
      ..addOption(
        'shard-index',
        help:
            'The 1-based index of the shard to run. '
            'Must be used together with --total-shards. '
            'Requires optimization to be enabled. '
            'When omitted, no sharding is applied.',
        valueHelp: 'index',
      )
      ..addOption(
        'total-shards',
        help:
            'Split the test suite into this many shards and run only the one '
            'selected by --shard-index. Useful to parallelize tests across '
            'multiple CI runners. When omitted, no sharding is applied.',
        valueHelp: 'count',
      );
  }

  final Logger _logger;
  final FlutterInstalledCommand _flutterInstalled;
  final FlutterTestCommand _flutterTest;

  @override
  String get description =>
      'Run `flutter test` in a project. (Check '
      'very_good dart test for running `dart test` instead.)';

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
This command should be run from the root of your Flutter project.''');
      return ExitCode.noInput.code;
    }

    final config = VeryGoodConfig.load(Directory(targetPath), logger: _logger);
    if (config == null) return ExitCode.config.code;

    final isFlutterInstalled = await _flutterInstalled(logger: _logger);

    final options = FlutterTestOptions.parse(_argResults, config: config);

    final shardingError = validateSharding(
      rawShardIndex: options.shardIndex,
      rawTotalShards: options.totalShards,
      optimizePerformance: options.optimizePerformance,
      minCoverage: options.minCoverage,
    );
    if (shardingError != null) {
      _logger.err(shardingError);
      return ExitCode.usage.code;
    }

    if (isFlutterInstalled) {
      try {
        final results = await _flutterTest(
          optimizePerformance:
              options.optimizePerformance &&
              !TestCLIRunner.isTargettingTestFiles(options.rest) &&
              !options.updateGoldens &&
              // Disabled optimization when platform is specified
              // https://github.com/VeryGoodOpenSource/very_good_cli/issues/1363
              options.platform == null,
          recursive: recursive,
          logger: _logger,
          stdout: _logger.write,
          stderr: _logger.err,
          collectCoverage:
              options.collectCoverage ||
              options.minCoverage != null ||
              options.showUncovered,
          minCoverage: options.minCoverage,
          showUncovered: options.showUncovered,
          excludeFromCoverage: options.excludeFromCoverage,
          collectCoverageFrom: options.collectCoverageFrom,
          randomSeed: options.randomSeed,
          forceAnsi: options.forceAnsi,
          reportOn: options.reportOn.isEmpty ? null : options.reportOn,
          shardIndex: int.tryParse(options.shardIndex ?? ''),
          totalShards: int.tryParse(options.totalShards ?? ''),
          arguments: [
            if (options.excludeTags != null) ...['-x', options.excludeTags!],
            if (options.tags != null) ...['-t', options.tags!],
            if (options.updateGoldens) '--update-goldens',
            if (options.failFast) '--fail-fast',
            if (options.runSkipped) '--run-skipped',
            if (options.flavor != null) ...['--flavor', options.flavor!],
            if (options.platform != null) ...['--platform', options.platform!],
            if (options.dartDefine != null)
              for (final value in options.dartDefine!) '--dart-define=$value',
            if (options.dartDefineFromFile != null)
              for (final value in options.dartDefineFromFile!)
                '--dart-define-from-file=$value',
            if (options.platform == null) ...['-j', options.concurrency],
            '--no-pub',
            if (options.timeout != null)
              '--timeout=${options.timeout!.inSeconds}s',
            if (options.fileReporter != null)
              '--file-reporter=${options.fileReporter}',
            ...options.rest,
          ],
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
