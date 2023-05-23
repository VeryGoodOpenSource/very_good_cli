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

dev_dependencies:
  test: any''';

const _unreachableGitUrlPubspec = '''
name: example

dev_dependencies:
  very_good_analysis:
    git:
      url: https://github.com/verygoodopensource/_very_good_analysis
''';

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

class _MockMasonGenerator extends Mock implements MasonGenerator {}

class _MockGeneratorHooks extends Mock implements GeneratorHooks {}

class _MockLogger extends Mock implements Logger {}

class _MockProgress extends Mock implements Progress {}

class _FakeGeneratorTarget extends Fake implements GeneratorTarget {}

void main() {
  final successProcessResult = ProcessResult(
    42,
    ExitCode.success.code,
    '',
    '',
  );
  final softwareErrorProcessResult = ProcessResult(
    42,
    ExitCode.software.code,
    '',
    'Some error',
  );

  group('Flutter', () {
    late _TestProcess process;
    late Logger logger;
    late Progress progress;

    setUpAll(() {
      registerFallbackValue(_FakeGeneratorTarget());
      registerFallbackValue(FileConflictResolution.prompt);
    });

    setUp(() {
      logger = _MockLogger();
      progress = _MockProgress();
      when(() => logger.progress(any())).thenReturn(progress);

      process = _MockProcess();
      when(
        () => process.run(
          any(),
          any(),
          runInShell: any(named: 'runInShell'),
          workingDirectory: any(named: 'workingDirectory'),
        ),
      ).thenAnswer((_) async => successProcessResult);
    });

    group('.packagesGet', () {
      test('throws when there is no pubspec.yaml', () {
        ProcessOverrides.runZoned(
          () => expectLater(
            Flutter.packagesGet(
              cwd: Directory.systemTemp.path,
              logger: logger,
            ),
            throwsA(isA<PubspecNotFound>()),
          ),
          runProcess: process.run,
        );
      });

      test('throws when process fails', () {
        when(
          () => process.run(
            'flutter',
            any(),
            runInShell: any(named: 'runInShell'),
            workingDirectory: any(named: 'workingDirectory'),
          ),
        ).thenAnswer((_) async => softwareErrorProcessResult);

        ProcessOverrides.runZoned(
          () => expectLater(
            Flutter.packagesGet(
              cwd: Directory.systemTemp.path,
              logger: logger,
            ),
            throwsException,
          ),
          runProcess: process.run,
        );
      });

      test('throws when there is an unreachable git url', () {
        final tempDirectory = Directory.systemTemp.createTempSync();
        addTearDown(() => tempDirectory.deleteSync(recursive: true));

        File(p.join(tempDirectory.path, 'pubspec.yaml'))
            .writeAsStringSync(_unreachableGitUrlPubspec);

        when(
          () => process.run(
            'git',
            any(that: contains('ls-remote')),
            runInShell: any(named: 'runInShell'),
            workingDirectory: any(named: 'workingDirectory'),
          ),
        ).thenAnswer((_) async => softwareErrorProcessResult);

        ProcessOverrides.runZoned(
          () => expectLater(
            () => Flutter.packagesGet(cwd: tempDirectory.path, logger: logger),
            throwsA(isA<UnreachableGitDependency>()),
          ),
          runProcess: process.run,
        );
      });

      test('completes when the process succeeds', () {
        ProcessOverrides.runZoned(
          () => expectLater(Flutter.packagesGet(logger: logger), completes),
          runProcess: process.run,
        );
      });

      test('throws when there is no pubspec.yaml (recursive)', () {
        final tempDirectory = Directory.systemTemp.createTempSync();
        addTearDown(() => tempDirectory.deleteSync(recursive: true));

        ProcessOverrides.runZoned(
          () => expectLater(
            Flutter.packagesGet(
              cwd: tempDirectory.path,
              recursive: true,
              logger: logger,
            ),
            throwsA(isA<PubspecNotFound>()),
          ),
          runProcess: process.run,
        );
      });

      test(
        'completes when there is a pubspec.yaml and '
        'directory is ignored (recursive)',
        () {
          final tempDirectory = Directory.systemTemp.createTempSync();
          addTearDown(() => tempDirectory.deleteSync(recursive: true));

          final nestedDirectory = Directory(p.join(tempDirectory.path, 'test'))
            ..createSync();
          final ignoredDirectory = Directory(
            p.join(tempDirectory.path, 'test_plugin'),
          )..createSync();

          File(p.join(nestedDirectory.path, 'pubspec.yaml'))
              .writeAsStringSync(_pubspec);
          File(p.join(ignoredDirectory.path, 'pubspec.yaml'))
              .writeAsStringSync(_pubspec);

          ProcessOverrides.runZoned(
            () => expectLater(
              Flutter.packagesGet(
                cwd: tempDirectory.path,
                recursive: true,
                ignore: {
                  'test_plugin',
                  '/**/test_plugin_two/**',
                },
                logger: logger,
              ),
              completes,
            ),
            runProcess: process.run,
          ).whenComplete(() {
            verify(() {
              logger.progress(
                any(
                  that: contains(
                    'Running "flutter packages get" in '
                    '${nestedDirectory.path}',
                  ),
                ),
              );
            }).called(1);

            verifyNever(() {
              logger.progress(
                any(
                  that: contains(
                    'Running "flutter packages get" in '
                    '${ignoredDirectory.path}',
                  ),
                ),
              );
            });
          });
        },
      );
    });

    group('.pubGet', () {
      test('throws when there is no pubspec.yaml', () {
        ProcessOverrides.runZoned(
          () => expectLater(
            Flutter.pubGet(cwd: Directory.systemTemp.path, logger: logger),
            throwsA(isA<PubspecNotFound>()),
          ),
          runProcess: process.run,
        );
      });

      test('throws when process fails', () {
        when(
          () => process.run(
            'flutter',
            any(),
            runInShell: any(named: 'runInShell'),
            workingDirectory: any(named: 'workingDirectory'),
          ),
        ).thenAnswer((_) async => softwareErrorProcessResult);
        ProcessOverrides.runZoned(
          () => expectLater(
            Flutter.pubGet(cwd: Directory.systemTemp.path, logger: logger),
            throwsException,
          ),
          runProcess: process.run,
        );
      });

      test('completes when the process succeeds', () {
        ProcessOverrides.runZoned(
          () => expectLater(Flutter.pubGet(logger: logger), completes),
          runProcess: process.run,
        );
      });

      test('completes when the process succeeds (recursive)', () {
        ProcessOverrides.runZoned(
          () => expectLater(
            Flutter.pubGet(recursive: true, logger: logger),
            completes,
          ),
          runProcess: process.run,
        );
      });

      test('throws when process fails', () {
        when(
          () => process.run(
            any(),
            any(),
            runInShell: any(named: 'runInShell'),
            workingDirectory: any(named: 'workingDirectory'),
          ),
        ).thenAnswer((_) async => softwareErrorProcessResult);

        ProcessOverrides.runZoned(
          () => expectLater(Flutter.pubGet(logger: logger), throwsException),
          runProcess: process.run,
        );
      });

      test('throws when process fails (recursive)', () {
        when(
          () => process.run(
            any(),
            any(),
            runInShell: any(named: 'runInShell'),
            workingDirectory: any(named: 'workingDirectory'),
          ),
        ).thenAnswer((_) async => softwareErrorProcessResult);

        ProcessOverrides.runZoned(
          () => expectLater(
            Flutter.pubGet(recursive: true, logger: logger),
            throwsException,
          ),
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
          () => Flutter.test(cwd: Directory.systemTemp.path, logger: logger),
          throwsA(isA<PubspecNotFound>()),
        );
      });

      test('completes when there is no test directory', () async {
        final tempDirectory = Directory.systemTemp.createTempSync();
        addTearDown(() => tempDirectory.deleteSync(recursive: true));

        File(p.join(tempDirectory.path, 'pubspec.yaml')).createSync();
        await expectLater(
          Flutter.test(
            cwd: tempDirectory.path,
            stdout: stdoutLogs.add,
            stderr: stderrLogs.add,
            logger: logger,
          ),
          completion(equals([ExitCode.success.code])),
        );
        expect(
          stdoutLogs,
          equals([
            'Running "flutter test" in ${p.dirname(tempDirectory.path)}...\n',
            'No test folder found in ${tempDirectory.absolute.path}\n',
          ]),
        );
      });

      test('runs tests and shows timer until tests start', () async {
        final tempDirectory = Directory.systemTemp.createTempSync();
        addTearDown(() => tempDirectory.deleteSync(recursive: true));

        final controller = StreamController<TestEvent>();
        File(p.join(tempDirectory.path, 'pubspec.yaml')).createSync();
        Directory(p.join(tempDirectory.path, 'test')).createSync();

        unawaited(
          Flutter.test(
            cwd: tempDirectory.path,
            stdout: stdoutLogs.add,
            stderr: stderrLogs.add,
            testRunner: testRunner(controller.stream),
            logger: logger,
          ),
        );

        await Future<void>.delayed(const Duration(seconds: 1));

        controller
          ..add(const DoneTestEvent(success: true, time: 0))
          ..add(
            const ExitTestEvent(exitCode: 0, time: 0),
          );

        await Future<void>.delayed(Duration.zero);

        expect(
          stdoutLogs,
          equals([
            'Running "flutter test" in ${p.dirname(tempDirectory.path)}...\n',
            '\x1B[2K\r00:00 ...',
            contains('All tests passed!'),
          ]),
        );
      });

      test('runs tests (passing)', () async {
        final tempDirectory = Directory.systemTemp.createTempSync();
        addTearDown(() => tempDirectory.deleteSync(recursive: true));

        File(p.join(tempDirectory.path, 'pubspec.yaml')).createSync();
        Directory(p.join(tempDirectory.path, 'test')).createSync();
        await expectLater(
          Flutter.test(
            cwd: tempDirectory.path,
            stdout: stdoutLogs.add,
            stderr: stderrLogs.add,
            testRunner: testRunner(
              Stream.fromIterable([
                ...passingJsonOutput.map(TestEvent.fromJson),
                const ExitTestEvent(exitCode: 0, time: 0),
              ]),
            ),
            logger: logger,
          ),
          completion(equals([ExitCode.success.code])),
        );
        expect(
          stdoutLogs,
          equals([
            'Running "flutter test" in ${p.dirname(tempDirectory.path)}...\n',
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
      });

      test('runs tests (passing) with forced ansi output', () async {
        final tempDirectory = Directory.systemTemp.createTempSync();
        addTearDown(() => tempDirectory.deleteSync(recursive: true));

        File(p.join(tempDirectory.path, 'pubspec.yaml')).createSync();
        Directory(p.join(tempDirectory.path, 'test')).createSync();

        await expectLater(
          Flutter.test(
            cwd: tempDirectory.path,
            stdout: stdoutLogs.add,
            stderr: stderrLogs.add,
            testRunner: testRunner(
              Stream.fromIterable([
                ...passingJsonOutput.map(TestEvent.fromJson),
                const ExitTestEvent(exitCode: 0, time: 0),
              ]),
            ),
            logger: logger,
            forceAnsi: true,
          ),
          completion(equals([ExitCode.success.code])),
        );

        expect(
          stdoutLogs,
          equals([
            'Running "flutter test" in ${p.dirname(tempDirectory.path)}...\n',
            '''\x1B[2K\r\x1B[90m00:02\x1B[0m \x1B[92m+1\x1B[0m: CounterCubit initial state is 0''',
            '''\x1B[2K\r\x1B[90m00:02\x1B[0m \x1B[92m+2\x1B[0m: CounterCubit emits [1] when increment is called''',
            '''\x1B[2K\r\x1B[90m00:02\x1B[0m \x1B[92m+3\x1B[0m: CounterCubit emits [-1] when decrement is called''',
            '''\x1B[2K\r\x1B[90m00:03\x1B[0m \x1B[92m+4\x1B[0m: App renders CounterPage''',
            '''\x1B[2K\r\x1B[90m00:03\x1B[0m \x1B[92m+5\x1B[0m: CounterPage renders CounterView''',
            '''\x1B[2K\r\x1B[90m00:03\x1B[0m \x1B[92m+6\x1B[0m: CounterView renders current count''',
            '''\x1B[2K\r\x1B[90m00:03\x1B[0m \x1B[92m+7\x1B[0m: ...rView calls increment when increment button is tapped''',
            '''\x1B[2K\r\x1B[90m00:03\x1B[0m \x1B[92m+8\x1B[0m: ...rView calls decrement when decrement button is tapped''',
            '''\x1B[2K\r\x1B[90m\x1B[90m00:04\x1B[0m\x1B[0m \x1B[92m+8\x1B[0m: \x1B[92mAll tests passed!\x1B[0m\n'''
          ]),
        );
        expect(stderrLogs, isEmpty);
      });

      test('runs tests (failing)', () async {
        final tempDirectory = Directory.systemTemp.createTempSync();
        addTearDown(() => tempDirectory.deleteSync(recursive: true));

        File(p.join(tempDirectory.path, 'pubspec.yaml')).createSync();
        Directory(p.join(tempDirectory.path, 'test')).createSync();
        await expectLater(
          Flutter.test(
            cwd: tempDirectory.path,
            stdout: stdoutLogs.add,
            stderr: stderrLogs.add,
            testRunner: testRunner(
              Stream.fromIterable([
                ...failingJsonOutput(tempDirectory.path)
                    .map(TestEvent.fromJson),
                const ExitTestEvent(exitCode: 1, time: 0),
              ]),
            ),
            logger: logger,
          ),
          completion(equals([ExitCode.unavailable.code])),
        );
        expect(
          stdoutLogs,
          equals([
            'Running "flutter test" in ${p.dirname(tempDirectory.path)}...\n',
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
              '\x1B[2K\rCounterCubit initial state is 0 ${tempDirectory.path}/test/counter/cubit/counter_cubit_test.dart (FAILED)',
              '\x1B[2K\rFailing Tests:\n'
                  '\x1B[2K\r - test/counter/cubit/counter_cubit_test.dart \n'
                  '\x1B[2K\r \t- [FAILED] CounterCubit initial state is 0\n',
            ],
          ),
        );
      });

      test('runs tests (noisy)', () async {
        final tempDirectory = Directory.systemTemp.createTempSync();
        addTearDown(() => tempDirectory.deleteSync(recursive: true));

        File(p.join(tempDirectory.path, 'pubspec.yaml')).createSync();
        Directory(p.join(tempDirectory.path, 'test')).createSync();
        await expectLater(
          Flutter.test(
            cwd: tempDirectory.path,
            stdout: stdoutLogs.add,
            stderr: stderrLogs.add,
            testRunner: testRunner(
              Stream.fromIterable([
                ...skipExceptionMessageJsonOutput(tempDirectory.path)
                    .map(TestEvent.fromJson),
                const ExitTestEvent(exitCode: 0, time: 0),
              ]),
            ),
            logger: logger,
          ),
          completion(equals([ExitCode.success.code])),
        );
        expect(
          stdoutLogs,
          equals([
            'Running "flutter test" in ${p.dirname(tempDirectory.path)}...\n',
            '\x1B[2K\rSkip: currently failing (see issue 1234)\n',
            '\x1B[2K\r(suite) ${tempDirectory.path}/test/counter/view/other_test.dart (SKIPPED)\n',
            '\x1B[2K\r00:00 ~1: (suite)',
            '\x1B[2K\rCounterCubit initial state is 0 ${tempDirectory.path}/test/counter/cubit/counter_cubit_test.dart (SKIPPED)\n',
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
            '''\x1B[2K\r00:05 +8 -1 ~2: ...tiline test name that should be well processed by very_good test''',
            '\x1B[2K\r00:05 +8 -1 ~2: Some tests failed.\n'
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
                '#0      main.<anonymous closure>.<anonymous closure> (file://${tempDirectory.path}/test/app/view/app_test.dart:15:7)\n'
                '#1      main.<anonymous closure>.<anonymous closure> (file://${tempDirectory.path}/test/app/view/app_test.dart:14:40)\n'
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
            '\x1B[2K\rApp renders CounterPage ${tempDirectory.path}/test/app/view/app_test.dart (FAILED)',
            '\x1B[2K\rFailing Tests:\n'
                '\x1B[2K\r - test/app/view/app_test.dart \n'
                '\x1B[2K\r \t- [ERROR] App renders CounterPage\n',
          ]),
        );
      });

      test('runs tests (error)', () async {
        const exception = 'oops';

        final tempDirectory = Directory.systemTemp.createTempSync();
        addTearDown(() => tempDirectory.deleteSync(recursive: true));

        final controller = StreamController<TestEvent>();
        File(p.join(tempDirectory.path, 'pubspec.yaml')).createSync();
        Directory(p.join(tempDirectory.path, 'test')).createSync();
        controller
          ..addError(exception)
          ..add(const ExitTestEvent(exitCode: 1, time: 0));
        await expectLater(
          Flutter.test(
            cwd: tempDirectory.path,
            stdout: stdoutLogs.add,
            stderr: stderrLogs.add,
            testRunner: testRunner(controller.stream),
            logger: logger,
          ),
          completion(equals([ExitCode.unavailable.code])),
        );
        expect(stderrLogs, equals(['\x1B[2K\r$exception', '\x1B[2K\r']));
      });

      test('runs tests (error w/stackTrace)', () async {
        final tempDirectory = Directory.systemTemp.createTempSync();
        addTearDown(() => tempDirectory.deleteSync(recursive: true));

        File(p.join(tempDirectory.path, 'pubspec.yaml')).createSync();
        Directory(p.join(tempDirectory.path, 'test')).createSync();
        await expectLater(
          Flutter.test(
            cwd: tempDirectory.path,
            stdout: stdoutLogs.add,
            stderr: stderrLogs.add,
            testRunner: testRunner(
              Stream.fromIterable([
                SuiteTestEvent(
                  suite: TestSuite(
                    id: 4,
                    platform: 'vm',
                    path: '${tempDirectory.path}/test/app/view/app_test.dart',
                  ),
                  time: 0,
                ),
                GroupTestEvent(
                  group: TestGroup(
                    id: 10,
                    suiteID: 4,
                    name: 'CounterCubit',
                    metadata: TestMetadata(
                      skip: false,
                    ),
                    testCount: 1,
                  ),
                  time: 0,
                ),
                TestStartEvent(
                  test: Test(
                    id: 0,
                    name: 'CounterCubit emits [1] when increment is called',
                    suiteID: 4,
                    groupIDs: [10],
                    metadata: TestMetadata(skip: false),
                  ),
                  time: 0,
                ),
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
            logger: logger,
          ),
          completion(equals([ExitCode.unavailable.code])),
        );
        expect(
          stderrLogs,
          equals([
            '\x1B[2K\rerror',
            '\x1B[2K\rtest/example_test.dart 4  main\n',
            '\x1B[2K\rFailing Tests:\n'
                '\x1B[2K\r - test/app/view/app_test.dart \n'
                '''\x1B[2K\r \t- [FAILED] CounterCubit emits [1] when increment is called\n'''
          ]),
        );
      });

      test('runs tests (compilation error)', () async {
        final tempDirectory = Directory.systemTemp.createTempSync();
        addTearDown(() => tempDirectory.deleteSync(recursive: true));
        Directory(p.join(tempDirectory.path, 'test')).createSync();
        File(p.join(tempDirectory.path, 'pubspec.yaml')).createSync();

        final testEventStream = Stream.fromIterable([
          ...compilationErrorJsonOutput(tempDirectory.path)
              .map(TestEvent.fromJson),
          const ExitTestEvent(exitCode: 1, time: 0),
        ]);

        await expectLater(
          Flutter.test(
            cwd: tempDirectory.path,
            stdout: stdoutLogs.add,
            stderr: stderrLogs.add,
            testRunner: testRunner(testEventStream),
            logger: logger,
          ),
          completion(equals([ExitCode.unavailable.code])),
        );

        expect(
          stdoutLogs,
          containsAllInOrder([
            '\x1B[2K\r00:00 -1: loading test/.test_optimizer.dart',
            '\x1B[2K\r00:00 -1: Some tests failed.\n'
          ]),
        );
        expect(
          stderrLogs,
          containsAll([
            '\x1B[2K\rFailed to load "test/.test_optimizer.dart":\n'
                "test/src/my_package_test.dart:8:18: Error: No named parameter with the name 'thing'.\n"
                '    expect(Thing(thing: true), isNull);\n'
                '                 ^^^^^\n'
                "lib/compilation_error.dart:2:9: Context: Found this candidate, but the arguments don't match.\n"
                '  const Thing();\n'
                '        ^^^^^',
          ]),
        );
      });

      test('runs tests w/out logs', () async {
        final tempDirectory = Directory.systemTemp.createTempSync();
        addTearDown(() => tempDirectory.deleteSync(recursive: true));

        File(p.join(tempDirectory.path, 'pubspec.yaml')).createSync();
        Directory(p.join(tempDirectory.path, 'test')).createSync();
        await expectLater(
          Flutter.test(
            cwd: tempDirectory.path,
            testRunner: testRunner(
              Stream.fromIterable(
                [
                  const DoneTestEvent(success: true, time: 0),
                  const ExitTestEvent(exitCode: 0, time: 0),
                ],
              ),
            ),
            logger: logger,
          ),
          completion(equals([ExitCode.success.code])),
        );
      });

      test('runs tests w/args', () async {
        const arguments = ['-x', 'e2e', '-j', '1'];

        final tempDirectory = Directory.systemTemp.createTempSync();
        addTearDown(() => tempDirectory.deleteSync(recursive: true));

        File(p.join(tempDirectory.path, 'pubspec.yaml')).createSync();
        Directory(p.join(tempDirectory.path, 'test')).createSync();
        await expectLater(
          Flutter.test(
            cwd: tempDirectory.path,
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
            logger: logger,
          ),
          completion(equals([ExitCode.success.code])),
        );
        expect(
          stdoutLogs,
          equals([
            'Running "flutter test" in ${p.dirname(tempDirectory.path)}...\n',
            contains('All tests passed!'),
          ]),
        );
        expect(testRunnerArgs, equals(arguments));
      });

      test('runs tests w/randomSeed', () async {
        const seed = 'seed';

        final tempDirectory = Directory.systemTemp.createTempSync();
        addTearDown(() => tempDirectory.deleteSync(recursive: true));

        File(p.join(tempDirectory.path, 'pubspec.yaml')).createSync();
        Directory(p.join(tempDirectory.path, 'test')).createSync();
        await expectLater(
          Flutter.test(
            cwd: tempDirectory.path,
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
            logger: logger,
          ),
          completion(equals([ExitCode.success.code])),
        );
        expect(
          stdoutLogs,
          equals([
            'Running "flutter test" in ${p.dirname(tempDirectory.path)}...\n',
            'Shuffling test order with --test-randomize-ordering-seed=$seed\n',
            contains('All tests passed!'),
          ]),
        );
        expect(
          testRunnerArgs,
          equals(['--test-randomize-ordering-seed', seed]),
        );
      });

      test('runs tests w/coverage', () async {
        final tempDirectory = Directory.systemTemp.createTempSync();
        addTearDown(() => tempDirectory.deleteSync(recursive: true));

        final lcovFile =
            File(p.join(tempDirectory.path, 'coverage', 'lcov.info'));
        File(p.join(tempDirectory.path, 'pubspec.yaml')).createSync();
        Directory(p.join(tempDirectory.path, 'test')).createSync();
        lcovFile.createSync(recursive: true);

        await expectLater(
          Flutter.test(
            cwd: tempDirectory.path,
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
            logger: logger,
          ),
          completion(equals([ExitCode.success.code])),
        );
        expect(
          stdoutLogs,
          equals([
            'Running "flutter test" in ${p.dirname(tempDirectory.path)}...\n',
            contains('All tests passed!'),
          ]),
        );
        expect(testRunnerArgs, equals(['--coverage']));
      });

      test('runs tests w/coverage + min-coverage 100 (pass)', () async {
        final tempDirectory = Directory.systemTemp.createTempSync();
        addTearDown(() => tempDirectory.deleteSync(recursive: true));

        File(p.join(tempDirectory.path, 'pubspec.yaml')).createSync();
        Directory(p.join(tempDirectory.path, 'test')).createSync();

        await expectLater(
          Flutter.test(
            cwd: tempDirectory.path,
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
                File(p.join(tempDirectory.path, 'coverage', 'lcov.info'))
                  ..createSync(recursive: true)
                  ..writeAsStringSync(lcov100);
              },
            ),
            logger: logger,
          ),
          completion(equals([ExitCode.success.code])),
        );
        expect(
          stdoutLogs,
          equals([
            'Running "flutter test" in ${p.dirname(tempDirectory.path)}...\n',
            contains('All tests passed!'),
          ]),
        );
        expect(testRunnerArgs, equals(['--coverage']));
      });

      test('runs tests w/coverage + min-coverage 100 (fail)', () async {
        final tempDirectory = Directory.systemTemp.createTempSync();
        addTearDown(() => tempDirectory.deleteSync(recursive: true));

        File(p.join(tempDirectory.path, 'pubspec.yaml')).createSync();
        Directory(p.join(tempDirectory.path, 'test')).createSync();

        await expectLater(
          () => Flutter.test(
            cwd: tempDirectory.path,
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
                File(p.join(tempDirectory.path, 'coverage', 'lcov.info'))
                  ..createSync(recursive: true)
                  ..writeAsStringSync(lcov95);
              },
            ),
            logger: logger,
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
            'Running "flutter test" in ${p.dirname(tempDirectory.path)}...\n',
            contains('All tests passed!'),
          ]),
        );
        expect(stderrLogs, isEmpty);
        expect(testRunnerArgs, equals(['--coverage']));
      });

      test('runs tests w/coverage + min-coverage 100 + exclude coverage (pass)',
          () async {
        final tempDirectory = Directory.systemTemp.createTempSync();
        addTearDown(() => tempDirectory.deleteSync(recursive: true));

        File(p.join(tempDirectory.path, 'pubspec.yaml')).createSync();
        Directory(p.join(tempDirectory.path, 'test')).createSync();

        await expectLater(
          Flutter.test(
            cwd: tempDirectory.path,
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
                File(p.join(tempDirectory.path, 'coverage', 'lcov.info'))
                  ..createSync(recursive: true)
                  ..writeAsStringSync(lcov95);
              },
            ),
            logger: logger,
          ),
          completion(equals([ExitCode.success.code])),
        );
        expect(
          stdoutLogs,
          equals([
            'Running "flutter test" in ${p.dirname(tempDirectory.path)}...\n',
            contains('All tests passed!'),
          ]),
        );
        expect(stderrLogs, isEmpty);
        expect(testRunnerArgs, equals(['--coverage']));
      });

      test(
        'runs tests w/coverage + min-coverage 100 + recursive (pass)',
        () async {
          final tempDirectory = Directory.systemTemp.createTempSync();
          addTearDown(() => tempDirectory.deleteSync(recursive: true));

          File(p.join(tempDirectory.path, 'pubspec.yaml')).createSync();
          Directory(p.join(tempDirectory.path, 'test')).createSync();

          final tempNestedDirectory =
              Directory(p.join(tempDirectory.path, 'test'))..createSync();
          File(p.join(tempNestedDirectory.path, 'pubspec.yaml')).createSync();
          Directory(p.join(tempNestedDirectory.path, 'test')).createSync();

          await expectLater(
            Flutter.test(
              cwd: tempDirectory.path,
              collectCoverage: true,
              minCoverage: 100,
              recursive: true,
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
                  File(p.join(tempDirectory.path, 'coverage', 'lcov.info'))
                    ..createSync(recursive: true)
                    ..writeAsStringSync(lcov100);
                  File(
                    p.join(tempNestedDirectory.path, 'coverage', 'lcov.info'),
                  )
                    ..createSync(recursive: true)
                    ..writeAsStringSync(lcov100);
                },
              ),
              logger: logger,
            ),
            completion(equals([ExitCode.success.code, ExitCode.success.code])),
          );

          expect(
            stdoutLogs,
            unorderedEquals([
              'Running "flutter test" in '
                  '${p.dirname(tempNestedDirectory.path)}...\n',
              contains('All tests passed!'),
              'Running "flutter test" in ${p.dirname(tempDirectory.path)}...\n',
              contains('All tests passed!'),
            ]),
          );
          expect(testRunnerArgs, equals(['--coverage', '--coverage']));
        },
      );

      test(
        'runs tests w/coverage + min-coverage 100 + recursive (fail)',
        () async {
          final tempDirectory = Directory.systemTemp.createTempSync();
          addTearDown(() => tempDirectory.deleteSync(recursive: true));

          File(p.join(tempDirectory.path, 'pubspec.yaml')).createSync();
          Directory(p.join(tempDirectory.path, 'test')).createSync();

          final tempNestedDirectory =
              Directory(p.join(tempDirectory.path, 'test'))..createSync();
          File(p.join(tempNestedDirectory.path, 'pubspec.yaml')).createSync();
          Directory(p.join(tempNestedDirectory.path, 'test')).createSync();

          await expectLater(
            Flutter.test(
              cwd: tempDirectory.path,
              collectCoverage: true,
              minCoverage: 100,
              recursive: true,
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
                  File(p.join(tempDirectory.path, 'coverage', 'lcov.info'))
                    ..createSync(recursive: true)
                    ..writeAsStringSync(lcov100);
                  File(
                    p.join(tempNestedDirectory.path, 'coverage', 'lcov.info'),
                  )
                    ..createSync(recursive: true)
                    ..writeAsStringSync(lcov95);
                },
              ),
              logger: logger,
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
            unorderedEquals([
              'Running "flutter test" in '
                  '${p.dirname(tempDirectory.path)}...\n',
              contains('All tests passed!'),
              'Running "flutter test" in '
                  '${p.dirname(tempNestedDirectory.path)}...\n',
              contains('All tests passed!'),
            ]),
          );
          expect(stderrLogs, isEmpty);
          expect(testRunnerArgs, equals(['--coverage', '--coverage']));
        },
      );

      test('runs tests w/optimizations (passing)', () async {
        final tempDirectory = Directory.systemTemp.createTempSync();
        addTearDown(() => tempDirectory.deleteSync(recursive: true));

        final originalVars = <String, dynamic>{
          'package-root': tempDirectory.path
        };
        final updatedVars = <String, dynamic>{
          'package-root': tempDirectory.path,
          'foo': 'bar'
        };
        File(p.join(tempDirectory.path, 'pubspec.yaml')).createSync();
        Directory(p.join(tempDirectory.path, 'test')).createSync();
        when(
          () => hooks.preGen(
            vars: any(named: 'vars'),
            onVarsChanged: any(named: 'onVarsChanged'),
            workingDirectory: any(named: 'workingDirectory'),
          ),
        ).thenAnswer((invocation) async {
          (invocation.namedArguments[#onVarsChanged] as void Function(
            Map<String, dynamic> vars,
          ))
              .call(updatedVars);
        });
        await expectLater(
          Flutter.test(
            cwd: tempDirectory.path,
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
            'Running "flutter test" in ${p.dirname(tempDirectory.path)}...\n',
            contains('All tests passed!'),
          ]),
        );
        expect(
          testRunnerArgs,
          equals([p.join('test', '.test_optimizer.dart')]),
        );
        verify(() => logger.progress('Optimizing tests')).called(1);
        verify(
          () => hooks.preGen(
            vars: originalVars,
            onVarsChanged: any(named: 'onVarsChanged'),
            workingDirectory: tempDirectory.path,
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
      });

      test('runs tests w/optimizations (failing)', () async {
        final tempDirectory = Directory.systemTemp.createTempSync();
        addTearDown(() => tempDirectory.deleteSync(recursive: true));

        File(p.join(tempDirectory.path, 'pubspec.yaml')).createSync();
        Directory(p.join(tempDirectory.path, 'test')).createSync();
        await expectLater(
          Flutter.test(
            cwd: tempDirectory.path,
            stdout: stdoutLogs.add,
            stderr: stderrLogs.add,
            testRunner: testRunner(
              Stream.fromIterable([
                SuiteTestEvent(
                  suite: TestSuite(
                    id: 4,
                    platform: 'vm',
                    path: '${tempDirectory.path}/test/.test_optimizer.dart',
                  ),
                  time: 0,
                ),
                GroupTestEvent(
                  group: TestGroup(
                    id: 10,
                    suiteID: 4,
                    name: 'app/view/app_test.dart',
                    metadata: TestMetadata(
                      skip: false,
                    ),
                    testCount: 1,
                  ),
                  time: 0,
                ),
                GroupTestEvent(
                  group: TestGroup(
                    id: 99,
                    suiteID: 4,
                    name: 'app/view/app_test.dart CounterCubit',
                    metadata: TestMetadata(
                      skip: false,
                    ),
                    testCount: 1,
                  ),
                  time: 0,
                ),
                TestStartEvent(
                  test: Test(
                    id: 0,
                    name:
                        'app/view/app_test.dart CounterCubit emits [1] when increment is called',
                    suiteID: 4,
                    groupIDs: [10, 99],
                    metadata: TestMetadata(skip: false),
                  ),
                  time: 0,
                ),
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
            logger: logger,
          ),
          completion(equals([ExitCode.unavailable.code])),
        );
        expect(
          stderrLogs,
          equals([
            '\x1B[2K\rerror',
            '\x1B[2K\rtest/example_test.dart 4  main\n',
            '\x1B[2K\rFailing Tests:\n'
                '\x1B[2K\r - test/app/view/app_test.dart \n'
                '''\x1B[2K\r \t- [FAILED] CounterCubit emits [1] when increment is called\n'''
          ]),
        );
      });
    });
  });
}
