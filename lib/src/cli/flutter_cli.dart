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

/// Thrown when `flutter test ---coverage --min-coverage value`
/// does not generate the coverage file within the timeout threshold.
class GenerateCoverageTimeout implements Exception {
  @override
  String toString() => 'Timed out waiting for coverage to be generated.';
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

/// Flutter CLI
class Flutter {
  /// Determine whether flutter is installed.
  static Future<bool> installed() async {
    try {
      await _Cmd.run('flutter', ['--version']);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Install flutter dependencies (`flutter packages get`).
  static Future<void> packagesGet({
    String cwd = '.',
    bool recursive = false,
    void Function([String?]) Function(String message)? progress,
  }) async {
    await _runCommand(
      cmd: (cwd) async {
        final installDone = progress?.call(
          'Running "flutter packages get" in $cwd',
        );
        try {
          await _Cmd.run(
            'flutter',
            ['packages', 'get'],
            workingDirectory: cwd,
          );
        } finally {
          installDone?.call();
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
  }) async {
    await _runCommand(
      cmd: (cwd) => _Cmd.run(
        'flutter',
        ['pub', 'get'],
        workingDirectory: cwd,
      ),
      cwd: cwd,
      recursive: recursive,
    );
  }

  /// Run tests (`flutter test`).
  static Future<void> test({
    String cwd = '.',
    bool recursive = false,
    bool collectCoverage = false,
    bool optimizePerformance = false,
    double? minCoverage,
    String? excludeFromCoverage,
    List<String>? arguments,
    void Function([String?]) Function(String message)? progress,
    void Function(String)? stdout,
    void Function(String)? stderr,
  }) async {
    final lcovPath = p.join(cwd, 'coverage', 'lcov.info');
    final lcovFile = File(lcovPath);

    if (collectCoverage && lcovFile.existsSync()) {
      await lcovFile.delete();
    }

    await _runCommand(
      cmd: (cwd) async {
        void noop(String? _) {}
        final target = DirectoryGeneratorTarget(Directory(p.normalize(cwd)));
        final workingDirectory = target.dir.absolute.path;
        stdout?.call(
          'Running "flutter test" in ${p.dirname(workingDirectory)}...\n',
        );

        if (optimizePerformance) {
          final optimizationDone = progress?.call('Optimizing tests');
          try {
            final generator = await MasonGenerator.fromBundle(testRunnerBundle);
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
            optimizationDone?.call();
          }
        }

        return _flutterTest(
          cwd: cwd,
          collectCoverage: collectCoverage,
          arguments: [
            ...?arguments,
            if (optimizePerformance) p.join('test', '.test_runner.dart')
          ],
          stdout: stdout ?? noop,
          stderr: stderr ?? noop,
        );
      },
      cwd: cwd,
      recursive: recursive,
    );

    if (optimizePerformance) {
      File(p.join(cwd, 'test', '.test_runner.dart')).delete().ignore();
    }
    if (collectCoverage) await lcovFile.ensureCreated();
    if (minCoverage != null) {
      final records = await Parser.parse(lcovPath);
      final coverageMetrics = _CoverageMetrics.fromLcovRecords(
        records,
        excludeFromCoverage,
      );
      final coverage = coverageMetrics.percentage;
      if (coverage < minCoverage) throw MinCoverageNotMet(coverage);
    }
  }
}

/// Run a command on directories with a `pubspec.yaml`.
Future<void> _runCommand<T>({
  required Future<T> Function(String cwd) cmd,
  required String cwd,
  required bool recursive,
}) async {
  if (!recursive) {
    final pubspec = File(p.join(cwd, 'pubspec.yaml'));
    if (!pubspec.existsSync()) throw PubspecNotFound();

    await cmd(cwd);
    return;
  }

  final processes = _Cmd.runWhere(
    run: (entity) => cmd(entity.parent.path),
    where: _isPubspec,
    cwd: cwd,
  );

  if (processes.isEmpty) throw PubspecNotFound();

  for (final process in processes) {
    await process;
  }
}

Future<void> _flutterTest({
  String cwd = '.',
  bool collectCoverage = false,
  List<String>? arguments,
  required void Function(String) stdout,
  required void Function(String) stderr,
}) {
  const clearLine = '\u001B[2K\r';

  final completer = Completer<void>();
  final suites = <int, TestSuite>{};
  final groups = <int, TestGroup>{};
  final tests = <int, Test>{};

  var successCount = 0;
  var skipCount = 0;
  var failureCount = 0;

  String computeStats() {
    final passingTests = successCount.formatSuccess();
    final failingTests = failureCount.formatFailure();
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

  flutterTest(
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
          failureCount++;
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
        completer.complete();
      }
    },
    onError: completer.completeError,
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

extension on File {
  Future<void> ensureCreated({
    Duration timeout = const Duration(seconds: 1),
    Duration interval = const Duration(milliseconds: 50),
  }) async {
    var elapsedTime = Duration.zero;
    while (!existsSync()) {
      await Future<void>.delayed(interval);
      elapsedTime += interval;
      if (elapsedTime >= timeout) throw GenerateCoverageTimeout();
    }
  }
}

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
