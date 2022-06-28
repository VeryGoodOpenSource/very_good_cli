// ignore_for_file: no_adjacent_strings_in_list

import 'dart:async';

import 'package:mason/mason.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;
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
          () => Flutter.test(
            cwd: Directory.systemTemp.path,
            stdout: stdoutLogs.add,
            stderr: stderrLogs.add,
          ),
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

      test('runs tests when there is a test directory (passing)', () async {
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

      test('runs tests when there is a test directory (failing)', () async {
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

      test(
          'runs tests when there is a test directory '
          '(skip + exception + message)', () async {
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
            '\x1B[2K\rCounterCubit initial state is 0 /my_app/test/counter/cubit/counter_cubit_test.dart (SKIPPED)\n',
            '\x1B[2K\r00:02 ~1: CounterCubit initial state is 0',
            '''\x1B[2K\r00:02 +1 ~1: CounterCubit emits [1] when increment is called''',
            '''\x1B[2K\r00:02 +2 ~1: CounterCubit emits [-1] when decrement is called''',
            '\x1B[2K\r00:02 +2 -1 ~1: App renders CounterPage',
            '\x1B[2K\rhello\n',
            '\x1B[2K\r00:03 +3 -1 ~1: CounterPage renders CounterView',
            '\x1B[2K\r00:03 +4 -1 ~1: CounterView renders current count',
            '''\x1B[2K\r00:03 +5 -1 ~1: CounterView calls increment when increment button is tapped''',
            '''\x1B[2K\r00:03 +6 -1 ~1: CounterView calls decrement when decrement button is tapped''',
            '\x1B[2K\r00:03 +6 -1 ~1: Some tests failed.\n'
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
        File(p.join(directory.path, 'pubspec.yaml')).createSync();
        Directory(p.join(directory.path, 'test')).createSync();

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
                File(p.join(directory.path, 'coverage', 'lcov.info'))
                    .createSync(recursive: true);
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
        expect(testRunnerArgs, equals(['--coverage']));
        directory.delete(recursive: true).ignore();
      });

      test(
          'runs tests w/optimizations when there is a test directory (passing)',
          () async {
        final directory = Directory.systemTemp.createTempSync();
        File(p.join(directory.path, 'pubspec.yaml')).createSync();
        Directory(p.join(directory.path, 'test')).createSync();
        await expectLater(
          Flutter.test(
            cwd: directory.path,
            optimizePerformance: true,
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
        verify(
          () => hooks.preGen(
            vars: <String, String>{'package-root': directory.path},
            onVarsChanged: any(named: 'onVarsChanged'),
            workingDirectory: directory.path,
          ),
        ).called(1);
        verify(
          () => generator.generate(
            any(),
            vars: <String, String>{'package-root': directory.path},
            fileConflictResolution: FileConflictResolution.overwrite,
          ),
        ).called(1);
        directory.delete(recursive: true).ignore();
      });
    });
  });
}
