part of 'cli.dart';

/// Thrown when `flutter packages get` or `flutter pub get`
/// is executed without a `pubspec.yaml`.
class PubspecNotFound implements Exception {}

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

class _CoverageMetrics {
  const _CoverageMetrics._({this.totalHits = 0, this.totalFound = 0});

  /// Generate coverage metrics from a list of lcov records.
  factory _CoverageMetrics.fromLcovRecords(
    List<Record> records,
    String? excludeFromCoverage,
  ) {
    final glob = excludeFromCoverage != null ? Glob(excludeFromCoverage) : null;
    return records.fold<_CoverageMetrics>(
      const _CoverageMetrics._(),
      (current, record) {
        final found = record.lines?.found ?? 0;
        final hit = record.lines?.hit ?? 0;
        if (glob != null && record.file != null) {
          if (glob.matches(record.file!)) {
            return current;
          }
        }
        return _CoverageMetrics._(
          totalFound: current.totalFound + found,
          totalHits: current.totalHits + hit,
        );
      },
    );
  }

  final int totalHits;
  final int totalFound;

  double get percentage => totalFound < 1 ? 0 : (totalHits / totalFound * 100);
}

/// Type definition for the [flutterTest] command
/// from 'package:very_good_test_runner`.
typedef FlutterTestRunner = Stream<TestEvent> Function({
  List<String>? arguments,
  String? workingDirectory,
  Map<String, String>? environment,
  bool runInShell,
});

/// A method which returns a [Future<MasonGenerator>] given a [MasonBundle].
typedef GeneratorBuilder = Future<MasonGenerator> Function(MasonBundle);

/// Flutter CLI
class Flutter {
  /// Determine whether flutter is installed.
  static Future<bool> installed({
    required Logger logger,
  }) async {
    try {
      await _Cmd.run('flutter', ['--version'], logger: logger);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Install flutter dependencies (`flutter packages get`).
  static Future<void> packagesGet({
    String cwd = '.',
    bool recursive = false,
    required Logger logger,
  }) async {
    await _runCommand(
      cmd: (cwd) async {
        final installProgress = logger.progress(
          'Running "flutter packages get" in $cwd',
        );

        try {
          await _verifyGitDependencies(cwd, logger: logger);
        } catch (_) {
          installProgress.fail();
          rethrow;
        }

        try {
          await _Cmd.run(
            'flutter',
            ['packages', 'get'],
            workingDirectory: cwd,
            logger: logger,
          );
        } finally {
          installProgress.complete();
        }
      },
      cwd: cwd,
      recursive: recursive,
    );
  }

  /// Install dart dependencies (`flutter pub get`).
  static Future<void> pubGet({
    String cwd = '.',
    bool recursive = false,
    required Logger logger,
  }) async {
    await _runCommand(
      cmd: (cwd) => _Cmd.run(
        'flutter',
        ['pub', 'get'],
        workingDirectory: cwd,
        logger: logger,
      ),
      cwd: cwd,
      recursive: recursive,
    );
  }

  /// Run tests (`flutter test`).
  /// Returns a list of exit codes for each test process.
  static Future<List<int>> test({
    String cwd = '.',
    bool recursive = false,
    bool collectCoverage = false,
    bool optimizePerformance = false,
    double? minCoverage,
    String? excludeFromCoverage,
    String? randomSeed,
    List<String>? arguments,
    required Logger logger,
    void Function(String)? stdout,
    void Function(String)? stderr,
    FlutterTestRunner testRunner = flutterTest,
    GeneratorBuilder buildGenerator = MasonGenerator.fromBundle,
  }) async {
    final lcovPath = p.join(cwd, 'coverage', 'lcov.info');
    final lcovFile = File(lcovPath);

    if (collectCoverage && lcovFile.existsSync()) {
      await lcovFile.delete();
    }

    final results = await _runCommand<int>(
      cmd: (cwd) async {
        void noop(String? _) {}
        final target = DirectoryGeneratorTarget(Directory(p.normalize(cwd)));
        final workingDirectory = target.dir.absolute.path;

        stdout?.call(
          'Running "flutter test" in ${p.dirname(workingDirectory)}...\n',
        );

        if (!Directory(p.join(target.dir.absolute.path, 'test')).existsSync()) {
          stdout?.call(
            'No test folder found in ${target.dir.absolute.path}\n',
          );
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
            final generator = await buildGenerator(testRunnerBundle);
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

        return _flutterTest(
          cwd: cwd,
          collectCoverage: collectCoverage,
          testRunner: testRunner,
          arguments: [
            ...?arguments,
            if (randomSeed != null) ...[
              '--test-randomize-ordering-seed',
              randomSeed
            ],
            if (optimizePerformance) p.join('test', '.test_runner.dart')
          ],
          stdout: stdout ?? noop,
          stderr: stderr ?? noop,
        ).whenComplete(() {
          if (optimizePerformance) {
            File(p.join(cwd, 'test', '.test_runner.dart')).delete().ignore();
          }
        });
      },
      cwd: cwd,
      recursive: recursive,
    );

    if (collectCoverage) {
      assert(lcovFile.existsSync(), 'coverage/lcov.info must exist');
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
    return results;
  }
}

/// Ensures all git dependencies are reachable for the pubspec
/// located in the [cwd].
///
/// If any git dependencies are unreachable,
/// an [UnreachableGitDependency] is thrown.
Future<void> _verifyGitDependencies(
  String cwd, {
  required Logger logger,
}) async {
  final pubspec = Pubspec.parse(
    await File(p.join(cwd, 'pubspec.yaml')).readAsString(),
  );

  final dependencies = pubspec.dependencies;
  final devDependencies = pubspec.devDependencies;
  final dependencyOverrides = pubspec.dependencyOverrides;
  final gitDependencies = [
    ...dependencies.entries,
    ...devDependencies.entries,
    ...dependencyOverrides.entries
  ]
      .where((entry) => entry.value is GitDependency)
      .map((entry) => entry.value)
      .cast<GitDependency>()
      .toList();

  await Future.wait(
    gitDependencies.map(
      (dependency) => Git.reachable(
        dependency.url,
        logger: logger,
      ),
    ),
  );
}

/// Run a command on directories with a `pubspec.yaml`.
Future<List<T>> _runCommand<T>({
  required Future<T> Function(String cwd) cmd,
  required String cwd,
  required bool recursive,
}) async {
  if (!recursive) {
    final pubspec = File(p.join(cwd, 'pubspec.yaml'));
    if (!pubspec.existsSync()) throw PubspecNotFound();

    return [await cmd(cwd)];
  }

  final processes = _Cmd.runWhere<T>(
    run: (entity) => cmd(entity.parent.path),
    where: _isPubspec,
    cwd: cwd,
  );

  if (processes.isEmpty) throw PubspecNotFound();

  final results = <T>[];
  for (final process in processes) {
    results.add(await process);
  }
  return results;
}

Future<int> _flutterTest({
  String cwd = '.',
  bool collectCoverage = false,
  List<String>? arguments,
  FlutterTestRunner testRunner = flutterTest,
  required void Function(String) stdout,
  required void Function(String) stderr,
}) {
  const clearLine = '\u001B[2K\r';

  final completer = Completer<int>();
  final suites = <int, TestSuite>{};
  final groups = <int, TestGroup>{};
  final tests = <int, Test>{};
  final failedTestErrorMessages = <int, String>{};

  var successCount = 0;
  var skipCount = 0;

  String computeStats() {
    final passingTests = successCount.formatSuccess();
    final failingTests = failedTestErrorMessages.length.formatFailure();
    final skippedTests = skipCount.formatSkipped();
    final result = [passingTests, failingTests, skippedTests]
      ..removeWhere((element) => element.isEmpty);
    return result.join(' ');
  }

  final timerSubscription =
      Stream.periodic(const Duration(seconds: 1), (_) => _).listen(
    (tick) {
      if (completer.isCompleted) return;
      final timeElapsed = Duration(seconds: tick).formatted();
      stdout('$clearLine$timeElapsed ...');
    },
  );

  late final StreamSubscription<TestEvent> subscription;
  subscription = testRunner(
    workingDirectory: cwd,
    arguments: [
      if (collectCoverage) '--coverage',
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

        final traceLocation = _getTraceLocation(stackTrace: event.stackTrace);

        // When failing to recover the location from the stack trace,
        // save a short description of the error
        final testErrorDescription = traceLocation ??
            event.error.replaceAll('\n', ' ').truncated(_lineLength);

        final prefix = event.isFailure ? '[FAILED]' : '[ERROR]';
        failedTestErrorMessages[event.testID] = '$prefix $testErrorDescription';
      }

      if (event is TestDoneEvent) {
        if (event.hidden) return;

        final test = tests[event.testID]!;
        final suite = suites[test.suiteID]!;

        if (event.skipped) {
          stdout(
            '''$clearLine${lightYellow.wrap('${test.name} ${suite.path} (SKIPPED)')}\n''',
          );
          skipCount++;
        } else if (event.result == TestResult.success) {
          successCount++;
        } else {
          stderr('$clearLine${test.name} ${suite.path} (FAILED)');
        }

        final timeElapsed = Duration(milliseconds: event.time).formatted();
        final stats = computeStats();
        final testName = test.name.truncated(
          _lineLength - (timeElapsed.length + stats.length + 2),
        );
        stdout('''$clearLine$timeElapsed $stats: $testName''');
      }

      if (event is DoneTestEvent) {
        final timeElapsed = Duration(milliseconds: event.time).formatted();
        final stats = computeStats();
        final summary = event.success == true
            ? lightGreen.wrap('All tests passed!')!
            : lightRed.wrap('Some tests failed.')!;

        stdout('$clearLine${darkGray.wrap(timeElapsed)} $stats: $summary\n');

        if (event.success != true) {
          assert(
            failedTestErrorMessages.isNotEmpty,
            'Invalid state: test event report as failed but no failed tests '
            'were gathered',
          );
          final title = styleBold.wrap('Failing Tests:');

          final lines = StringBuffer('$clearLine$title\n');
          for (final errorMessage in failedTestErrorMessages.values) {
            lines.writeln('$clearLine - $errorMessage');
          }
          stderr(lines.toString());
        }
      }

      if (event is ExitTestEvent) {
        if (completer.isCompleted) return;
        subscription.cancel();
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

final int _lineLength = () {
  try {
    return stdout.terminalColumns;
  } on StdoutException {
    return 80;
  }
}();

extension on TestEvent {
  bool shouldCancelTimer() {
    final event = this;
    if (event is MessageTestEvent) return true;
    if (event is ErrorTestEvent) return true;
    if (event is DoneTestEvent) return true;
    if (event is TestDoneEvent) return !event.hidden;
    return false;
  }
}

extension on Duration {
  String formatted() {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final twoDigitMinutes = twoDigits(inMinutes.remainder(60));
    final twoDigitSeconds = twoDigits(inSeconds.remainder(60));
    return darkGray.wrap('$twoDigitMinutes:$twoDigitSeconds')!;
  }
}

extension on int {
  String formatSuccess() {
    return this > 0 ? lightGreen.wrap('+$this')! : '';
  }

  String formatFailure() {
    return this > 0 ? lightRed.wrap('-$this')! : '';
  }

  String formatSkipped() {
    return this > 0 ? lightYellow.wrap('~$this')! : '';
  }
}

extension on String {
  String truncated(int maxLength) {
    if (length <= maxLength) return this;
    final truncated = substring(length - maxLength, length).trim();
    return '...$truncated';
  }
}

String? _getTraceLocation({
  required String stackTrace,
}) {
  final trace = Trace.parse(stackTrace);
  if (trace.frames.isEmpty) {
    return null;
  }

  final lastFrame = trace.frames.last;

  final library = lastFrame.library;
  final line = lastFrame.line;
  final column = lastFrame.column;

  if (line == null) return library;
  if (column == null) return '$library:$line';
  return '$library:$line:$column';
}
