part of 'cli.dart';

const _testOptimizerFileName = '.test_optimizer.dart';

/// This class facilitates overriding `ProcessSignal` related behavior.
/// It should be extended by another class in client code with overrides
/// that construct a custom implementation.
@visibleForTesting
abstract class ProcessSignalOverrides {
  static final _token = Object();
  StreamController<ProcessSignal>? _sigintStreamController;

  /// Returns the current [ProcessSignalOverrides] instance.
  ///
  /// This will return `null` if the current [Zone] does not contain
  /// any [ProcessSignalOverrides].
  ///
  /// See also:
  /// * [ProcessSignalOverrides.runZoned] to provide [ProcessSignalOverrides]
  /// in a fresh [Zone].
  static ProcessSignalOverrides? get current {
    return Zone.current[_token] as ProcessSignalOverrides?;
  }

  /// Runs [body] in a fresh [Zone] using the provided overrides.
  static R runZoned<R>(
    R Function() body, {
    Stream<ProcessSignal>? sigintStream,
  }) {
    final overrides = _ProcessSignalOverridesScope(sigintStream);
    return _asyncRunZoned(body, zoneValues: {_token: overrides});
  }

  /// Provides a custom [Stream] of [ProcessSignal.sigint] events.
  Stream<ProcessSignal>? get sigintWatch;

  /// Emits a [ProcessSignal.sigint] event on the [sigintWatch] stream.
  ///
  /// If no custom [sigintWatch] stream is provided, this method does nothing.
  void addSIGINT() {
    _sigintStreamController?.add(ProcessSignal.sigint);
  }
}

class _ProcessSignalOverridesScope extends ProcessSignalOverrides {
  _ProcessSignalOverridesScope(Stream<ProcessSignal>? mockSigintStream) {
    if (mockSigintStream != null) {
      _sigintStreamController = StreamController<ProcessSignal>();
    }
  }

  @override
  Stream<ProcessSignal>? get sigintWatch {
    return _sigintStreamController?.stream;
  }
}

/// Thrown when `flutter pub get` is executed without a `pubspec.yaml`.
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

  /// Install dart dependencies (`flutter pub get`).
  static Future<bool> pubGet({
    required Logger logger,
    String cwd = '.',
    bool recursive = false,
    Set<String> ignore = const {},
  }) async {
    final initialCwd = cwd;

    final result = await _runCommand(
      cmd: (cwd) async {
        final relativePath = p.relative(cwd, from: initialCwd);
        final path =
            relativePath == '.' ? '.' : '.${p.context.separator}$relativePath';

        final installProgress = logger.progress(
          'Running "flutter pub get" in $path ',
        );

        try {
          await _verifyGitDependencies(cwd, logger: logger);
        } catch (_) {
          installProgress.fail();
          rethrow;
        }

        try {
          return await _Cmd.run(
            'flutter',
            ['pub', 'get'],
            workingDirectory: cwd,
            logger: logger,
          );
        } finally {
          installProgress.complete();
        }
      },
      cwd: cwd,
      recursive: recursive,
      ignore: ignore,
    );
    return result.every((e) => e.exitCode == ExitCode.success.code);
  }

  /// Run tests (`flutter test`).
  /// Returns a list of exit codes for each test process.
  static Future<List<int>> test({
    required Logger logger,
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
    FlutterTestRunner testRunner = flutterTest,
    GeneratorBuilder buildGenerator = MasonGenerator.fromBundle,
  }) async {
    final initialCwd = cwd;

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
        final path =
            relativePath == '.' ? '.' : '.${p.context.separator}$relativePath';

        stdout?.call(
          'Running "flutter test" in $path ...\n',
        );

        if (!Directory(p.join(target.dir.absolute.path, 'test')).existsSync()) {
          stdout?.call(
            'No test folder found in $path\n',
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
          () => _flutterTest(
            cwd: cwd,
            collectCoverage: collectCoverage,
            testRunner: testRunner,
            arguments: [
              ...?arguments,
              if (randomSeed != null) ...[
                '--test-randomize-ordering-seed',
                randomSeed,
              ],
              if (optimizePerformance) p.join('test', _testOptimizerFileName),
            ],
            stdout: stdout ?? noop,
            stderr: stderr ?? noop,
          ).whenComplete(() async {
            if (optimizePerformance) {
              await _cleanupOptimizerFile(cwd);
            }

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
    ...dependencyOverrides.entries,
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
  required Set<String> ignore,
}) async {
  if (!recursive) {
    final pubspec = File(p.join(cwd, 'pubspec.yaml'));
    if (!pubspec.existsSync()) throw PubspecNotFound();

    return [await cmd(cwd)];
  }

  final processes = _Cmd.runWhere<T>(
    run: (entity) => cmd(entity.parent.path),
    where: (entity) => !ignore.excludes(entity) && _isPubspec(entity),
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
  required void Function(String) stdout,
  required void Function(String) stderr,
  String cwd = '.',
  bool collectCoverage = false,
  List<String>? arguments,
  FlutterTestRunner testRunner = flutterTest,
}) {
  const clearLine = '\u001B[2K\r';

  final completer = Completer<int>();
  final suites = <int, TestSuite>{};
  final groups = <int, TestGroup>{};
  final tests = <int, Test>{};
  final failedTestErrorMessages = <String, List<String>>{};
  final sigintWatch = ProcessSignalOverrides.current?.sigintWatch ??
      ProcessSignal.sigint.watch();

  var successCount = 0;
  var skipCount = 0;

  String computeStats() {
    final passingTests = successCount.formatSuccess();
    final failingTests =
        failedTestErrorMessages.values.expand((e) => e).length.formatFailure();
    final skippedTests = skipCount.formatSkipped();
    final result = [passingTests, failingTests, skippedTests]
      ..removeWhere((element) => element.isEmpty);
    return result.join(' ');
  }

  final timerSubscription = Stream.periodic(
    const Duration(seconds: 1),
    (computationCount) => computationCount,
  ).listen(
    (tick) {
      if (completer.isCompleted) return;
      final timeElapsed = Duration(seconds: tick).formatted();
      stdout('$clearLine$timeElapsed ...');
    },
  );

  late final StreamSubscription<TestEvent> subscription;
  late final StreamSubscription<ProcessSignal> sigintWatchSubscription;

  sigintWatchSubscription = sigintWatch.listen((_) async {
    await _cleanupOptimizerFile(cwd);
    await subscription.cancel();
    await sigintWatchSubscription.cancel();
    return completer.complete(ExitCode.success.code);
  });

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

        final test = tests[event.testID]!;
        final suite = suites[test.suiteID]!;
        final prefix = event.isFailure ? '[FAILED]' : '[ERROR]';

        final optimizationApplied = _isOptimizationApplied(suite);

        var testPath = suite.path!;
        var testName = test.name;

        // When there is a test error before any group is computed, it means
        // that there is an error when compiling the test optimizer file.
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

        stdout('$clearLine${darkGray.wrap(timeElapsed)} $stats: $summary\n');

        if (event.success != true) {
          assert(
            failedTestErrorMessages.isNotEmpty,
            'Invalid state: test event report as failed but no failed tests '
            'were gathered',
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

Future<void> _cleanupOptimizerFile(String cwd) async => File(
      p.join(cwd, 'test', _testOptimizerFileName),
    ).delete().ignore();

final int _lineLength = () {
  try {
    return stdout.terminalColumns;
  } on StdoutException {
    return 80;
  }
}();

// The extension is intended to be unnamed, but it's not possible due to
// an issue with Dart SDK 2.18.0.
//
// Once the min Dart SDK is bumped, this extension can be unnamed again.
extension _TestEvent on TestEvent {
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

  String toSingleLine() {
    return replaceAll('\n', '').replaceAll(RegExp(r'\s\s+'), ' ');
  }
}
