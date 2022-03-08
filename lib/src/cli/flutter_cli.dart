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
  }) async {
    await _runCommand(
      cmd: (cwd) {
        stdout?.call('\nRunning "flutter test" in $cwd...\n');
        return _flutterTest(cwd: cwd, stdout: stdout, stderr: stderr);
      },
      cwd: cwd,
      recursive: recursive,
    );
  }

  static Future<ProcessResult> _flutterTest({
    String cwd = '.',
    void Function(String)? stdout,
    void Function(String)? stderr,
  }) {
    final _stdout = stdout ?? (String _) {};
    final _stderr = stderr ?? (String _) {};
    const clearLine = '\u001B[2K\r';

    final completer = Completer<ProcessResult>();
    final groups = <int, TestGroup>{};
    final tests = <int, Test>{};
    final stopwatch = Stopwatch()..start();

    var successCount = 0;
    var skipCount = 0;
    var failureCount = 0;

    final timerSubscription =
        Stream.periodic(const Duration(seconds: 1), (_) => _).listen(
      (tick) {
        final timeElapsed = Duration(seconds: tick).formatted();
        _stdout('$clearLine${darkGray.wrap(timeElapsed)}');
      },
    );

    flutterTest(workingDirectory: cwd).listen(
      (event) {
        if (event is GroupTestEvent) groups[event.group.id] = event.group;
        if (event is TestStartEvent) tests[event.test.id] = event.test;
        if (event is MessageTestEvent) {
          _stderr('$clearLine  ${event.message}');
        }

        if (event is ErrorTestEvent) {
          timerSubscription.cancel();
          _stderr(event.error);
          if (event.stackTrace.trim().isNotEmpty) {
            _stderr(event.stackTrace);
          }
        }

        if (event is TestDoneEvent) {
          if (event.hidden) return;
          timerSubscription.cancel();
          final test = tests[event.testID]!;
          var skipped = false;
          var failed = false;
          if (event.skipped) {
            skipCount++;
            skipped = true;
          } else if (event.result == TestResult.success) {
            successCount++;
          } else {
            failureCount++;
            failed = true;
          }

          if (skipped) {
            _stdout('  ${lightYellow.wrap('${test.name} (SKIPPED)')}\n');
          }

          if (failed) _stderr('  ${test.name} (FAILED)\n');

          final passingTests =
              successCount > 0 ? lightGreen.wrap('+$successCount')! : '';
          final failingTests =
              failureCount > 0 ? lightRed.wrap('-$failureCount')! : '';
          final skippedTests =
              skipCount > 0 ? lightYellow.wrap('~$skipCount')! : '';
          final result = [passingTests, failingTests, skippedTests]
            ..removeWhere((element) => element.isEmpty);
          final timeElapsed = Duration(milliseconds: event.time).formatted();

          _stdout(
            '''$clearLine${darkGray.wrap(timeElapsed)} ${result.join(' ')}: ${test.name}''',
          );
        }

        if (event is DoneTestEvent) {
          stopwatch.stop();
          final timeElapsed = Duration(
            milliseconds: stopwatch.elapsedMilliseconds,
          ).formatted();
          stopwatch.reset();
          if (event.success == true) {
            return _stdout(
              '''$clearLine${darkGray.wrap(timeElapsed)} ${lightGreen.wrap('+$successCount')}: ${lightGreen.wrap('All tests passed!')}\n''',
            );
          }

          final passingTests =
              successCount > 0 ? lightGreen.wrap('+$successCount')! : '';
          final failingTests =
              failureCount > 0 ? lightRed.wrap('-$failureCount')! : '';
          final skippedTests =
              skipCount > 0 ? lightYellow.wrap('~$skipCount')! : '';
          final result = [passingTests, failingTests, skippedTests]
            ..removeWhere((element) => element.isEmpty);
          _stdout(
            '''$clearLine${darkGray.wrap(timeElapsed)} ${result.join(' ')}: ${lightRed.wrap('Some tests failed.')}\n''',
          );
        }

        if (event is TestProcessDone) completer.complete(event.result);
      },
      onError: completer.completeError,
    );
    return completer.future;
  }

  /// Run a command on directories with a `pubspec.yaml`.
  static Future<void> _runCommand({
    required Future<ProcessResult> Function(String cwd) cmd,
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
}

extension on Duration {
  String formatted() {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final twoDigitMinutes = twoDigits(inMinutes.remainder(60));
    final twoDigitSeconds = twoDigits(inSeconds.remainder(60));
    return '$twoDigitMinutes:$twoDigitSeconds';
  }
}
