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

/// How to collect coverage.
enum CoverageCollectionMode {
  /// Collect coverage from imported files only (default behavior).
  imports,

  /// Collect coverage from all files in the project.
  all
  ;

  /// Parses a string value into a [CoverageCollectionMode].
  static CoverageCollectionMode fromString(String value) {
    return CoverageCollectionMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => CoverageCollectionMode.imports,
    );
  }
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
    CoverageCollectionMode collectCoverageFrom = CoverageCollectionMode.imports,
    String? randomSeed,
    bool? forceAnsi,
    List<String>? arguments,
    void Function(String)? stdout,
    void Function(String)? stderr,
    GeneratorBuilder buildGenerator = MasonGenerator.fromBundle,
    String? reportOn,
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
        var vars = <String, dynamic>{'package-root': workingDirectory};
        if (optimizePerformance) {
          final optimizationProgress = logger.progress('Optimizing tests');
          try {
            final generator = await buildGenerator(testOptimizerBundle);
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

        final notOptimizedTests =
            vars['notOptimizedTests'] as List<dynamic>? ?? [];
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
                  // Include non-optimized tests that require separate execution
                  if (notOptimizedTests.isNotEmpty && optimizePerformance)
                    ...notOptimizedTests.map(
                      (e) => p.join('test', e.toString()),
                    ),
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
                    reportOn: [reportOn ?? 'lib'],
                    basePath: cwd,
                  );

                  // Write the lcov output to the file.
                  await lcovFile.create(recursive: true);
                  await lcovFile.writeAsString(output);

                  // If collectCoverageFrom is 'all', enhance with untested
                  // files
                  if (collectCoverageFrom == CoverageCollectionMode.all) {
                    await _enhanceLcovWithUntestedFiles(
                      lcovPath: lcovPath,
                      cwd: cwd,
                      reportOn: reportOn ?? 'lib',
                      excludeFromCoverage: excludeFromCoverage,
                    );
                  }
                }

                if (collectCoverage) {
                  assert(
                    lcovFile.existsSync(),
                    'coverage/lcov.info must exist',
                  );

                  // For Flutter tests with collectCoverageFrom = all, enhance
                  // lcov
                  if (testType == TestRunType.flutter &&
                      collectCoverageFrom == CoverageCollectionMode.all) {
                    await _enhanceLcovWithUntestedFiles(
                      lcovPath: lcovPath,
                      cwd: cwd,
                      reportOn: 'lib',
                      excludeFromCoverage: excludeFromCoverage,
                    );
                  }
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

  /// Discovers all Dart files in the specified directory for coverage.
  static List<String> _discoverDartFilesForCoverage({
    required String cwd,
    required String reportOn,
    String? excludeFromCoverage,
  }) {
    final reportOnPath = p.join(cwd, reportOn);
    final directory = Directory(reportOnPath);

    if (!directory.existsSync()) return [];

    final glob = excludeFromCoverage != null ? Glob(excludeFromCoverage) : null;

    return directory
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .where((file) => glob == null || !glob.matches(file.path))
        .map((file) => p.relative(file.path, from: cwd))
        .toList();
  }

  /// Enhances an existing lcov file by adding uncovered files with 0% coverage.
  static Future<void> _enhanceLcovWithUntestedFiles({
    required String lcovPath,
    required String cwd,
    required String reportOn,
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
    final coveredFiles = existingRecords
        .where((r) => r.file != null)
        .map((r) => r.file!)
        .toSet();

    // Find uncovered files
    final uncoveredFiles = allDartFiles.where((file) {
      final normalizedFile = p.normalize(file);
      for (final covered in coveredFiles) {
        if (p.normalize(covered).endsWith(normalizedFile)) {
          return false; // File is covered
        }
      }
      return true; // File is uncovered
    }).toList();

    if (uncoveredFiles.isEmpty) return;

    // Append uncovered files to lcov
    final lcovContent = await lcovFile.readAsString();
    final buffer = StringBuffer(lcovContent);

    for (final file in uncoveredFiles) {
      final absolutePath = p.join(cwd, file);
      final dartFile = File(absolutePath);
      if (dartFile.existsSync()) {
        final lines = await dartFile.readAsLines();
        buffer.writeln('SF:$file');
        // Mark non-trivial lines as uncovered
        for (var i = 1; i <= lines.length; i++) {
          final line = lines[i - 1].trim();
          if (line.isNotEmpty &&
              !line.startsWith('//') &&
              !line.startsWith('import') &&
              !line.startsWith('export') &&
              !line.startsWith('part')) {
            buffer.writeln('DA:$i,0');
          }
        }
        buffer.writeln('end_of_record');
      }
    }

    await lcovFile.writeAsString(buffer.toString());
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
        (event) async {
          if (event.shouldCancelTimer()) unawaited(timerSubscription.cancel());
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
            unawaited(subscription.cancel());
            unawaited(sigintWatchSubscription.cancel());

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
