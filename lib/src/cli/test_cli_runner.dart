part of 'cli.dart';

/// Type definition for the [flutterTest]/[dartTest] command
/// from 'package:very_good_test_runner`.
typedef VeryGoodTestRunner = Stream<TestEvent> Function({
  List<String>? arguments,
  String? workingDirectory,
  Map<String, String>? environment,
  bool runInShell,
});

/// Which test runner to use for running tests.
enum TestRunType {
  /// Run tests using `flutter test`.
  flutter('Flutter'),

  /// Run tests using `dart test`.
  dart('Dart');

  new(this.projectKind);

  /// The kind of project the runner tests, as named in messages.
  final String projectKind;

  /// The command of `package:very_good_test_runner` that runs the tests.
  VeryGoodTestRunner get runner => switch (this) {
    TestRunType.flutter => flutterTest,
    TestRunType.dart => dartTest,
  };

  /// The [CoverageReport] of a run of the tests of the package at
  /// [packageRoot].
  CoverageReport coverageReportOf(
    String packageRoot, {
    required CoverageOptions options,
  }) => switch (this) {
    TestRunType.flutter => FlutterCoverageReport(
      packageRoot: packageRoot,
      options: options,
    ),
    TestRunType.dart => DartCoverageReport(
      packageRoot: packageRoot,
      options: options,
    ),
  };
}

/// A class to run test command from a CLI command, like `flutter` or `dart`.
///
/// It abstracts common functionalities like the test optimization, coverage
/// collection, and concurrency management.
class TestCLIRunner {
  /// Determines whether the user is targetting test files or not.
  ///
  /// [rest] holds the positional arguments left over after option parsing.
  /// Trailing options are allowed, so bare targets work
  /// (`very_good test test/foo_test.dart`); the `--` option terminator is only
  /// needed for a target that begins with `-`, which would otherwise be read
  /// as an option. Either way the parser strips the `--` out of [rest], so
  /// what arrives here is the targets alone.
  ///
  /// The heuristics used to determine if the user is not targetting test files
  /// are:
  /// * No [rest] arguments are passed.
  /// * Every [rest] argument is an option (i.e. it starts with `-`), which
  ///   only happens when the options were passed through a `--` for the
  ///   underlying test runner.
  ///
  /// See also:
  /// * [What does -- mean in Shell?](https://www.cyberciti.biz/faq/what-does-double-dash-mean-in-ssh-command/)
  static bool isTargettingTestFiles(List<String> rest) {
    if (rest.isEmpty) {
      return false;
    }

    return rest.where((arg) => !arg.startsWith('-')).isNotEmpty;
  }

  /// Validates the `--shard-index` / `--total-shards` combination.
  ///
  /// Returns an error message describing the problem, or `null` when the
  /// configuration is valid.
  ///
  /// [rawShardIndex], [rawTotalShards] and [rawMinCoverage] are the unparsed
  /// command line values, so that "not provided" can be told apart from
  /// "provided but not a number", and an explicit `--min-coverage` from one
  /// inherited from `very_good.yaml`. [optimizePerformance] is the effective
  /// value, after every option that disables the optimizer is accounted for.
  static String? validateSharding({
    required String? rawShardIndex,
    required String? rawTotalShards,
    required String? rawMinCoverage,
    required bool optimizePerformance,
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
      return 'Sharding requires the test optimizer, which is disabled by '
          '--no-optimization, --platform, --update-goldens or by targeting '
          'specific test files.';
    }

    // Each shard only exercises a fraction of the codebase, so its coverage is
    // not representative of the whole suite. Merge the lcov files from every
    // shard and enforce the threshold in a separate job instead.
    if (rawMinCoverage != null) {
      return '--min-coverage cannot be combined with sharding. Collect '
          'coverage per shard with --coverage, merge the lcov reports, then '
          'check the threshold in a separate job.';
    }

    return null;
  }

  /// Validates that the tests can run against [targetPath].
  ///
  /// Logs the problem and returns the exit code to stop with, or returns
  /// `null` when the run can proceed. [rest] are the positional arguments of
  /// the command and [testType] names the project in the messages.
  static int? validateTarget({
    required String targetPath,
    required bool recursive,
    required List<String> rest,
    required TestRunType testType,
    required Logger logger,
  }) {
    if (recursive && isTargettingTestFiles(rest)) {
      logger.err('''
Cannot target specific test files together with --recursive.
Test targets are resolved against a single package root, so the same path
cannot apply to every package. Drop --recursive and run from the package
that contains them.''');
      return ExitCode.usage.code;
    }

    final pubspec = File(p.join(targetPath, 'pubspec.yaml'));
    if (!recursive && !pubspec.existsSync()) {
      logger.err(
        '''
Could not find a pubspec.yaml in $targetPath.
This command should be run from the root of your ${testType.projectKind} project.''',
      );
      return ExitCode.noInput.code;
    }

    return null;
  }

  /// Run tests (`flutter test`).
  /// Returns a list of exit codes for each test process.
  static Future<List<int>> test({
    required Logger logger,
    required TestRunType testType,
    String cwd = '.',
    bool recursive = false,
    bool collectCoverage = false,
    TestOptimizer optimizer = const TestOptimizer.disabled(),
    Set<String> ignore = const {},
    double? minCoverage,
    bool showUncovered = false,
    String? excludeFromCoverage,
    CoverageCollectionMode collectCoverageFrom = CoverageCollectionMode.imports,
    String? randomSeed,
    bool? forceAnsi,
    List<String>? arguments,
    void Function(String)? stdout,
    void Function(String)? stderr,
    List<String>? reportOn,
    bool checkIgnore = false,
    @visibleForTesting VeryGoodTestRunner? overrideTestRunner,
  }) {
    final initialCwd = cwd;

    final testRunner = overrideTestRunner ?? testType.runner;

    final coverageOptions = CoverageOptions(
      collect: collectCoverage,
      collectFrom: collectCoverageFrom,
      minCoverage: minCoverage,
      showUncovered: showUncovered,
      excludeFromCoverage: excludeFromCoverage,
      reportOn: reportOn ?? const ['lib'],
      checkIgnore: checkIgnore,
    );

    return _runCommand<int>(
      cmd: (cwd) => _testPackage(
        cwd: cwd,
        initialCwd: initialCwd,
        logger: logger,
        testType: testType,
        testRunner: testRunner,
        optimizer: optimizer,
        coverageReport: testType.coverageReportOf(
          cwd,
          options: coverageOptions,
        ),
        randomSeed: randomSeed,
        forceAnsi: forceAnsi,
        arguments: arguments,
        stdout: stdout,
        stderr: stderr,
      ),
      cwd: cwd,
      ignore: ignore,
      recursive: recursive,
    );
  }

  /// Runs the tests of the single package rooted at [cwd].
  static Future<int> _testPackage({
    required String cwd,
    required String initialCwd,
    required Logger logger,
    required TestRunType testType,
    required VeryGoodTestRunner testRunner,
    required TestOptimizer optimizer,
    required CoverageReport coverageReport,
    required String? randomSeed,
    required bool? forceAnsi,
    required List<String>? arguments,
    required void Function(String)? stdout,
    required void Function(String)? stderr,
  }) async {
    await coverageReport.clean();

    void noop(String? _) {}
    final workingDirectory = Directory(p.normalize(cwd)).absolute.path;
    final path = _displayPath(workingDirectory, from: initialCwd);

    stdout?.call('Running "${testType.name} test" in $path ...\n');

    if (!Directory(p.join(workingDirectory, 'test')).existsSync()) {
      stdout?.call('No test folder found in $path\n');
      return ExitCode.success.code;
    }

    if (randomSeed != null) {
      stdout?.call(
        '''Shuffling test order with --test-randomize-ordering-seed=$randomSeed\n''',
      );
    }
    final optimization = await optimizer.apply(
      packageRoot: workingDirectory,
      logger: logger,
    );

    if (optimization.isEmptyShard) {
      stdout?.call(
        'No tests found for shard ${optimization.shardIndex} in $path\n',
      );
      await optimization.cleanUp();
      // The merge step downstream still expects a report from every
      // shard, so leave an empty one behind.
      await coverageReport.writeEmpty();
      return ExitCode.success.code;
    }

    return await _overrideAnsiOutput(
      forceAnsi,
      () =>
          _testCommand(
            cwd: cwd,
            testRunner: testRunner,
            optimization: optimization,
            arguments: [
              ...coverageReport.collectArguments,
              ...?arguments,
              if (randomSeed != null) ...[
                '--test-randomize-ordering-seed',
                randomSeed,
              ],
              ...optimization.testTargets,
            ],
            stdout: stdout ?? noop,
            stderr: stderr ?? noop,
          ).whenComplete(() async {
            await optimization.cleanUp();
            await coverageReport.finalize(stdout: stdout);
          }),
    );
  }

  /// The path of [workingDirectory] relative to [from], as shown to the user.
  static String _displayPath(String workingDirectory, {required String from}) {
    final relativePath = p.relative(workingDirectory, from: from);
    return relativePath == '.' ? '.' : '.${p.context.separator}$relativePath';
  }

  static T _overrideAnsiOutput<T>(bool? enableAnsiOutput, T Function() body) =>
      enableAnsiOutput == null
      ? body.call()
      : overrideAnsiOutput(enableAnsiOutput, body);

  /// Awaits the exit codes of [runTests] and maps the outcome of the run to
  /// the exit code of the command, logging any failure.
  static Future<int> exitCodeOf(
    Future<List<int>> Function() runTests, {
    required Logger logger,
  }) async {
    try {
      final results = await runTests();
      return results.every((code) => code == ExitCode.success.code)
          ? ExitCode.success.code
          : ExitCode.software.code;
    } on MinCoverageNotMet catch (error) {
      return _handleMinCoverageNotMet(error, logger: logger);
    } on InvalidOptimizationGlob catch (error) {
      logger.err('$error');
      return ExitCode.config.code;
    } on Exception catch (error) {
      logger.err('$error');
      return ExitCode.unavailable.code;
    }
  }

  /// Logs [error], along with its uncovered lines when it carries any, and
  /// returns the exit code an unmet coverage threshold reports.
  static int _handleMinCoverageNotMet(
    MinCoverageNotMet error, {
    required Logger logger,
  }) {
    final minCoverage = error.minCoverage;
    var decimalPlaces = 2;

    double round(double x) {
      final b = pow(10, decimalPlaces);
      return (x * b).roundToDouble() / b;
    }

    if (error.coverage < minCoverage) {
      var rounded = round(error.coverage);
      while (rounded == minCoverage) {
        decimalPlaces++;
        rounded = round(error.coverage);
      }
    }

    logger.err(
      '''Expected coverage >= ${minCoverage.toStringAsFixed(decimalPlaces)}% but actual is ${error.coverage.toStringAsFixed(decimalPlaces)}%.''',
    );

    final uncoveredLines = error.uncoveredLines;
    if (uncoveredLines != null && uncoveredLines.isNotEmpty) {
      logger.err(formatUncoveredLines(uncoveredLines));
    }

    return ExitCode.software.code;
  }
}

/// The exit code `dart test` and `flutter test` use when no test ran, for
/// example because `--exclude-tags` filtered out every test.
const _noTestsRanExitCode = 79;

Future<int> _testCommand({
  required void Function(String) stdout,
  required void Function(String) stderr,
  required VeryGoodTestRunner testRunner,
  required TestOptimization optimization,
  String cwd = '.',
  List<String>? arguments,
}) {
  final completer = Completer<int>();
  final reporter = _TestEventReporter(
    stdout: stdout,
    stderr: stderr,
    optimization: optimization,
    cwd: cwd,
  );
  final sigintWatch =
      ProcessSignalOverrides.current?.sigintWatch ??
      ProcessSignal.sigint.watch();

  final timerSubscription =
      Stream.periodic(
        const Duration(seconds: 1),
        (computationCount) => computationCount,
      ).listen((tick) {
        if (completer.isCompleted) return;
        final timeElapsed = Duration(seconds: tick).formatted();
        stdout('$_clearLine$timeElapsed ...');
      });

  late final StreamSubscription<TestEvent> subscription;
  late final StreamSubscription<ProcessSignal> sigintWatchSubscription;

  sigintWatchSubscription = sigintWatch.listen((_) async {
    await optimization.cleanUp();
    await subscription.cancel();
    await sigintWatchSubscription.cancel();
    return completer.complete(ExitCode.success.code);
  });

  subscription =
      testRunner(
        workingDirectory: cwd,
        arguments: arguments,
        runInShell: true,
      ).listen(
        (event) {
          if (event.shouldCancelTimer()) unawaited(timerSubscription.cancel());
          reporter.report(event);

          if (event is! ExitTestEvent || completer.isCompleted) return;
          unawaited(subscription.cancel());
          unawaited(sigintWatchSubscription.cancel());
          completer.complete(_exitCodeOfEvent(event, optimization));
        },
        onError: (Object error, StackTrace stackTrace) {
          stderr('$_clearLine$error');
          stderr('$_clearLine$stackTrace');
        },
      );

  return completer.future;
}

/// The exit code a test run that ended with [event] reports.
int _exitCodeOfEvent(ExitTestEvent event, TestOptimization optimization) {
  // A shard can end up holding only tests that the given tags
  // filter out, which is expected and not a failure.
  final noTestsRanInShard =
      optimization.shardIndex != null && event.exitCode == _noTestsRanExitCode;

  return event.exitCode == ExitCode.success.code || noTestsRanInShard
      ? ExitCode.success.code
      : ExitCode.unavailable.code;
}
