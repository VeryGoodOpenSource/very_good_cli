import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dart_mcp/server.dart';
import 'package:mason/mason.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:very_good_cli/src/cli/cli.dart';
import 'package:very_good_cli/src/command_runner.dart';
import 'package:very_good_cli/src/mcp/runner/tool_runner.dart';

class _MockVeryGoodCommandRunner extends Mock implements VeryGoodCommandRunner;

void main() {
  group(ToolRunner, () {
    late VeryGoodCommandRunner commandRunner;
    // The mason Logger the runner constructs inside the IOOverrides zone and
    // passes to the builder. Captured here so tests can drive it directly.
    late Logger injectedLogger;
    late ToolRunner runner;
    late String originalCwd;
    // A real directory used wherever a run is given a working directory (the
    // runner switches the real cwd, which must exist).
    late Directory tempDir;

    setUp(() {
      commandRunner = _MockVeryGoodCommandRunner();
      runner = ToolRunner(
        commandRunnerBuilder: ({required logger}) {
          injectedLogger = logger;
          return commandRunner;
        },
      );
      when(() => commandRunner.run(any()))
          .thenAnswer((_) async => ExitCode.success.code);

      originalCwd = Directory.current.path;
      tempDir = Directory.systemTemp.createTempSync('vgmcp_test_');
      addTearDown(() {
        // Always restore the cwd so a failure cannot leak into other tests.
        Directory.current = originalCwd;
        tempDir.deleteSync(recursive: true);
      });
    });

    Future<CallToolResult> run({
      List<String> args = const ['test'],
      String? directory,
      Map<String, Object?>? requestArguments,
      Duration? timeout,
    }) => runner.run(
      args,
      toolName: 'test',
      directory: directory,
      requestArguments: requestArguments,
      timeout: timeout,
    );

    Map<String, Object?> payloadOf(CallToolResult result) =>
        result.structuredContent!;

    test('builds a $VeryGoodCommandRunner by default', () {
      expect(ToolRunner(), isA<ToolRunner>());
      expect(
        defaultCommandRunnerBuilder(logger: Logger()),
        isA<VeryGoodCommandRunner>(),
      );
    });

    group('outcome', () {
      test('reports a success with the command that ran', () async {
        final result = await run(
          args: ['create', 'flutter_app', 'my_app'],
          requestArguments: {'subcommand': 'flutter_app', 'name': 'my_app'},
        );

        verify(() => commandRunner.run(['create', 'flutter_app', 'my_app']))
            .called(1);
        expect(result.isError, isFalse);
        expect(
          (result.content.single as TextContent).text,
          equals('"test" completed successfully.'),
        );
        expect(
          payloadOf(result),
          equals({
            'status': 'success',
            'attemptedAction': {
              'tool': 'test',
              'command': 'very_good create flutter_app my_app',
              'arguments': {'subcommand': 'flutter_app', 'name': 'my_app'},
            },
          }),
        );
      });

      test('reports a failing exit code as a failure', () async {
        when(() => commandRunner.run(any()))
            .thenAnswer((_) async => ExitCode.software.code);

        final result = await run(requestArguments: {'coverage': true});

        expect(result.isError, isTrue);
        final payload = payloadOf(result);
        expect(payload['status'], equals('failure'));
        expect(payload['failureType'], equals('business'));
        expect(payload['reason'], contains('failed with exit code 70'));
        expect(
          payload['attemptedAction'],
          equals({
            'tool': 'test',
            'command': 'very_good test',
            'arguments': {'coverage': true},
          }),
        );
        expect(payload['alternativeApproaches'], isNotEmpty);
      });

      test('reports a $UsageException as a validation failure', () async {
        when(() => commandRunner.run(any()))
            .thenThrow(UsageException('bad usage', 'usage string'));

        final result = await run();

        expect(result.isError, isTrue);
        final payload = payloadOf(result);
        expect(payload['failureType'], equals('validation'));
        expect(payload['reason'], contains('usage error: bad usage'));
        final action = payload['attemptedAction']! as Map<String, Object?>;
        expect(action['command'], equals('very_good test'));
      });

      test('reports any other exception as a business failure', () async {
        when(() => commandRunner.run(any())).thenThrow(Exception('big bad'));

        final result = await run();

        expect(result.isError, isTrue);
        final payload = payloadOf(result);
        expect(payload['failureType'], equals('business'));
        expect(payload['reason'], contains('threw an exception'));
        expect(payload['reason'], contains('big bad'));
      });
    });

    group('directory', () {
      test('is the working directory of the run, then restored', () async {
        String? cwdDuringRun;
        when(() => commandRunner.run(any())).thenAnswer((_) async {
          cwdDuringRun = Directory.current.resolveSymbolicLinksSync();
          return ExitCode.success.code;
        });

        final result = await run(directory: tempDir.path);

        expect(result.isError, isFalse);
        expect(cwdDuringRun, equals(tempDir.resolveSymbolicLinksSync()));
        expect(Directory.current.path, equals(originalCwd));
        final action =
            payloadOf(result)['attemptedAction']! as Map<String, Object?>;
        expect(action['directory'], equals(tempDir.path));
      });

      test('stays stable for each of several overlapping runs', () async {
        final dirA = Directory.systemTemp.createTempSync('vgmcp_a_');
        final dirB = Directory.systemTemp.createTempSync('vgmcp_b_');
        addTearDown(() {
          dirA.deleteSync(recursive: true);
          dirB.deleteSync(recursive: true);
        });

        // For each run record (cwd at start, cwd after an async gap). With
        // serialization the cwd is stable within a run; without it, a sibling
        // run's Directory.current mutation would clobber it across the gap.
        final pairs = <List<String>>[];
        when(() => commandRunner.run(any())).thenAnswer((_) async {
          final before = Directory.current.path;
          await Future<void>.delayed(const Duration(milliseconds: 20));
          final after = Directory.current.path;
          pairs.add([before, after]);
          return ExitCode.success.code;
        });

        await Future.wait([
          run(directory: dirA.path),
          run(directory: dirB.path),
        ]);

        expect(pairs, hasLength(2));
        for (final pair in pairs) {
          expect(
            pair[1],
            equals(pair[0]),
            reason: 'cwd must stay stable for the duration of a single run',
          );
        }
        expect(
          pairs.map((p) => Directory(p[0]).resolveSymbolicLinksSync()).toSet(),
          equals({
            dirA.resolveSymbolicLinksSync(),
            dirB.resolveSymbolicLinksSync(),
          }),
        );
      });

      test('fails without running when it does not exist', () async {
        final missing = '${tempDir.path}/missing';

        final result = await run(directory: missing);

        expect(result.isError, isTrue);
        expect(payloadOf(result)['failureType'], equals('validation'));
        verifyNever(() => commandRunner.run(any()));
        expect(Directory.current.path, equals(originalCwd));
      });
    });

    group('captured command output', () {
      test('is the partial results of a failure', () async {
        when(() => commandRunner.run(any())).thenAnswer((_) async {
          stdout.write('compile error: boom');
          stderr.write('stderr detail');
          return ExitCode.software.code;
        });

        final result = await run();

        expect(result.isError, isTrue);
        final payload = payloadOf(result);
        expect(payload['status'], equals('partial_failure'));
        expect(payload['failureType'], equals('business'));
        expect(payload['reason'], contains('failed with exit code 70'));
        final partial = payload['partialResults']! as String;
        expect(partial, contains('compile error: boom'));
        expect(partial, contains('stderr detail'));
      });

      test('is the output of a success', () async {
        when(() => commandRunner.run(any())).thenAnswer((_) async {
          stdout.write('All tests passed!');
          return ExitCode.success.code;
        });

        final result = await run();

        expect(result.isError, isFalse);
        expect([
          for (final content in result.content) (content as TextContent).text,
        ], equals(['"test" completed successfully.', 'All tests passed!']));
        expect(payloadOf(result)['output'], equals('All tests passed!'));
      });

      test('includes what the injected in-zone logger writes', () async {
        // The load-bearing invariant: a Logger constructed INSIDE the zone
        // writes through the capture override. Driving the injected logger
        // (not the dart:io globals) is what would fail if the Logger were
        // built outside the zone.
        when(() => commandRunner.run(any())).thenAnswer((_) async {
          injectedLogger
            ..info('stdout via logger')
            ..err('stderr via logger');
          return ExitCode.unavailable.code;
        });

        final result = await run();

        final partial = payloadOf(result)['partialResults']! as String;
        expect(partial, contains('stdout via logger'));
        expect(partial, contains('stderr via logger'));
      });

      test('is kept when the run throws', () async {
        when(() => commandRunner.run(any())).thenAnswer((_) async {
          stdout.write('partial output before crash');
          throw Exception('boom');
        });

        final result = await run();

        expect(result.isError, isTrue);
        final payload = payloadOf(result);
        expect(payload['status'], equals('partial_failure'));
        expect(payload['reason'], contains('threw an exception'));
        expect(
          payload['partialResults'],
          contains('partial output before crash'),
        );
      });

      test('comes with the failing tests the run recorded', () async {
        when(() => commandRunner.run(any())).thenAnswer((_) async {
          TestRunRecorder.current?.recordPackage(
            const TestRunResults(
              failingTests: [(file: 'a_test.dart', name: 'a', error: 'boom')],
            ),
          );
          return ExitCode.software.code;
        });

        final result = await run(timeout: const Duration(seconds: 60));

        final payload = payloadOf(result);
        expect(payload['failureType'], equals('business'));
        expect(payload['failureReason'], equals('test_failure'));
      });
    });

    group('timeout', () {
      // Mimics the test command's SIGINT path: wait on
      // `ProcessSignalOverrides.current?.sigintWatch` and return
      // `ExitCode.success` when it fires. Unlike the real `flutter_tester`,
      // the mock also has to tolerate `sigintWatch` being null (a run without
      // a timeout doesn't open the override zone) and resolve as if the test
      // suite had passed.
      Future<int> sigintResponsive() async {
        final sigintWatch = ProcessSignalOverrides.current?.sigintWatch;
        if (sigintWatch != null) await sigintWatch.first;
        return ExitCode.success.code;
      }

      test('fails the run when the budget elapses', () async {
        when(() => commandRunner.run(any()))
            .thenAnswer((_) => sigintResponsive());

        final result = await run(timeout: const Duration(seconds: 1));

        expect(result.isError, isTrue);
        final payload = payloadOf(result);
        expect(payload['failureType'], equals('timeout'));
        expect(payload['reason'], contains('timed out after 1 seconds'));
      });

      test(
        'synthesizes a SIGINT so the command tears down its subprocess',
        () async {
          // The real test runner subscribes to
          // `ProcessSignalOverrides.current?.sigintWatch` and cancels its
          // subprocess subscription on SIGINT; the mock proves the same
          // signal is delivered by waiting on that stream and completing
          // only once it fires.
          var sigintObserved = false;
          when(() => commandRunner.run(any())).thenAnswer((_) async {
            final sigintWatch = ProcessSignalOverrides.current?.sigintWatch;
            expect(
              sigintWatch,
              isNotNull,
              reason:
                  'the timeout flow must open a ProcessSignalOverrides zone '
                  'so the test runner can kill its subprocess tree',
            );
            await sigintWatch!.first;
            sigintObserved = true;
            return ExitCode.success.code;
          });

          final result = await run(timeout: const Duration(milliseconds: 50));

          expect(
            sigintObserved,
            isTrue,
            reason:
                'the runner must deliver a SIGINT to the command, not just '
                'abandon the run',
          );
          expect(payloadOf(result)['failureType'], equals('timeout'));
        },
      );

      test('reports a success when the command beats the budget', () async {
        // A fast-finishing command inside the timeout flow must not be
        // misclassified as a timeout. Only an elapsed budget flips the flag.
        when(() => commandRunner.run(any())).thenAnswer((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          return ExitCode.success.code;
        });

        final result = await run(timeout: const Duration(seconds: 30));

        expect(result.isError, isFalse);
      });

      test('lets a queued run start once the first one timed out', () async {
        // The first run responds to the synthetic SIGINT; the second returns
        // normally. The lock must release when the first times out,
        // otherwise the second would never start.
        var callNumber = 0;
        when(() => commandRunner.run(any())).thenAnswer((_) {
          callNumber++;
          return callNumber == 1
              ? sigintResponsive()
              : Future.value(ExitCode.success.code);
        });

        final first = run(timeout: const Duration(milliseconds: 50));
        final second = run();

        final firstResult = await first;
        final secondResult = await second;

        expect(firstResult.isError, isTrue);
        expect(payloadOf(firstResult)['failureType'], equals('timeout'));
        expect(
          secondResult.isError,
          isFalse,
          reason: 'a queued run must start after a timeout releases the lock',
        );
      });

      test('waits for the command when no budget is given', () async {
        when(() => commandRunner.run(any())).thenAnswer((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          return ExitCode.success.code;
        });

        final result = await run();

        expect(result.isError, isFalse);
      });
    });
  });
}
