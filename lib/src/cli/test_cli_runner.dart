part of 'cli.dart';

/// Type definition for the [flutterTest]/[dartTest] command
/// from 'package:very_good_test_runner`.
typedef VeryGoodTestRunner =
    Stream<TestEvent> Function({
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

/// A method which returns a [Future<MasonGenerator>] given a [MasonBundle].
typedef GeneratorBuilder = Future<MasonGenerator> Function(MasonBundle);

/// {@template coverage_not_met}
/// Thrown when `flutter test ---coverage --min-coverage`
/// does not meet the provided minimum coverage threshold.
/// {@endtemplate}
class MinCoverageNotMet implements Exception {
  /// {@macro coverage_not_met}
  const MinCoverageNotMet(this.coverage);

  /// The measured coverage percentage (total hits / total found * 100).
  final double coverage;
}

/// A class to run test command from a CLI command, like `flutter` or `dart`.
///
/// It abstracts common functionalities like the test optimization, coverage
/// collection, and concurrency management.
class TestCLIRunner {
  /// Determines whether the user is targetting test files or not.
  ///
  /// The user can only target test files by using the `--` option terminator.
  /// The additional options after the `--` are passed to the test runner which
  /// allows the user to target specific test files or directories.
  ///
  /// The heuristics used to determine if the user is not targetting test files
  /// are:
  /// * No [rest] arguments are passed.
  /// * All [rest] arguments are options (i.e. they do not start with `-`).
  ///
  /// See also:
  /// * [What does -- mean in Shell?](https://www.cyberciti.biz/faq/what-does-double-dash-mean-in-ssh-command/)
  static bool isTargettingTestFiles(List<String> rest) {
    if (rest.isEmpty) {
      return false;
    }

    return rest.where((arg) => !arg.startsWith('-')).isNotEmpty;
  }

  /// Run tests (`flutter test`).
  /// Returns a list of exit codes for each test process.
  static Future<List<int>> test({
    required Logger logger,
    required TestRunType testType,
    String cwd = '.',
    bool recursive = false,
    bool collectCoverage = false,
    bool optimizePerformance = false,
    Set<String> ignore = const {},
    double? minCoverage,
    String? excludeFromCoverage,
    String? randomSeed,
    bool? forceAnsi,
    List<String>? arguments,
    void Function(String)? stdout,
    void Function(String)? stderr,
    GeneratorBuilder buildGenerator = MasonGenerator.fromBundle,
    @visibleForTesting VeryGoodTestRunner? overrideTestRunner,
  }) async {
    final initialCwd = cwd;

    final testRunner =
        overrideTestRunner ??
        (testType == TestRunType.flutter ? flutterTest : dartTest);

    return _runCommand<int>(
      cmd: (cwd) async {
        final lcovPath = p.join(cwd, 'coverage', 'lcov.info');
        final lcovFile = File(lcovPath);

        if (collectCoverage && lcovFile.existsSync()) {
          await lcovFile.delete();
        }

        void noop(String? _) {}
        final target = DirectoryGeneratorTarget(Directory(p.normalize(cwd)));
        final workingDirectory = target.dir.absolute.path;
        final relativePath = p.relative(workingDirectory, from: initialCwd);
        final path = relativePath == '.'
            ? '.'
            : '.${p.context.separator}$relativePath';

        stdout?.call('Running "${testType.name} test" in $path ...\n');

        if (!Directory(p.join(target.dir.absolute.path, 'test')).existsSync()) {
          stdout?.call('No test folder found in $path\n');
          return ExitCode.success.code;
        }

        if (randomSeed != null) {
          stdout?.call(
            '''Shuffling test order with --test-randomize-ordering-seed=$randomSeed\n''',
          );
        }

        if (optimizePerformance) {
          final optimizationProgress = logger.progress('Optimizing tests');
          try {
            final generator = await buildGenerator(testOptimizerBundle);
            var vars = <String, dynamic>{'package-root': workingDirectory};
            await generator.hooks.preGen(
              vars: vars,
              onVarsChanged: (v) => vars = v,
              workingDirectory: workingDirectory,
            );
            await generator.generate(
              target,
              vars: vars,
              fileConflictResolution: FileConflictResolution.overwrite,
            );
          } finally {
            optimizationProgress.complete();
          }
        }
        return _overrideAnsiOutput(
          forceAnsi,
          () =>
              _testCommand(
                cwd: cwd,
                collectCoverage: collectCoverage,
                testRunner: testRunner,
                testType: testType,
                arguments: [
                  ...?arguments,
                  if (randomSeed != null) ...[
                    '--test-randomize-ordering-seed',
                    randomSeed,
                  ],
                  if (optimizePerformance)
                    p.join('test', _testOptimizerFileName),
                ],
                stdout: stdout ?? noop,
                stderr: stderr ?? noop,
              ).whenComplete(() async {
                if (optimizePerformance) {
                  await _cleanupOptimizerFile(cwd);
                }

                // Dart don't directly generate lcov files, so we need
                // to read the json that is generates and convert it to lcov.
                if (testType == TestRunType.dart && collectCoverage) {
                  final files = _dartCoverageFilesToProcess(
                    p.join(cwd, 'coverage'),
                  );

                  final packagesPath = p.join(
                    '.dart_tool',
                    'package_config.json',
                  );
                  final hitmap = await coverage.HitMap.parseFiles(
                    files,
                    packagePath: packagesPath,
                  );

                  final resolver = await coverage.Resolver.create(
                    packagesPath: packagesPath,
                    packagePath: packagesPath,
                  );

                  final output = hitmap.formatLcov(
                    resolver,
                    reportOn: ['lib'],
                    basePath: cwd,
                  );

                  // Write the lcov output to the file.
                  await lcovFile.create(recursive: true);
                  await lcovFile.writeAsString(output);
                }

                if (collectCoverage) {
                  assert(
                    lcovFile.existsSync(),
                    'coverage/lcov.info must exist',
                  );
                }

                if (minCoverage != null) {
                  final records = await Parser.parse(lcovPath);
                  final coverageMetrics = _CoverageMetrics.fromLcovRecords(
                    records,
                    excludeFromCoverage,
                  );
                  final coverage = coverageMetrics.percentage;

                  if (coverage < minCoverage) throw MinCoverageNotMet(coverage);
                }
              }),
        );
      },
      cwd: cwd,
      recursive: recursive,
      ignore: ignore,
    );
  }

  static T _overrideAnsiOutput<T>(bool? enableAnsiOutput, T Function() body) =>
      enableAnsiOutput == null
      ? body.call()
      : overrideAnsiOutput(enableAnsiOutput, body);

  /// Handles the [MinCoverageNotMet] exception by logging the error message
  static void handleMinCoverageNotMet({
    required Logger logger,
    required MinCoverageNotMet e,
    double? minCoverage,
  }) {
    var decimalPlaces = 2;

    double round(double x) {
      final b = pow(10, decimalPlaces);
      return (x * b).roundToDouble() / b;
    }

    if (e.coverage < minCoverage!) {
      var rounded = round(e.coverage);
      while (rounded == minCoverage) {
        decimalPlaces++;
        rounded = round(e.coverage);
      }
    }

    logger.err(
      '''Expected coverage >= ${minCoverage.toStringAsFixed(decimalPlaces)}% but actual is ${e.coverage.toStringAsFixed(decimalPlaces)}%.''',
    );
  }

  static List<File> _dartCoverageFilesToProcess(String absPath) {
    return Directory(absPath)
        .listSync(recursive: true)
        .whereType<File>()
        .where((e) => e.path.endsWith('.json'))
        .toList();
  }
}

Future<int> _testCommand({
  required void Function(String) stdout,
  required void Function(String) stderr,
  required VeryGoodTestRunner testRunner,
  required TestRunType testType,
  String cwd = '.',
  bool collectCoverage = false,
  List<String>? arguments,
}) {
  const clearLine = '\u001B[2K\r';

  final completer = Completer<int>();
  final suites = <int, TestSuite>{};
  final groups = <int, TestGroup>{};
  final tests = <int, Test>{};
  final failedTestErrorMessages = <String, List<String>>{};
  final sigintWatch =
      ProcessSignalOverrides.current?.sigintWatch ??
      ProcessSignal.sigint.watch();

  var successCount = 0;
  var skipCount = 0;

  String computeStats() {
    final passingTests = successCount.formatSuccess();
    final failingTests = failedTestErrorMessages.values
        .expand((e) => e)
        .length
        .formatFailure();
    final skippedTests = skipCount.formatSkipped();
    final result = [passingTests, failingTests, skippedTests]
      ..removeWhere((element) => element.isEmpty);
    return result.join(' ');
  }

  final timerSubscription =
      Stream.periodic(
        const Duration(seconds: 1),
        (computationCount) => computationCount,
      ).listen((tick) {
        if (completer.isCompleted) return;
        final timeElapsed = Duration(seconds: tick).formatted();
        stdout('$clearLine$timeElapsed ...');
      });

  late final StreamSubscription<TestEvent> subscription;
  late final StreamSubscription<ProcessSignal> sigintWatchSubscription;

  sigintWatchSubscription = sigintWatch.listen((_) async {
    await _cleanupOptimizerFile(cwd);
    await subscription.cancel();
    await sigintWatchSubscription.cancel();
    return completer.complete(ExitCode.success.code);
  });

  subscription =
      testRunner(
        workingDirectory: cwd,
        arguments: [
          if (collectCoverage)
            testType == TestRunType.flutter
                ? '--coverage'
                : '--coverage=coverage',
          ...?arguments,
        ],
        runInShell: true,
      ).listen(
        (event) {
          if (event.shouldCancelTimer()) timerSubscription.cancel();
          if (event is SuiteTestEvent) suites[event.suite.id] = event.suite;
          if (event is GroupTestEvent) groups[event.group.id] = event.group;
          if (event is TestStartEvent) tests[event.test.id] = event.test;

          if (event is MessageTestEvent) {
            if (event.message.startsWith('Skip:')) {
              stdout('$clearLine${lightYellow.wrap(event.message)}\n');
            } else if (event.message.contains('EXCEPTION')) {
              stderr('$clearLine${event.message}');
            } else {
              stdout('$clearLine${event.message}\n');
            }
          }

          if (event is ErrorTestEvent) {
            stderr('$clearLine${event.error}');

            if (event.stackTrace.trim().isNotEmpty) {
              stderr('$clearLine${event.stackTrace}');
            }

            final test = tests[event.testID]!;
            final suite = suites[test.suiteID]!;
            final prefix = event.isFailure ? '[FAILED]' : '[ERROR]';

            final optimizationApplied = _isOptimizationApplied(suite);

            var testPath = suite.path!;
            var testName = test.name;

            // When there is a test error before any group is computed, it
            // means that there is an error when compiling the test optimizer
            // file.
            if (optimizationApplied && groups.isNotEmpty) {
              final topGroupName = _topGroupName(test, groups)!;

              testPath = testPath.replaceFirst(
                _testOptimizerFileName,
                topGroupName,
              );

              testName = testName.replaceFirst(topGroupName, '').trim();
            }

            final relativeTestPath = p.relative(testPath, from: cwd);
            failedTestErrorMessages[relativeTestPath] = [
              ...failedTestErrorMessages[relativeTestPath] ?? [],
              '$prefix $testName',
            ];
          }

          if (event is TestDoneEvent) {
            if (event.hidden) return;

            final test = tests[event.testID]!;
            final suite = suites[test.suiteID]!;
            final optimizationApplied = _isOptimizationApplied(suite);

            var testPath = suite.path!;
            var testName = test.name;

            if (optimizationApplied) {
              final firstGroupName = _topGroupName(test, groups) ?? '';
              testPath = testPath.replaceFirst(
                _testOptimizerFileName,
                firstGroupName,
              );
              testName = testName.replaceFirst(firstGroupName, '').trim();
            }

            if (event.skipped) {
              stdout(
                '''$clearLine${lightYellow.wrap('$testName $testPath (SKIPPED)')}\n''',
              );
              skipCount++;
            } else if (event.result == TestResult.success) {
              successCount++;
            } else {
              stderr('$clearLine$testName $testPath (FAILED)');
            }

            final timeElapsed = Duration(milliseconds: event.time).formatted();
            final stats = computeStats();
            final truncatedTestName = testName.toSingleLine().truncated(
              _lineLength - (timeElapsed.length + stats.length + 2),
            );
            stdout('''$clearLine$timeElapsed $stats: $truncatedTestName''');
          }

          if (event is DoneTestEvent) {
            final timeElapsed = Duration(milliseconds: event.time).formatted();
            final stats = computeStats();
            final summary = event.success ?? false
                ? lightGreen.wrap('All tests passed!')!
                : lightRed.wrap('Some tests failed.')!;

            stdout(
              '$clearLine${darkGray.wrap(timeElapsed)} $stats: $summary\n',
            );

            if (event.success != true) {
              assert(
                failedTestErrorMessages.isNotEmpty,
                'Invalid state: test event report as failed '
                'but no failed tests were gathered',
              );
              final title = styleBold.wrap('Failing Tests:');

              final lines = StringBuffer('$clearLine$title\n');
              for (final testSuiteErrorMessages
                  in failedTestErrorMessages.entries) {
                lines.writeln('$clearLine - ${testSuiteErrorMessages.key} ');

                for (final errorMessage in testSuiteErrorMessages.value) {
                  lines.writeln('$clearLine \t- $errorMessage');
                }
              }

              stderr(lines.toString());
            }
          }

          if (event is ExitTestEvent) {
            if (completer.isCompleted) return;
            subscription.cancel();
            sigintWatchSubscription.cancel();

            completer.complete(
              event.exitCode == ExitCode.success.code
                  ? ExitCode.success.code
                  : ExitCode.unavailable.code,
            );
          }
        },
        onError: (Object error, StackTrace stackTrace) {
          stderr('$clearLine$error');
          stderr('$clearLine$stackTrace');
        },
      );

  return completer.future;
}

bool _isOptimizationApplied(TestSuite suite) =>
    suite.path?.contains(_testOptimizerFileName) ?? false;

String? _topGroupName(Test test, Map<int, TestGroup> groups) => test.groupIDs
    .map((groupID) => groups[groupID]?.name)
    .firstWhereOrNull((groupName) => groupName?.isNotEmpty ?? false);

Future<void> _cleanupOptimizerFile(String cwd) async =>
    File(p.join(cwd, 'test', _testOptimizerFileName)).delete().ignore();

final int _lineLength = () {
  try {
    return stdout.terminalColumns;
  } on StdoutException {
    return 80;
  }
}();
