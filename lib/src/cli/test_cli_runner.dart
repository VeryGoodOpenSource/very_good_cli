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
enum TestRunType(
  /// The kind of project the runner tests, as named in messages.
  final String projectKind,
) {
  /// Run tests using `flutter test`.
  flutter('Flutter'),

  /// Run tests using `dart test`.
  dart('Dart');

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

/// How long [_testCommand] waits for the test subprocess to exit after
/// SIGTERM (sent by `package:very_good_test_runner`'s `onCancel`) before
/// escalating to SIGKILL.
///
/// `flutter test` tears down its `flutter_tester` subprocess under SIGTERM
/// within well under a second. `dart test` instead treats SIGTERM as a
/// request to shut down gracefully: it waits for every in-progress test to
/// finish, and a test with `Timeout.none` awaiting a future that never
/// completes blocks that shutdown indefinitely — leaving the `dart test`
/// process (and the `frontend_server` it spawned) running past the MCP
/// wall-clock budget. The grace period should be short enough to feel
/// responsive and long enough that a well-behaved runner is never
/// hard-killed mid-cleanup.
const _forceKillGrace = Duration(seconds: 2);

/// Wraps [dartTest] / [flutterTest] so the subprocess they spawn can be
/// force-killed if SIGTERM alone does not tear it down.
///
/// The wrapper injects a `startProcess` override into the underlying runner
/// to capture the [Process] handle, then exposes [forceKillAfterGrace] so
/// the caller can escalate to SIGKILL after
/// `package:very_good_test_runner`'s `onCancel` has had a chance to exit
/// the subprocess gracefully.
@visibleForTesting
class CancellableTestRunner(final TestRunType _testType) {
  /// Builds a cancellable runner for [_testType] (`dart test` or
  /// `flutter test`).
  this;

  /// The subprocess the underlying test runner last spawned, tracked by
  /// [_startProcess] so [forceKillAfterGrace] can tear it down.
  Process? _process;

  /// The subprocess the underlying test runner last spawned, if any.
  ///
  /// Exposed so tests can inject a fake [Process] and verify
  /// [forceKillAfterGrace]'s teardown behaviour without having to run a real
  /// `dart test` / `flutter test` subprocess.
  @visibleForTesting
  Process? get attachedProcess => _process;
  @visibleForTesting
  set attachedProcess(Process? process) => _process = process;

  /// A [VeryGoodTestRunner] that delegates to [dartTest] / [flutterTest]
  /// while capturing the spawned subprocess for later force-kill.
  // Thin pass-through to `package:very_good_test_runner`. Exercising it
  // means actually spawning `dart test` / `flutter test`, which the unit
  // test suite intentionally avoids; the behaviour is covered end-to-end
  // through the MCP tool run.
  // coverage:ignore-start
  Stream<TestEvent> run({
    List<String>? arguments,
    String? workingDirectory,
    Map<String, String>? environment,
    bool runInShell = false,
  }) => switch (_testType) {
    TestRunType.flutter => flutterTest(
      arguments: arguments,
      workingDirectory: workingDirectory,
      environment: environment,
      runInShell: runInShell,
      startProcess: _startProcess,
    ),
    TestRunType.dart => dartTest(
      arguments: arguments,
      workingDirectory: workingDirectory,
      environment: environment,
      runInShell: runInShell,
      startProcess: _startProcess,
    ),
  };

  Future<Process> _startProcess(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment = true,
    bool runInShell = false,
    ProcessStartMode mode = ProcessStartMode.normal,
  }) async {
    final process = await Process.start(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      environment: environment,
      includeParentEnvironment: includeParentEnvironment,
      runInShell: runInShell,
      mode: mode,
    );
    _process = process;
    return process;
  }
  // coverage:ignore-end

  /// Waits up to [grace] for the spawned subprocess to exit after SIGTERM,
  /// then sends SIGKILL if it is still alive and awaits its exit.
  ///
  /// Returns promptly when no subprocess was spawned (for example because
  /// cancellation fired before `onListen` could call `Process.start`), or
  /// when the subprocess already exited on its own.
  Future<void> forceKillAfterGrace([Duration grace = _forceKillGrace]) async {
    final process = _process;
    if (process == null) return;
    try {
      await process.exitCode.timeout(grace);
    } on TimeoutException {
      process.kill(ProcessSignal.sigkill);
      // Give the kernel a brief moment to reap the process so the caller
      // observes a fully torn-down subtree. SIGKILL is uncatchable and
      // should resolve almost instantly; the extra timeout is a safety
      // valve so a stuck caller is never held up indefinitely.
      try {
        await process.exitCode.timeout(grace);
      } on TimeoutException {
        // The process did not reap within the extra grace. Unusual, but we
        // refuse to block the MCP lock on it: whichever queue is waiting
        // for us is more important than reporting the exit of a zombie.
      }
    }
  }
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
      cmd: (cwd) {
        // One cancellable runner per package so a recursive run tears down the
        // in-flight subprocess, not a prior iteration's.
        final cancellable = overrideTestRunner == null
            ? CancellableTestRunner(testType)
            : null;
        final testRunner = overrideTestRunner ?? cancellable!.run;
        return _testPackage(
          cwd: cwd,
          initialCwd: initialCwd,
          logger: logger,
          testType: testType,
          testRunner: testRunner,
          onForceKill: cancellable?.forceKillAfterGrace,
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
        );
      },
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
    Future<void> Function()? onForceKill,
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
            onForceKill: onForceKill,
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
  Future<void> Function()? onForceKill,
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
    // `subscription.cancel()` triggers `onCancel` in
    // `package:very_good_test_runner`, which sends SIGTERM to the test
    // subprocess. SIGTERM alone is not enough when the subprocess is
    // `dart test` running a test with `Timeout.none` awaiting a future
    // that never completes: `dart test` waits for in-progress tests to
    // finish before honouring the signal and the whole process tree
    // outlives the MCP wall-clock budget. [onForceKill] escalates to
    // SIGKILL after a grace period so the budget actually releases the
    // lock on a torn-down subprocess.
    await subscription.cancel();
    // The `onForceKill` branch is only non-null when
    // [TestCLIRunner.test] is called without `overrideTestRunner`, which
    // means the runner spawns a real `dart test` / `flutter test`
    // subprocess — behaviour the unit suite intentionally avoids and
    // which is covered end-to-end through the MCP tool run.
    // coverage:ignore-start
    if (onForceKill != null) await onForceKill();
    // coverage:ignore-end
    await sigintWatchSubscription.cancel();
    return completer.complete(ExitCode.success.code);
  });

  // The broadcast [sigintWatch] does not replay events to late listeners, so a
  // SIGINT emitted before this subscription — for example while [_testPackage]
  // awaited [coverageReport.clean] or [optimizer.apply] — would be dropped and
  // the test subprocess would still be spawned and never signalled. Honour the
  // sticky [isSigintEmitted] flag here and tear down before starting the run.
  if (ProcessSignalOverrides.current?.isSigintEmitted ?? false) {
    unawaited(timerSubscription.cancel());
    unawaited(sigintWatchSubscription.cancel());
    completer.complete(ExitCode.success.code);
    return completer.future;
  }

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
