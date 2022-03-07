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
    void Function(String message)? stdout,
    void Function(String message)? stderr,
  }) {
    final stream = _parseTestJson(
      () => Process.start(
        'flutter',
        ['test', '--reporter=json', '--no-pub'],
        workingDirectory: cwd,
        runInShell: true,
      ),
    );
    const clearPreviousLine = '\x1b[A\u001B[2K';

    final completer = Completer<void>();
    final groups = <int, TestGroup>{};
    final tests = <int, Test>{};
    final stopwatch = Stopwatch()..start();

    var successCount = 0;
    var skipCount = 0;
    var failureCount = 0;

    stream.listen((event) {
      if (event is GroupTestEvent) groups[event.group.id] = event.group;
      if (event is TestStartEvent) tests[event.test.id] = event.test;
      if (event is MessageTestEvent) {
        stderr?.call('$clearPreviousLine${event.message}');
      }
      if (event is ErrorTestEvent) {
        stderr?.call(event.error);
        if (event.stackTrace.trim().isNotEmpty) {
          stderr?.call(event.stackTrace);
        }
      }
      if (event is TestDoneEvent) {
        if (event.hidden) return;
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
          stdout?.call('  ${lightYellow.wrap('${test.name} (SKIPPED)')}');
          stdout?.call('');
        }

        if (failed) {
          stderr?.call('  ${test.name} (FAILED)');
          stderr?.call('');
        }

        final passingTests =
            successCount > 0 ? lightGreen.wrap('+$successCount')! : '';
        final failingTests =
            failureCount > 0 ? lightRed.wrap('-$failureCount')! : '';
        final skippedTests =
            skipCount > 0 ? lightYellow.wrap('~$skipCount')! : '';
        final result = [passingTests, failingTests, skippedTests]
          ..removeWhere((element) => element.isEmpty);
        final timeElapsed = Duration(milliseconds: event.time).formatted();

        stdout?.call(
          '''$clearPreviousLine${darkGray.wrap(timeElapsed)} ${result.join(' ')}: ${test.name}''',
        );
      }
      if (event is DoneTestEvent) {
        stopwatch.stop();
        final timeElapsed = Duration(
          milliseconds: stopwatch.elapsedMilliseconds,
        ).formatted();
        if (event.success == true) {
          return stdout?.call(
            '''$clearPreviousLine${darkGray.wrap(timeElapsed)} ${lightGreen.wrap('+$successCount')}: ${lightGreen.wrap('All tests passed!')}''',
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
        stdout?.call(
          '''$clearPreviousLine${darkGray.wrap(timeElapsed)} ${result.join(' ')}: ${lightRed.wrap('Some tests failed.')}''',
        );
      }
      if (event is DoneTestEvent) completer.complete();
    });
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

Stream<TestEvent> _parseTestJson(
  Future<Process> Function() processCallback,
) {
  final controller = StreamController<TestEvent>();
  late StreamSubscription eventSub;
  late Future<Process> processFuture;

  controller
    ..onListen = () async {
      processFuture = processCallback();
      final process = await processFuture;

      final events = process.stdout
          .map(utf8.decode)
          .expand<String>((msg) sync* {
            for (final value in msg.split('\n')) {
              final trimmedValue = value.trim();
              if (trimmedValue.isNotEmpty) yield trimmedValue;
            }
          })
          .expand<Object?>((j) {
            try {
              return [json.decode(j)];
            } on FormatException {
              return [];
            }
          })
          .cast<Map<Object?, Object?>>()
          .map((json) => TestEvent.fromJson(Map<String, dynamic>.from(json)));

      eventSub = events.listen(
        controller.add,
        onError: controller.addError,
        onDone: () async {
          await controller.close();
        },
      );
    }
    ..onCancel = () async {
      await controller.close();
      (await processFuture).kill();
      await eventSub.cancel();
    };

  return controller.stream;
}

extension on Duration {
  String formatted() {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final twoDigitMinutes = twoDigits(inMinutes.remainder(60));
    final twoDigitSeconds = twoDigits(inSeconds.remainder(60));
    return '$twoDigitMinutes:$twoDigitSeconds';
  }
}
