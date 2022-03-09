part of 'cli.dart';

/// Thrown when `flutter packages get` or `flutter pub get`
/// is executed without a `pubspec.yaml`.
class PubspecNotFound implements Exception {}

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
          final result = await _Cmd.run(
            'flutter',
            ['packages', 'get'],
            workingDirectory: cwd,
          );
          return result;
        } catch (_) {
          rethrow;
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
    void Function(String)? stdout,
    void Function(String)? stderr,
  }) {
    return _runCommand(
      cmd: (cwd) {
        stdout?.call('Running "flutter test" in $cwd...\n');
        return _flutterTest(cwd: cwd, stdout: stdout, stderr: stderr);
      },
      cwd: cwd,
      recursive: recursive,
    );
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
  void Function(String)? stdout,
  void Function(String)? stderr,
}) {
  final _stdout = stdout ?? (String _) {};
  final _stderr = stderr ?? (String _) {};
  const clearLine = '\u001B[2K\r';

  final completer = Completer<void>();
  final suites = <int, TestSuite>{};
  final groups = <int, TestGroup>{};
  final tests = <int, Test>{};
  final stopwatch = Stopwatch()..start();

  var successCount = 0;
  var skipCount = 0;
  var failureCount = 0;

  final timerSubscription =
      Stream.periodic(const Duration(seconds: 1), (_) => _).listen(
    (tick) {
      if (completer.isCompleted) return;
      final timeElapsed = Duration(seconds: tick).formatted();
      _stdout('$clearLine$timeElapsed ...');
    },
  );

  flutterTest(workingDirectory: cwd).listen(
    (event) {
      if (event is SuiteTestEvent) suites[event.suite.id] = event.suite;
      if (event is GroupTestEvent) groups[event.group.id] = event.group;
      if (event is TestStartEvent) tests[event.test.id] = event.test;

      if (event is MessageTestEvent) {
        timerSubscription.cancel();
        if (event.message.startsWith('Skip:')) {
          _stdout('$clearLine${lightYellow.wrap(event.message)}\n');
        } else if (event.message.contains('EXCEPTION')) {
          _stderr('$clearLine${event.message}');
        } else {
          _stdout('$clearLine${event.message}\n');
        }
      }

      if (event is ErrorTestEvent) {
        timerSubscription.cancel();
        _stderr(event.error);
        if (event.stackTrace.trim().isNotEmpty) _stderr(event.stackTrace);
      }

      if (event is TestDoneEvent) {
        if (event.hidden) return;
        timerSubscription.cancel();

        final test = tests[event.testID]!;
        final suite = suites[test.suiteID]!;

        if (event.skipped) {
          _stdout(
            '''$clearLine${lightYellow.wrap('${test.name} ${suite.path} (SKIPPED)')}\n''',
          );
          skipCount++;
        } else if (event.result == TestResult.success) {
          successCount++;
        } else {
          _stderr('$clearLine${test.name} ${suite.path} (FAILED)');
          failureCount++;
        }

        final timeElapsed = Duration(milliseconds: event.time).formatted();
        final passingTests = successCount.formatSuccess();
        final failingTests = failureCount.formatFailure();
        final skippedTests = skipCount.formatSkipped();
        final result = [passingTests, failingTests, skippedTests]
          ..removeWhere((element) => element.isEmpty);
        final stats = result.join(' ');

        _stdout('$clearLine$timeElapsed $stats: ${test.name}');
      }

      if (event is DoneTestEvent) {
        timerSubscription.cancel();
        stopwatch.stop();
        final timeElapsed = Duration(
          milliseconds: stopwatch.elapsedMilliseconds,
        ).formatted();
        final passingTests = successCount.formatSuccess();
        final failingTests = failureCount.formatFailure();
        final skippedTests = skipCount.formatSkipped();
        final result = [passingTests, failingTests, skippedTests]
          ..removeWhere((element) => element.isEmpty);
        final stats = result.join(' ');
        final summary = event.success == true
            ? lightGreen.wrap('All tests passed!')!
            : lightRed.wrap('Some tests failed.')!;

        _stdout('$clearLine${darkGray.wrap(timeElapsed)} $stats: $summary\n');
        completer.complete();
      }
    },
    onError: completer.completeError,
  );

  return completer.future;
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
