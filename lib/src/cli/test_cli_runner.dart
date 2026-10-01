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
  flutter,

  /// Run tests using `dart test`.
  dart,
}

/// How to collect coverage.
enum CoverageCollectionMode {
  /// Collect coverage from imported files only (default behavior).
  imports,

  /// Collect coverage from all files in the project.
  all;

  /// Parses a string value into a [CoverageCollectionMode].
  static CoverageCollectionMode fromString(String value) {
    return CoverageCollectionMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => CoverageCollectionMode.imports,
    );
  }
}

/// {@template coverage_not_met}
/// Thrown when `flutter test ---coverage --min-coverage`
/// does not meet the provided minimum coverage threshold.
/// {@endtemplate}
class MinCoverageNotMet implements Exception {
  /// {@macro coverage_not_met}
  const new(this.coverage, {this.uncoveredLines});

  /// The measured coverage percentage (total hits / total found * 100).
  final double coverage;

  /// Lines not covered, keyed by file path, values are line numbers.
  ///
  /// Only populated when `--show-uncovered` is set.
  final Map<String, List<int>>? uncoveredLines;
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

    final testRunner =
        overrideTestRunner ??
        (testType == TestRunType.flutter ? flutterTest : dartTest);

    final coverageOptions = _CoverageOptions(
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
        coverageOptions: coverageOptions,
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
    required _CoverageOptions coverageOptions,
    required String? randomSeed,
    required bool? forceAnsi,
    required List<String>? arguments,
    required void Function(String)? stdout,
    required void Function(String)? stderr,
  }) async {
    final lcovPath = p.join(cwd, 'coverage', 'lcov.info');
    final lcovFile = File(lcovPath);

    if (coverageOptions.collect && lcovFile.existsSync()) {
      await lcovFile.delete();
    }

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
      if (coverageOptions.collect) await lcovFile.create(recursive: true);
      return ExitCode.success.code;
    }

    return await _overrideAnsiOutput(
      forceAnsi,
      () =>
          _testCommand(
            cwd: cwd,
            collectCoverage: coverageOptions.collect,
            testRunner: testRunner,
            testType: testType,
            optimization: optimization,
            arguments: [
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
            await _reportCoverage(
              cwd: cwd,
              lcovPath: lcovPath,
              testType: testType,
              options: coverageOptions,
              stdout: stdout,
            );
          }),
    );
  }

  /// The path of [workingDirectory] relative to [from], as shown to the user.
  static String _displayPath(String workingDirectory, {required String from}) {
    final relativePath = p.relative(workingDirectory, from: from);
    return relativePath == '.' ? '.' : '.${p.context.separator}$relativePath';
  }

  /// Writes the lcov report of a finished test run when coverage is
  /// collected, then enforces the coverage threshold when one is set.
  static Future<void> _reportCoverage({
    required String cwd,
    required String lcovPath,
    required TestRunType testType,
    required _CoverageOptions options,
    required void Function(String)? stdout,
  }) async {
    if (options.collect) {
      await _writeLcov(
        cwd: cwd,
        lcovPath: lcovPath,
        testType: testType,
        options: options,
      );
    }

    if (options.minCoverage != null || options.showUncovered) {
      await _checkCoverage(
        lcovPath: lcovPath,
        options: options,
        stdout: stdout,
      );
    }
  }

  /// Leaves the coverage of the test run in `coverage/lcov.info`.
  static Future<void> _writeLcov({
    required String cwd,
    required String lcovPath,
    required TestRunType testType,
    required _CoverageOptions options,
  }) async {
    // Dart don't directly generate lcov files, so we need
    // to read the json that is generates and convert it to lcov.
    if (testType == TestRunType.dart) {
      await _convertDartCoverageToLcov(
        cwd: cwd,
        lcovFile: File(lcovPath),
        options: options,
      );
    }

    assert(File(lcovPath).existsSync(), 'coverage/lcov.info must exist');

    if (options.collectFrom == CoverageCollectionMode.all) {
      await _enhanceLcovWithUntestedFiles(
        lcovPath: lcovPath,
        cwd: cwd,
        reportOn: options.reportOn,
        excludeFromCoverage: options.excludeFromCoverage,
      );
    }
  }

  /// Converts the json coverage `dart test` writes into [lcovFile].
  static Future<void> _convertDartCoverageToLcov({
    required String cwd,
    required File lcovFile,
    required _CoverageOptions options,
  }) async {
    final files = _dartCoverageFilesToProcess(p.join(cwd, 'coverage'));

    final resolvedCwd = Directory(cwd).resolveSymbolicLinksSync();
    final resolvedReportOn = [
      for (final path in options.reportOn) p.join(resolvedCwd, path),
    ];

    final hitmap = await coverage.HitMap.parseFiles(
      files,
      packagePath: resolvedCwd,
      checkIgnoredLines: options.checkIgnore,
    );

    final resolver = await coverage.Resolver.create(packagePath: resolvedCwd);

    final output = hitmap.formatLcov(
      resolver,
      reportOn: resolvedReportOn,
      basePath: resolvedCwd,
    );

    await lcovFile.create(recursive: true);
    await lcovFile.writeAsString(output);
  }

  /// Throws [MinCoverageNotMet] when the coverage in [lcovPath] is below the
  /// threshold, and otherwise lists the uncovered lines when asked to.
  static Future<void> _checkCoverage({
    required String lcovPath,
    required _CoverageOptions options,
    required void Function(String)? stdout,
  }) async {
    final records = await Parser.parse(lcovPath);
    final coverageMetrics = CoverageMetrics.fromLcovRecords(
      records,
      excludeFromCoverage: options.excludeFromCoverage,
    );
    final percentage = coverageMetrics.percentage;
    final uncoveredLines =
        options.showUncovered && coverageMetrics.uncoveredLines.isNotEmpty
        ? coverageMetrics.uncoveredLines
        : null;

    final minCoverage = options.minCoverage;
    if (minCoverage != null && percentage < minCoverage) {
      throw MinCoverageNotMet(percentage, uncoveredLines: uncoveredLines);
    }

    // When coverage passes but is below 100%,
    // show uncovered lines as informational output.
    if (uncoveredLines != null) {
      stdout?.call('${formatUncoveredLines(uncoveredLines)}\n');
    }
  }

  static T _overrideAnsiOutput<T>(bool? enableAnsiOutput, T Function() body) =>
      enableAnsiOutput == null
      ? body.call()
      : overrideAnsiOutput(enableAnsiOutput, body);

  /// Logs [error], along with its uncovered lines when it carries any, and
  /// returns the exit code an unmet coverage threshold reports.
  static int handleMinCoverageNotMet(
    MinCoverageNotMet error, {
    required Logger logger,
    double? minCoverage,
  }) {
    var decimalPlaces = 2;

    double round(double x) {
      final b = pow(10, decimalPlaces);
      return (x * b).roundToDouble() / b;
    }

    if (error.coverage < minCoverage!) {
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

  /// Formats a map of uncovered lines into a human-readable string.
  ///
  /// The [uncoveredLines] map is keyed by file path, with values being lists
  /// of uncovered line numbers.
  ///
  /// Example output:
  /// ```dart
  /// Lines not covered:
  ///   - lib/src/foo.dart: 10, 20, 30
  ///   - lib/src/bar.dart: 5
  /// ```
  static String formatUncoveredLines(Map<String, List<int>> uncoveredLines) {
    final lines = uncoveredLines.entries.map((entry) {
      final sortedLines = [...entry.value]..sort();
      return '\t- ${entry.key}: ${sortedLines.join(', ')}';
    });
    return 'Lines not covered:\n${lines.join('\n')}';
  }

  /// Discovers all Dart files in the specified directories for coverage.
  static List<String> _discoverDartFilesForCoverage({
    required String cwd,
    required List<String> reportOn,
    String? excludeFromCoverage,
  }) {
    final glob = excludeFromCoverage != null ? Glob(excludeFromCoverage) : null;

    return reportOn.expand((dir) {
      final reportOnPath = p.join(cwd, dir);
      final directory = Directory(reportOnPath);

      if (!directory.existsSync()) return <String>[];

      return directory
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .where((file) => glob == null || !glob.matches(file.path))
          .map((file) => p.relative(file.path, from: cwd));
    }).toList();
  }

  /// Enhances an existing lcov file by adding uncovered files with 0% coverage.
  static Future<void> _enhanceLcovWithUntestedFiles({
    required String lcovPath,
    required String cwd,
    required List<String> reportOn,
    String? excludeFromCoverage,
  }) async {
    final lcovFile = File(lcovPath);

    final allDartFiles = _discoverDartFilesForCoverage(
      cwd: cwd,
      reportOn: reportOn,
      excludeFromCoverage: excludeFromCoverage,
    );

    // Parse existing lcov to find covered files
    final existingRecords = await Parser.parse(lcovPath);
    final coveredFiles = existingRecords.map((r) => r.file).nonNulls.toSet();

    final uncoveredFiles = allDartFiles.where((file) {
      final normalizedFile = p.normalize(file);
      return !coveredFiles.any(
        (covered) => p.normalize(covered).endsWith(normalizedFile),
      );
    }).toList();

    if (uncoveredFiles.isEmpty) return;

    // Append uncovered files to lcov
    final buffer = StringBuffer(await lcovFile.readAsString());

    for (final file in uncoveredFiles) {
      final dartFile = File(p.join(cwd, file));
      if (!dartFile.existsSync()) continue;
      buffer.write(_untestedFileRecord(file, await dartFile.readAsLines()));
    }

    await lcovFile.writeAsString(buffer.toString());
  }

  /// The lcov record of a [file] no test reached, given its [lines], where
  /// every non-trivial line is marked as uncovered.
  static String _untestedFileRecord(String file, List<String> lines) {
    final uncoveredLineNumbers = [
      for (final (index, line) in lines.indexed)
        if (_isCoverableLine(line.trim())) index + 1,
    ];

    final record = StringBuffer()..writeln('SF:${file.replaceAll(r'\', '/')}');
    for (final lineNumber in uncoveredLineNumbers) {
      record.writeln('DA:$lineNumber,0');
    }
    record
      ..writeln('LF:${uncoveredLineNumbers.length}')
      ..writeln('LH:0')
      ..writeln('end_of_record');
    return record.toString();
  }

  /// Whether a [trimmedLine] of source counts towards coverage.
  static bool _isCoverableLine(String trimmedLine) =>
      trimmedLine.isNotEmpty &&
      !_nonCoverableLinePrefixes.any(trimmedLine.startsWith);

  static const _nonCoverableLinePrefixes = ['//', 'import', 'export', 'part'];

  static List<File> _dartCoverageFilesToProcess(String absPath) {
    return Directory(absPath)
        .listSync(recursive: true)
        .whereType<File>()
        .where((e) => e.path.endsWith('.json'))
        .toList();
  }
}

/// The coverage settings of a [TestCLIRunner.test] run.
class _CoverageOptions {
  const new({
    required this.collect,
    required this.collectFrom,
    required this.minCoverage,
    required this.showUncovered,
    required this.excludeFromCoverage,
    required this.reportOn,
    required this.checkIgnore,
  });

  /// Whether to collect coverage into `coverage/lcov.info`.
  final bool collect;

  /// Which files the lcov report accounts for.
  final CoverageCollectionMode collectFrom;

  /// The minimum coverage percentage the run must reach, if any.
  final double? minCoverage;

  /// Whether to list the lines left uncovered.
  final bool showUncovered;

  /// A glob of the files left out of the coverage.
  final String? excludeFromCoverage;

  /// The directories, relative to the package, the coverage reports on.
  final List<String> reportOn;

  /// Whether to honor the `coverage:ignore` comments.
  final bool checkIgnore;
}

/// The exit code `dart test` and `flutter test` use when no test ran, for
/// example because `--exclude-tags` filtered out every test.
const _noTestsRanExitCode = 79;

/// Clears the current terminal line and moves the cursor to its start.
const _clearLine = '\u001B[2K\r';

Future<int> _testCommand({
  required void Function(String) stdout,
  required void Function(String) stderr,
  required VeryGoodTestRunner testRunner,
  required TestRunType testType,
  required TestOptimization optimization,
  String cwd = '.',
  bool collectCoverage = false,
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
        arguments: [
          if (collectCoverage) _coverageArgument(testType),
          ...?arguments,
        ],
        runInShell: true,
      ).listen(
        (event) async {
          if (event.shouldCancelTimer()) unawaited(timerSubscription.cancel());
          reporter.report(event);

          if (event is! ExitTestEvent || completer.isCompleted) return;
          unawaited(subscription.cancel());
          unawaited(sigintWatchSubscription.cancel());
          completer.complete(_exitCodeOf(event, optimization));
        },
        onError: (Object error, StackTrace stackTrace) {
          stderr('$_clearLine$error');
          stderr('$_clearLine$stackTrace');
        },
      );

  return completer.future;
}

/// The argument that makes [testType] collect coverage.
String _coverageArgument(TestRunType testType) => switch (testType) {
  TestRunType.flutter => '--coverage',
  TestRunType.dart => '--coverage=coverage',
};

/// The exit code a test run that ended with [event] reports.
int _exitCodeOf(ExitTestEvent event, TestOptimization optimization) {
  // A shard can end up holding only tests that the given tags
  // filter out, which is expected and not a failure.
  final noTestsRanInShard =
      optimization.shardIndex != null && event.exitCode == _noTestsRanExitCode;

  return event.exitCode == ExitCode.success.code || noTestsRanInShard
      ? ExitCode.success.code
      : ExitCode.unavailable.code;
}

/// Prints the progress of a test run as its [TestEvent]s arrive, and keeps
/// the tally of passing, skipped and failing tests the summary is made of.
class _TestEventReporter {
  new({
    required this.stdout,
    required this.stderr,
    required this.optimization,
    required this.cwd,
  });

  final void Function(String) stdout;
  final void Function(String) stderr;
  final TestOptimization optimization;
  final String cwd;

  final _suites = <int, TestSuite>{};
  final _groups = <int, TestGroup>{};
  final _tests = <int, Test>{};
  final _failedTestErrorMessages = <String, List<String>>{};

  var _successCount = 0;
  var _skipCount = 0;

  void report(TestEvent event) {
    switch (event) {
      case SuiteTestEvent(:final suite):
        _suites[suite.id] = suite;
      case GroupTestEvent(:final group):
        _groups[group.id] = group;
      case TestStartEvent(:final test):
        _tests[test.id] = test;
      case MessageTestEvent():
        _reportMessage(event);
      case ErrorTestEvent():
        _reportError(event);
      case TestDoneEvent():
        _reportTestDone(event);
      case DoneTestEvent():
        _reportDone(event);
    }
  }

  void _reportMessage(MessageTestEvent event) {
    final message = event.message;
    if (message.startsWith('Skip:')) {
      stdout('$_clearLine${lightYellow.wrap(message)}\n');
    } else if (message.contains('EXCEPTION')) {
      stderr('$_clearLine$message');
    } else {
      stdout('$_clearLine$message\n');
    }
  }

  void _reportError(ErrorTestEvent event) {
    stderr('$_clearLine${event.error}');

    if (event.stackTrace.trim().isNotEmpty) {
      stderr('$_clearLine${event.stackTrace}');
    }

    final report = _resolveReport(event.testID);
    final prefix = event.isFailure ? '[FAILED]' : '[ERROR]';

    final relativeTestPath = p.relative(report.path, from: cwd);
    _failedTestErrorMessages[relativeTestPath] = [
      ...?_failedTestErrorMessages[relativeTestPath],
      '$prefix ${report.name}',
    ];
  }

  void _reportTestDone(TestDoneEvent event) {
    if (event.hidden) return;

    final (:path, :name) = _resolveReport(event.testID);
    _tallyResult(event, testPath: path, testName: name);

    final timeElapsed = Duration(milliseconds: event.time).formatted();
    final stats = _stats();
    final truncatedTestName = name.toSingleLine().truncated(
      _lineLength - (timeElapsed.length + stats.length + 2),
    );
    stdout('''$_clearLine$timeElapsed $stats: $truncatedTestName''');
  }

  void _tallyResult(
    TestDoneEvent event, {
    required String testPath,
    required String testName,
  }) {
    if (event.skipped) {
      stdout(
        '''$_clearLine${lightYellow.wrap('$testName $testPath (SKIPPED)')}\n''',
      );
      _skipCount++;
    } else if (event.result == TestResult.success) {
      _successCount++;
    } else {
      stderr('$_clearLine$testName $testPath (FAILED)');
    }
  }

  void _reportDone(DoneTestEvent event) {
    final timeElapsed = Duration(milliseconds: event.time).formatted();
    final stats = _stats();
    final success = event.success ?? false;
    final summary = success
        ? lightGreen.wrap('All tests passed!')!
        : lightRed.wrap('Some tests failed.')!;

    stdout('$_clearLine${darkGray.wrap(timeElapsed)} $stats: $summary\n');

    if (success) return;

    assert(
      _failedTestErrorMessages.isNotEmpty,
      'Invalid state: test event report as failed '
      'but no failed tests were gathered',
    );
    stderr(_failingTestsSummary());
  }

  String _failingTestsSummary() {
    final title = styleBold.wrap('Failing Tests:');

    final lines = StringBuffer('$_clearLine$title\n');
    for (final MapEntry(key: testPath, value: errorMessages)
        in _failedTestErrorMessages.entries) {
      lines.writeln('$_clearLine - $testPath ');

      for (final errorMessage in errorMessages) {
        lines.writeln('$_clearLine \t- $errorMessage');
      }
    }

    return lines.toString();
  }

  /// The file and name [testID] is reported under, once the bundling of the
  /// test optimizer is undone.
  ({String path, String name}) _resolveReport(int testID) {
    final test = _tests[testID]!;
    final suite = _suites[test.suiteID]!;

    return optimization.resolveReport(
      suitePath: suite.path!,
      testName: test.name,
      groupName: _topGroupName(test, _groups),
    );
  }

  String _stats() {
    final passingTests = _successCount.formatSuccess();
    final failingTests = _failedTestErrorMessages.values
        .expand((e) => e)
        .length
        .formatFailure();
    final skippedTests = _skipCount.formatSkipped();
    final result = [passingTests, failingTests, skippedTests]
      ..removeWhere((element) => element.isEmpty);
    return result.join(' ');
  }
}

/// The name of the outermost non-empty group [test] belongs to.
///
/// For a test running inside the optimized bundle this is the path of the file
/// it was written in, relative to `test`, which is what
/// [TestOptimization.resolveReport] needs to undo the bundling.
String? _topGroupName(Test test, Map<int, TestGroup> groups) => test.groupIDs
    .map((groupID) => groups[groupID]?.name)
    .firstWhereOrNull((groupName) => groupName?.isNotEmpty ?? false);

final int _lineLength = () {
  try {
    return stdout.terminalColumns;
  } on StdoutException {
    return 80;
  }
}();
