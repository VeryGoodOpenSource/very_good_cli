// ignore_for_file: no_adjacent_strings_in_list

import 'dart:async';

import 'package:mason/mason.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;
import 'package:stack_trace/stack_trace.dart' as stack_trace;
import 'package:test/test.dart';
import 'package:universal_io/io.dart';
import 'package:very_good_cli/src/cli/cli.dart';
import 'package:very_good_test_runner/very_good_test_runner.dart';

import '../../fixtures/fixtures.dart';

const _pubspec = '''
name: example
environment:
  sdk: ">=2.13.0 <3.0.0"

dev_dependencies:
  test: any''';

const _unreachableGitUrlPubspec = '''
name: example
environment:
  sdk: ">=2.13.0 <3.0.0"

dev_dependencies:
  very_good_analysis:
    git:
      url: https://github.com/verygoodopensource/_very_good_analysis''';

class _TestProcess {
  Future<ProcessResult> run(
    String command,
    List<String> args, {
    bool runInShell = false,
    String? workingDirectory,
  }) {
    throw UnimplementedError();
  }
}

class _MockProcess extends Mock implements _TestProcess {}

class _MockProcessResult extends Mock implements ProcessResult {}

class _MockMasonGenerator extends Mock implements MasonGenerator {}

class _MockGeneratorHooks extends Mock implements GeneratorHooks {}

class _MockLogger extends Mock implements Logger {}

class _MockProgress extends Mock implements Progress {}

class _FakeGeneratorTarget extends Fake implements GeneratorTarget {}

void main() {
  group('Flutter', () {
    late ProcessResult processResult;
    late _TestProcess process;

    setUpAll(() {
      registerFallbackValue(_FakeGeneratorTarget());
      registerFallbackValue(FileConflictResolution.prompt);
    });

    setUp(() {
      processResult = _MockProcessResult();
      process = _MockProcess();
      when(() => processResult.exitCode).thenReturn(ExitCode.success.code);
      when(
        () => process.run(
          any(),
          any(),
          runInShell: any(named: 'runInShell'),
          workingDirectory: any(named: 'workingDirectory'),
        ),
      ).thenAnswer((_) async => processResult);
    });

    group('.packagesGet', () {
      test('throws when there is no pubspec.yaml', () {
        ProcessOverrides.runZoned(
          () => expectLater(
            Flutter.packagesGet(cwd: Directory.systemTemp.path),
            throwsA(isA<PubspecNotFound>()),
          ),
          runProcess: process.run,
        );
      });

      test('throws when process fails', () {
        final flutterProcessResult = _MockProcessResult();
        when(
          () => flutterProcessResult.exitCode,
        ).thenReturn(ExitCode.software.code);
        when(
          () => process.run(
            'flutter',
            any(),
            runInShell: any(named: 'runInShell'),
            workingDirectory: any(named: 'workingDirectory'),
          ),
        ).thenAnswer((_) async => flutterProcessResult);

        ProcessOverrides.runZoned(
          () => expectLater(
            Flutter.packagesGet(cwd: Directory.systemTemp.path),
            throwsException,
          ),
          runProcess: process.run,
        );
      });

      test('throws when there is an unreachable git url', () {
        final directory = Directory.systemTemp.createTempSync();
        File(p.join(directory.path, 'pubspec.yaml'))
            .writeAsStringSync(_unreachableGitUrlPubspec);

        final gitProcessResult = _MockProcessResult();
        when(
          () => gitProcessResult.exitCode,
        ).thenReturn(ExitCode.software.code);
        when(
          () => process.run(
            'git',
            any(that: contains('ls-remote')),
            runInShell: any(named: 'runInShell'),
            workingDirectory: any(named: 'workingDirectory'),
          ),
        ).thenAnswer((_) async => gitProcessResult);

        ProcessOverrides.runZoned(
          () => expectLater(
            () => Flutter.packagesGet(cwd: directory.path),
            throwsA(isA<UnreachableGitDependency>()),
          ),
          runProcess: process.run,
        );
      });

      test('completes when the process succeeds', () {
        ProcessOverrides.runZoned(
          () => expectLater(Flutter.packagesGet(), completes),
          runProcess: process.run,
        );
      });

      test('throws when there is no pubspec.yaml (recursive)', () {
        ProcessOverrides.runZoned(
          () => expectLater(
            Flutter.packagesGet(
              cwd: Directory.systemTemp.createTempSync().path,
              recursive: true,
            ),
            throwsA(isA<PubspecNotFound>()),
          ),
          runProcess: process.run,
        );
      });

      test('completes when there is a pubspec.yaml (recursive)', () {
        final directory = Directory.systemTemp.createTempSync();
        final nestedDirectory = Directory(p.join(directory.path, 'test'))
          ..createSync();
        File(p.join(nestedDirectory.path, 'pubspec.yaml'))
            .writeAsStringSync(_pubspec);

        ProcessOverrides.runZoned(
          () => expectLater(
            Flutter.packagesGet(cwd: directory.path, recursive: true),
            completes,
          ),
          runProcess: process.run,
        );
      });
    });

    group('.pubGet', () {
      test('throws when there is no pubspec.yaml', () {
        ProcessOverrides.runZoned(
          () => expectLater(
            Flutter.pubGet(cwd: Directory.systemTemp.path),
            throwsA(isA<PubspecNotFound>()),
          ),
          runProcess: process.run,
        );
      });

      test('throws when process fails', () {
        final flutterProcessResult = _MockProcessResult();
        when(
          () => flutterProcessResult.exitCode,
        ).thenReturn(ExitCode.software.code);
        when(
          () => process.run(
            'flutter',
            any(),
            runInShell: any(named: 'runInShell'),
            workingDirectory: any(named: 'workingDirectory'),
          ),
        ).thenAnswer((_) async => flutterProcessResult);
        ProcessOverrides.runZoned(
          () => expectLater(
            Flutter.pubGet(cwd: Directory.systemTemp.path),
            throwsException,
          ),
          runProcess: process.run,
        );
      });

      test('completes when the process succeeds', () {
        ProcessOverrides.runZoned(
          () => expectLater(Flutter.pubGet(), completes),
          runProcess: process.run,
        );
      });

      test('completes when the process succeeds (recursive)', () {
        ProcessOverrides.runZoned(
          () => expectLater(Flutter.pubGet(recursive: true), completes),
          runProcess: process.run,
        );
      });

      test('throws when process fails', () {
        when(() => processResult.exitCode).thenReturn(ExitCode.software.code);
        ProcessOverrides.runZoned(
          () => expectLater(Flutter.pubGet(), throwsException),
          runProcess: process.run,
        );
      });

      test('throws when process fails (recursive)', () {
        when(() => processResult.exitCode).thenReturn(ExitCode.software.code);
        ProcessOverrides.runZoned(
          () => expectLater(Flutter.pubGet(recursive: true), throwsException),
          runProcess: process.run,
        );
      });
    });

    group('.test', () {
      late Progress progress;
      late Logger logger;
      late GeneratorHooks hooks;
      late MasonGenerator generator;
      late List<String> stdoutLogs;
      late List<String> stderrLogs;
      late List<String> testRunnerArgs;

      FlutterTestRunner testRunner(
        Stream<TestEvent> stream, {
        void Function()? onStart,
      }) {
        return ({
          arguments,
          environment,
          runInShell = false,
          workingDirectory,
        }) {
          onStart?.call();
          if (arguments != null) testRunnerArgs.addAll(arguments);
          return stream;
        };
      }

      GeneratorBuilder generatorBuilder() => (_) async => generator;

      setUp(() {
        progress = _MockProgress();
        logger = _MockLogger();
        when(() => logger.progress(any())).thenReturn(progress);
        hooks = _MockGeneratorHooks();
        generator = _MockMasonGenerator();
        when(() => generator.hooks).thenReturn(hooks);
        when(
          () => hooks.preGen(
            vars: any(named: 'vars'),
            onVarsChanged: any(named: 'onVarsChanged'),
            workingDirectory: any(named: 'workingDirectory'),
          ),
        ).thenAnswer((_) async {});
        when(
          () => generator.generate(
            any(),
            vars: any(named: 'vars'),
            fileConflictResolution: any(named: 'fileConflictResolution'),
          ),
        ).thenAnswer((_) async => []);
        testRunnerArgs = [];
        stdoutLogs = [];
        stderrLogs = [];
      });

      test('throws when pubspec not found', () async {
        await expectLater(
          () => Flutter.test(cwd: Directory.systemTemp.path),
          throwsA(isA<PubspecNotFound>()),
        );
      });

      test('completes when there is no test directory', () async {
        final directory = Directory.systemTemp.createTempSync();
        File(p.join(directory.path, 'pubspec.yaml')).createSync();
        await expectLater(
          Flutter.test(
            cwd: directory.path,
            stdout: stdoutLogs.add,
            stderr: stderrLogs.add,
          ),
          completion(equals([ExitCode.success.code])),
        );
        expect(
          stdoutLogs,
          equals([
            'Running "flutter test" in ${p.dirname(directory.path)}...\n',
            'No test folder found in ${directory.absolute.path}\n',
          ]),
        );
        directory.delete(recursive: true).ignore();
      });

      test('runs tests and shows timer until tests start', () async {
        final controller = StreamController<TestEvent>();
        final directory = Directory.systemTemp.createTempSync();
        File(p.join(directory.path, 'pubspec.yaml')).createSync();
        Directory(p.join(directory.path, 'test')).createSync();

        unawaited(
          Flutter.test(
            cwd: directory.path,
            stdout: stdoutLogs.add,
            stderr: stderrLogs.add,
            testRunner: testRunner(controller.stream),
          ),
        );

        await Future<void>.delayed(const Duration(seconds: 1));

        controller
          ..add(const DoneTestEvent(success: true, time: 0))
          ..add(const ExitTestEvent(exitCode: 0, time: 0));

        await Future<void>.delayed(Duration.zero);

        expect(
          stdoutLogs,
          equals([
            'Running "flutter test" in ${p.dirname(directory.path)}...\n',
            '\x1B[2K\r00:00 ...',
            contains('All tests passed!'),
          ]),
        );
        directory.delete(recursive: true).ignore();
      });

      test('runs tests (passing)', () async {
        final directory = Directory.systemTemp.createTempSync();
        File(p.join(directory.path, 'pubspec.yaml')).createSync();
        Directory(p.join(directory.path, 'test')).createSync();
        await expectLater(
          Flutter.test(
            cwd: directory.path,
            stdout: stdoutLogs.add,
            stderr: stderrLogs.add,
            testRunner: testRunner(
              Stream.fromIterable([
                ...passingJsonOutput.map(TestEvent.fromJson),
                const ExitTestEvent(exitCode: 0, time: 0),
              ]),
            ),
          ),
          completion(equals([ExitCode.success.code])),
        );
        expect(
          stdoutLogs,
          equals([
            'Running "flutter test" in ${p.dirname(directory.path)}...\n',
            '\x1B[2K\r00:02 +1: CounterCubit initial state is 0',
            '''\x1B[2K\r00:02 +2: CounterCubit emits [1] when increment is called''',
            '''\x1B[2K\r00:02 +3: CounterCubit emits [-1] when decrement is called''',
            '\x1B[2K\r00:03 +4: App renders CounterPage',
            '\x1B[2K\r00:03 +5: CounterPage renders CounterView',
            '\x1B[2K\r00:03 +6: CounterView renders current count',
            '''\x1B[2K\r00:03 +7: CounterView calls increment when increment button is tapped''',
            '''\x1B[2K\r00:03 +8: CounterView calls decrement when decrement button is tapped''',
            '\x1B[2K\r00:04 +8: All tests passed!\n'
          ]),
        );
        expect(stderrLogs, isEmpty);
        directory.delete(recursive: true).ignore();
      });

      test('runs tests (failing)', () async {
        final directory = Directory.systemTemp.createTempSync();
        File(p.join(directory.path, 'pubspec.yaml')).createSync();
        Directory(p.join(directory.path, 'test')).createSync();
        await expectLater(
          Flutter.test(
            cwd: directory.path,
            stdout: stdoutLogs.add,
            stderr: stderrLogs.add,
            testRunner: testRunner(
              Stream.fromIterable([
                ...failingJsonOutput.map(TestEvent.fromJson),
                const ExitTestEvent(exitCode: 1, time: 0),
              ]),
            ),
          ),
          completion(equals([ExitCode.unavailable.code])),
        );
        expect(
          stdoutLogs,
          equals([
            'Running "flutter test" in ${p.dirname(directory.path)}...\n',
            '\x1B[2K\r00:11 -1: CounterCubit initial state is 0',
            '''\x1B[2K\r00:11 +1 -1: CounterCubit emits [1] when increment is called''',
            '''\x1B[2K\r00:11 +2 -1: CounterCubit emits [-1] when decrement is called''',
            '\x1B[2K\r00:11 +3 -1: App renders CounterPage',
            '\x1B[2K\r00:12 +4 -1: CounterPage renders CounterView',
            '\x1B[2K\r00:12 +5 -1: CounterView renders current count',
            '''\x1B[2K\r00:12 +6 -1: CounterView calls increment when increment button is tapped''',
            '''\x1B[2K\r00:12 +7 -1: CounterView calls decrement when decrement button is tapped''',
            '\x1B[2K\r00:12 +7 -1: Some tests failed.\n',
          ]),
        );
        expect(
          stderrLogs,
          equals(
            [
              '\x1B[2K\rExpected: <1>\n'
                  '  Actual: <0>\n',
              '''\x1B[2K\rpackage:test_api                                    expect\n'''
                  'package:flutter_test/src/widget_tester.dart 455:16  expect\n'
                  'test/counter/cubit/counter_cubit_test.dart 16:7     main.<fn>.<fn>\n',
              '\x1B[2K\rCounterCubit initial state is 0 /my_app/test/counter/cubit/counter_cubit_test.dart (FAILED)',
              '\x1B[2K\rFailing Tests:\n'
                  '\x1B[2K\r - [FAILED] test/counter/cubit/counter_cubit_test.dart:16:7\n'
            ],
          ),
        );
        directory.delete(recursive: true).ignore();
      });

      test('runs tests (noisy)', () async {
        final directory = Directory.systemTemp.createTempSync();
        File(p.join(directory.path, 'pubspec.yaml')).createSync();
        Directory(p.join(directory.path, 'test')).createSync();
        await expectLater(
          Flutter.test(
            cwd: directory.path,
            stdout: stdoutLogs.add,
            stderr: stderrLogs.add,
            testRunner: testRunner(
              Stream.fromIterable([
                ...skipExceptionMessageJsonOuput.map(TestEvent.fromJson),
                const ExitTestEvent(exitCode: 0, time: 0),
              ]),
            ),
          ),
          completion(equals([ExitCode.success.code])),
        );
        expect(
          stdoutLogs,
          equals([
            'Running "flutter test" in ${p.dirname(directory.path)}...\n',
            '\x1B[2K\rSkip: currently failing (see issue 1234)\n',
            '\x1B[2K\r(suite) /my_app/test/counter/view/other_test.dart (SKIPPED)\n',
            '\x1B[2K\r00:00 ~1: (suite)',
            '\x1B[2K\rCounterCubit initial state is 0 /my_app/test/counter/cubit/counter_cubit_test.dart (SKIPPED)\n',
            '\x1B[2K\r00:02 ~2: CounterCubit initial state is 0',
            '''\x1B[2K\r00:02 +1 ~2: CounterCubit emits [1] when increment is called''',
            '''\x1B[2K\r00:02 +2 ~2: CounterCubit emits [-1] when decrement is called''',
            '''\x1B[2K\r00:02 +3 ~2: ...a really long test name that should get truncated by very_good test''',
            '\x1B[2K\r00:03 +3 -1 ~2: App renders CounterPage',
            '\x1B[2K\rhello\n',
            '\x1B[2K\r00:04 +4 -1 ~2: CounterPage renders CounterView',
            '\x1B[2K\r00:04 +5 -1 ~2: CounterView renders current count',
            '''\x1B[2K\r00:04 +6 -1 ~2: CounterView calls increment when increment button is tapped''',
            '''\x1B[2K\r00:04 +7 -1 ~2: CounterView calls decrement when decrement button is tapped''',
            '\x1B[2K\r00:04 +7 -1 ~2: Some tests failed.\n'
          ]),
        );
        expect(
          stderrLogs,
          equals([
            '''\x1B[2K\r══╡ EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK ╞════════════════════════════════════════════════════\n'''
                'The following _Exception was thrown running a test:\n'
                'Exception: oops\n'
                '\n'
                'When the exception was thrown, this was the stack:\n'
                '#0      main.<anonymous closure>.<anonymous closure> (file:///my_app/test/app/view/app_test.dart:15:7)\n'
                '#1      main.<anonymous closure>.<anonymous closure> (file:///my_app/test/app/view/app_test.dart:14:40)\n'
                '#2      testWidgets.<anonymous closure>.<anonymous closure> (package:flutter_test/src/widget_tester.dart:170:29)\n'
                '<asynchronous suspension>\n'
                '<asynchronous suspension>\n'
                '(elided one frame from package:stack_trace)\n'
                '\n'
                'The test description was:\n'
                '  renders CounterPage\n'
                '''════════════════════════════════════════════════════════════════════════════════════════════════════''',
            '\x1B[2K\rTest failed. See exception logs above.\n'
                'The test description was: renders CounterPage',
            '\x1B[2K\rApp renders CounterPage /my_app/test/app/view/app_test.dart (FAILED)',
            '\x1B[2K\rFailing Tests:\n'
                '''\x1B[2K\r - [ERROR] ...failed. See exception logs above. The test description was: renders CounterPage\n'''
          ]),
        );
        directory.delete(recursive: true).ignore();
      });

      test('runs tests (error)', () async {
        const exception = 'oops';
        final directory = Directory.systemTemp.createTempSync();
        final controller = StreamController<TestEvent>();
        File(p.join(directory.path, 'pubspec.yaml')).createSync();
        Directory(p.join(directory.path, 'test')).createSync();
        controller
          ..addError(exception)
          ..add(const ExitTestEvent(exitCode: 1, time: 0));
        await expectLater(
          Flutter.test(
            cwd: directory.path,
            stdout: stdoutLogs.add,
            stderr: stderrLogs.add,
            testRunner: testRunner(controller.stream),
          ),
          completion(equals([ExitCode.unavailable.code])),
        );
        expect(stderrLogs, equals(['\x1B[2K\r$exception', '\x1B[2K\r']));
        directory.delete(recursive: true).ignore();
      });

      test('runs tests (error w/stackTrace)', () async {
        final directory = Directory.systemTemp.createTempSync();
        File(p.join(directory.path, 'pubspec.yaml')).createSync();
        Directory(p.join(directory.path, 'test')).createSync();
        await expectLater(
          Flutter.test(
            cwd: directory.path,
            stdout: stdoutLogs.add,
            stderr: stderrLogs.add,
            testRunner: testRunner(
              Stream.fromIterable([
                ErrorTestEvent(
                  testID: 0,
                  error: 'error',
                  stackTrace:
                      stack_trace.Trace.parse('test/example_test.dart 4 main')
                          .toString(),
                  isFailure: true,
                  time: 0,
                ),
                const DoneTestEvent(success: false, time: 0),
                const ExitTestEvent(exitCode: 1, time: 0),
              ]),
            ),
          ),
          completion(equals([ExitCode.unavailable.code])),
        );
        expect(
          stderrLogs,
          equals([
            '\x1B[2K\rerror',
            '\x1B[2K\rtest/example_test.dart 4  main\n',
            '\x1B[2K\rFailing Tests:\n'
                '\x1B[2K\r - [FAILED] test/example_test.dart:4\n'
          ]),
        );
        directory.delete(recursive: true).ignore();
      });

      test('runs tests w/out logs', () async {
        final directory = Directory.systemTemp.createTempSync();
        File(p.join(directory.path, 'pubspec.yaml')).createSync();
        Directory(p.join(directory.path, 'test')).createSync();
        await expectLater(
          Flutter.test(
            cwd: directory.path,
            testRunner: testRunner(
              Stream.fromIterable(
                [
                  const DoneTestEvent(success: true, time: 0),
                  const ExitTestEvent(exitCode: 0, time: 0),
                ],
              ),
            ),
          ),
          completion(equals([ExitCode.success.code])),
        );
        directory.delete(recursive: true).ignore();
      });

      test('runs tests w/args', () async {
        const arguments = ['-x', 'e2e', '-j', '1'];
        final directory = Directory.systemTemp.createTempSync();
        File(p.join(directory.path, 'pubspec.yaml')).createSync();
        Directory(p.join(directory.path, 'test')).createSync();
        await expectLater(
          Flutter.test(
            cwd: directory.path,
            arguments: arguments,
            stdout: stdoutLogs.add,
            stderr: stderrLogs.add,
            testRunner: testRunner(
              Stream.fromIterable(
                [
                  const DoneTestEvent(success: true, time: 0),
                  const ExitTestEvent(exitCode: 0, time: 0),
                ],
              ),
            ),
          ),
          completion(equals([ExitCode.success.code])),
        );
        expect(
          stdoutLogs,
          equals([
            'Running "flutter test" in ${p.dirname(directory.path)}...\n',
            contains('All tests passed!'),
          ]),
        );
        expect(testRunnerArgs, equals(arguments));
        directory.delete(recursive: true).ignore();
      });

      test('runs tests w/randomSeed', () async {
        const seed = 'seed';
        final directory = Directory.systemTemp.createTempSync();
        File(p.join(directory.path, 'pubspec.yaml')).createSync();
        Directory(p.join(directory.path, 'test')).createSync();
        await expectLater(
          Flutter.test(
            cwd: directory.path,
            randomSeed: seed,
            stdout: stdoutLogs.add,
            stderr: stderrLogs.add,
            testRunner: testRunner(
              Stream.fromIterable(
                [
                  const DoneTestEvent(success: true, time: 0),
                  const ExitTestEvent(exitCode: 0, time: 0),
                ],
              ),
            ),
          ),
          completion(equals([ExitCode.success.code])),
        );
        expect(
          stdoutLogs,
          equals([
            'Running "flutter test" in ${p.dirname(directory.path)}...\n',
            'Shuffling test order with --test-randomize-ordering-seed=$seed\n',
            contains('All tests passed!'),
          ]),
        );
        expect(
          testRunnerArgs,
          equals(['--test-randomize-ordering-seed', seed]),
        );
        directory.delete(recursive: true).ignore();
      });

      test('runs tests w/coverage', () async {
        final directory = Directory.systemTemp.createTempSync();
        final lcovFile = File(p.join(directory.path, 'coverage', 'lcov.info'));
        File(p.join(directory.path, 'pubspec.yaml')).createSync();
        Directory(p.join(directory.path, 'test')).createSync();
        lcovFile.createSync(recursive: true);

        await expectLater(
          Flutter.test(
            cwd: directory.path,
            collectCoverage: true,
            stdout: stdoutLogs.add,
            stderr: stderrLogs.add,
            testRunner: testRunner(
              Stream.fromIterable(
                [
                  const DoneTestEvent(success: true, time: 0),
                  const ExitTestEvent(exitCode: 0, time: 0),
                ],
              ),
              onStart: () {
                expect(lcovFile.existsSync(), isFalse);
                lcovFile.createSync(recursive: true);
              },
            ),
          ),
          completion(equals([ExitCode.success.code])),
        );
        expect(
          stdoutLogs,
          equals([
            'Running "flutter test" in ${p.dirname(directory.path)}...\n',
            contains('All tests passed!'),
          ]),
        );
        expect(testRunnerArgs, equals(['--coverage']));
        directory.delete(recursive: true).ignore();
      });

      test('runs tests w/coverage + min-coverage 100 (pass)', () async {
        final directory = Directory.systemTemp.createTempSync();
        File(p.join(directory.path, 'pubspec.yaml')).createSync();
        Directory(p.join(directory.path, 'test')).createSync();

        await expectLater(
          Flutter.test(
            cwd: directory.path,
            collectCoverage: true,
            minCoverage: 100,
            stdout: stdoutLogs.add,
            stderr: stderrLogs.add,
            testRunner: testRunner(
              Stream.fromIterable(
                [
                  const DoneTestEvent(success: true, time: 0),
                  const ExitTestEvent(exitCode: 0, time: 0),
                ],
              ),
              onStart: () {
                File(p.join(directory.path, 'coverage', 'lcov.info'))
                  ..createSync(recursive: true)
                  ..writeAsStringSync(lcov100);
              },
            ),
          ),
          completion(equals([ExitCode.success.code])),
        );
        expect(
          stdoutLogs,
          equals([
            'Running "flutter test" in ${p.dirname(directory.path)}...\n',
            contains('All tests passed!'),
          ]),
        );
        expect(testRunnerArgs, equals(['--coverage']));
        directory.delete(recursive: true).ignore();
      });

      test('runs tests w/coverage + min-coverage 100 (fail)', () async {
        final directory = Directory.systemTemp.createTempSync();
        File(p.join(directory.path, 'pubspec.yaml')).createSync();
        Directory(p.join(directory.path, 'test')).createSync();

        await expectLater(
          () => Flutter.test(
            cwd: directory.path,
            collectCoverage: true,
            minCoverage: 100,
            stdout: stdoutLogs.add,
            stderr: stderrLogs.add,
            testRunner: testRunner(
              Stream.fromIterable(
                [
                  const DoneTestEvent(success: true, time: 0),
                  const ExitTestEvent(exitCode: 0, time: 0),
                ],
              ),
              onStart: () {
                File(p.join(directory.path, 'coverage', 'lcov.info'))
                  ..createSync(recursive: true)
                  ..writeAsStringSync(lcov95);
              },
            ),
          ),
          throwsA(
            isA<MinCoverageNotMet>().having(
              (e) => e.coverage,
              'coverage',
              95.0,
            ),
          ),
        );
        expect(
          stdoutLogs,
          equals([
            'Running "flutter test" in ${p.dirname(directory.path)}...\n',
            contains('All tests passed!'),
          ]),
        );
        expect(stderrLogs, isEmpty);
        expect(testRunnerArgs, equals(['--coverage']));
        directory.delete(recursive: true).ignore();
      });

      test('runs tests w/coverage + min-coverage 100 + exclude coverage (pass)',
          () async {
        final directory = Directory.systemTemp.createTempSync();
        File(p.join(directory.path, 'pubspec.yaml')).createSync();
        Directory(p.join(directory.path, 'test')).createSync();

        await expectLater(
          Flutter.test(
            cwd: directory.path,
            collectCoverage: true,
            minCoverage: 100,
            excludeFromCoverage:
                '/bloc/packages/bloc/lib/src/bloc_observer.dart',
            stdout: stdoutLogs.add,
            stderr: stderrLogs.add,
            testRunner: testRunner(
              Stream.fromIterable(
                [
                  const DoneTestEvent(success: true, time: 0),
                  const ExitTestEvent(exitCode: 0, time: 0),
                ],
              ),
              onStart: () {
                File(p.join(directory.path, 'coverage', 'lcov.info'))
                  ..createSync(recursive: true)
                  ..writeAsStringSync(lcov95);
              },
            ),
          ),
          completion(equals([ExitCode.success.code])),
        );
        expect(
          stdoutLogs,
          equals([
            'Running "flutter test" in ${p.dirname(directory.path)}...\n',
            contains('All tests passed!'),
          ]),
        );
        expect(stderrLogs, isEmpty);
        expect(testRunnerArgs, equals(['--coverage']));
        directory.delete(recursive: true).ignore();
      });

      test('runs tests w/optimizations (passing)', () async {
        final directory = Directory.systemTemp.createTempSync();
        final originalVars = <String, dynamic>{'package-root': directory.path};
        final updatedVars = <String, dynamic>{
          'package-root': directory.path,
          'foo': 'bar'
        };
        File(p.join(directory.path, 'pubspec.yaml')).createSync();
        Directory(p.join(directory.path, 'test')).createSync();
        when(
          () => hooks.preGen(
            vars: any(named: 'vars'),
            onVarsChanged: any(named: 'onVarsChanged'),
            workingDirectory: any(named: 'workingDirectory'),
          ),
        ).thenAnswer((invocation) async {
          (invocation.namedArguments[#onVarsChanged] as Function(
            Map<String, dynamic> vars,
          ))
              .call(updatedVars);
        });
        await expectLater(
          Flutter.test(
            cwd: directory.path,
            optimizePerformance: true,
            stdout: stdoutLogs.add,
            stderr: stderrLogs.add,
            logger: logger,
            testRunner: testRunner(
              Stream.fromIterable(
                [
                  const DoneTestEvent(success: true, time: 0),
                  const ExitTestEvent(exitCode: 0, time: 0),
                ],
              ),
            ),
            buildGenerator: generatorBuilder(),
          ),
          completion(equals([ExitCode.success.code])),
        );
        expect(
          stdoutLogs,
          equals([
            'Running "flutter test" in ${p.dirname(directory.path)}...\n',
            contains('All tests passed!'),
          ]),
        );
        expect(testRunnerArgs, equals([p.join('test', '.test_runner.dart')]));
        verify(() => logger.progress('Optimizing tests')).called(1);
        verify(
          () => hooks.preGen(
            vars: originalVars,
            onVarsChanged: any(named: 'onVarsChanged'),
            workingDirectory: directory.path,
          ),
        ).called(1);
        verify(
          () => generator.generate(
            any(),
            vars: updatedVars,
            fileConflictResolution: FileConflictResolution.overwrite,
          ),
        ).called(1);
        verify(() => progress.complete()).called(1);
        directory.delete(recursive: true).ignore();
      });
    });
  });
}
