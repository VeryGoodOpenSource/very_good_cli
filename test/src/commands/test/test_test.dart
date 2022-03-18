import 'dart:io';

import 'package:args/args.dart';
import 'package:mason/mason.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:very_good_cli/src/cli/cli.dart';
import 'package:very_good_cli/src/commands/test/test.dart';

import '../../../helpers/helpers.dart';

const expectedTestUsage = [
  // ignore: no_adjacent_strings_in_list
  'Run tests in a Dart or Flutter project.\n'
      '\n'
      'Usage: very_good test [arguments]\n'
      '-h, --help                            Print this usage information.\n'
      '''    --coverage                        Whether to collect coverage information.\n'''
      '''-r, --recursive                       Run tests recursively for all nested packages.\n'''
      '''    --[no-]optimization               Whether to apply optimizations for test performance.\n'''
      '                                      (defaults to on)\n'
      '''    --exclude-coverage                A glob which will be used to exclude files that match from the coverage.\n'''
      '''-x, --exclude-tags                    Run only tests that do not have the specified tags.\n'''
      '''    --min-coverage                    Whether to enforce a minimum coverage percentage.\n'''
      '''    --test-randomize-ordering-seed    The seed to randomize the execution order of test cases within test files.\n'''
      '\n'
      'Run "very_good help" to see global options.'
];

// ignore: one_member_abstracts
abstract class FlutterTestCommand {
  Future<void> call({
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
  });
}

class MockLogger extends Mock implements Logger {}

class MockArgResults extends Mock implements ArgResults {}

class MockFlutterTestCommand extends Mock implements FlutterTestCommand {}

void main() {
  group('test', () {
    final cwd = Directory.current;
    const defaultArguments = ['--no-pub'];

    late Logger logger;
    late bool isFlutterInstalled;
    late ArgResults argResults;
    late FlutterTestCommand flutterTest;
    late TestCommand testCommand;

    setUp(() {
      Directory.current = cwd;
      logger = MockLogger();
      isFlutterInstalled = true;
      argResults = MockArgResults();
      flutterTest = MockFlutterTestCommand();
      testCommand = TestCommand(
        logger: logger,
        flutterInstalled: () async => isFlutterInstalled,
        flutterTest: flutterTest.call,
      )..argResultOverrides = argResults;
      when(
        () => flutterTest(
          cwd: any(named: 'cwd'),
          recursive: any(named: 'recursive'),
          collectCoverage: any(named: 'collectCoverage'),
          optimizePerformance: any(named: 'optimizePerformance'),
          minCoverage: any(named: 'minCoverage'),
          excludeFromCoverage: any(named: 'excludeFromCoverage'),
          arguments: any(named: 'arguments'),
          progress: any(named: 'progress'),
          stdout: any(named: 'stdout'),
          stderr: any(named: 'stderr'),
        ),
      ).thenAnswer((_) async {});
      when<dynamic>(() => argResults['recursive']).thenReturn(false);
      when<dynamic>(() => argResults['coverage']).thenReturn(false);
      when<dynamic>(() => argResults['optimization']).thenReturn(true);
      when(() => argResults.rest).thenReturn([]);
    });

    test(
      'help',
      withRunner((commandRunner, logger, printLogs) async {
        final result = await commandRunner.run(['test', '--help']);
        expect(printLogs, equals(expectedTestUsage));
        expect(result, equals(ExitCode.success.code));

        printLogs.clear();

        final resultAbbr = await commandRunner.run(['test', '-h']);
        expect(printLogs, equals(expectedTestUsage));
        expect(resultAbbr, equals(ExitCode.success.code));
      }),
    );

    test(
      'throws pubspec not found exception '
      'when no pubspec.yaml exists',
      withRunner((commandRunner, logger, printLogs) async {
        final directory = Directory.systemTemp.createTempSync();
        Directory.current = directory.path;
        final result = await commandRunner.run(['test']);
        expect(result, equals(ExitCode.noInput.code));
        verify(() {
          logger.err(any(that: contains('Could not find a pubspec.yaml in')));
        }).called(1);
      }),
    );

    test(
      'throws pubspec not found exception '
      'when no pubspec.yaml exists (recursive)',
      withRunner((commandRunner, logger, printLogs) async {
        final directory = Directory.systemTemp.createTempSync();
        Directory.current = directory.path;
        final result = await commandRunner.run(['test', '-r']);
        expect(result, equals(ExitCode.noInput.code));
        verify(() {
          logger.err(any(that: contains('Could not find a pubspec.yaml in')));
        }).called(1);
      }),
    );

    test('completes normally', () async {
      final result = await testCommand.run();
      expect(result, equals(ExitCode.success.code));
      verify(
        () => flutterTest(
          optimizePerformance: true,
          arguments: defaultArguments,
          progress: logger.progress,
          stdout: logger.write,
          stderr: logger.err,
        ),
      ).called(1);
    });

    test('completes normally --recursive', () async {
      when<dynamic>(() => argResults['recursive']).thenReturn(true);
      final result = await testCommand.run();
      expect(result, equals(ExitCode.success.code));
      verify(
        () => flutterTest(
          recursive: true,
          optimizePerformance: true,
          arguments: defaultArguments,
          progress: logger.progress,
          stdout: logger.write,
          stderr: logger.err,
        ),
      ).called(1);
    });

    test('completes normally --no-optimization', () async {
      when<dynamic>(() => argResults['optimization']).thenReturn(false);
      final result = await testCommand.run();
      expect(result, equals(ExitCode.success.code));
      verify(
        () => flutterTest(
          arguments: defaultArguments,
          progress: logger.progress,
          stdout: logger.write,
          stderr: logger.err,
        ),
      ).called(1);
    });

    test('completes normally --test-randomize-ordering-seed random', () async {
      when<dynamic>(
        () => argResults['test-randomize-ordering-seed'],
      ).thenReturn('random');
      final result = await testCommand.run();
      expect(result, equals(ExitCode.success.code));
      verify(
        () => flutterTest(
          arguments: [
            '--test-randomize-ordering-seed',
            'random',
            ...defaultArguments
          ],
          optimizePerformance: true,
          progress: logger.progress,
          stdout: logger.write,
          stderr: logger.err,
        ),
      ).called(1);
    });

    test('completes normally --test-randomize-ordering-seed 2305182648',
        () async {
      when<dynamic>(
        () => argResults['test-randomize-ordering-seed'],
      ).thenReturn('2305182648');
      final result = await testCommand.run();
      expect(result, equals(ExitCode.success.code));
      verify(
        () => flutterTest(
          arguments: [
            '--test-randomize-ordering-seed',
            '2305182648',
            ...defaultArguments
          ],
          optimizePerformance: true,
          progress: logger.progress,
          stdout: logger.write,
          stderr: logger.err,
        ),
      ).called(1);
    });

    test('completes normally --coverage', () async {
      when<dynamic>(() => argResults['coverage']).thenReturn(true);
      final result = await testCommand.run();
      expect(result, equals(ExitCode.success.code));
      verify(
        () => flutterTest(
          collectCoverage: true,
          optimizePerformance: true,
          arguments: defaultArguments,
          progress: logger.progress,
          stdout: logger.write,
          stderr: logger.err,
        ),
      ).called(1);
    });

    test('completes normally -x test-tag', () async {
      when<dynamic>(() => argResults['exclude-tags']).thenReturn('test-tag');
      final result = await testCommand.run();
      expect(result, equals(ExitCode.success.code));
      verify(
        () => flutterTest(
          optimizePerformance: true,
          arguments: ['-x', 'test-tag', ...defaultArguments],
          progress: logger.progress,
          stdout: logger.write,
          stderr: logger.err,
        ),
      ).called(1);
    });

    test('completes normally --coverage --min-coverage 0', () async {
      when<dynamic>(() => argResults['coverage']).thenReturn(true);
      when<dynamic>(() => argResults['min-coverage']).thenReturn('0');
      final result = await testCommand.run();
      expect(result, equals(ExitCode.success.code));
      verify(
        () => flutterTest(
          optimizePerformance: true,
          collectCoverage: true,
          arguments: defaultArguments,
          minCoverage: 0,
          progress: logger.progress,
          stdout: logger.write,
          stderr: logger.err,
        ),
      ).called(1);
    });

    test('fails when coverage not met', () async {
      when<dynamic>(() => argResults['coverage']).thenReturn(true);
      when<dynamic>(() => argResults['min-coverage']).thenReturn('100');
      const exception = MinCoverageNotMet(0);
      when(
        () => flutterTest(
          cwd: any(named: 'cwd'),
          recursive: any(named: 'recursive'),
          collectCoverage: any(named: 'collectCoverage'),
          optimizePerformance: any(named: 'optimizePerformance'),
          minCoverage: any(named: 'minCoverage'),
          excludeFromCoverage: any(named: 'excludeFromCoverage'),
          arguments: any(named: 'arguments'),
          progress: any(named: 'progress'),
          stdout: any(named: 'stdout'),
          stderr: any(named: 'stderr'),
        ),
      ).thenThrow(exception);
      final result = await testCommand.run();
      expect(result, equals(ExitCode.unavailable.code));
      verify(
        () => flutterTest(
          optimizePerformance: true,
          collectCoverage: true,
          arguments: defaultArguments,
          minCoverage: 100,
          progress: logger.progress,
          stdout: logger.write,
          stderr: logger.err,
        ),
      ).called(1);
      verify(
        () => logger.err('Expected coverage >= 100.00% but actual is 0.00%.'),
      ).called(1);
    });

    test('exclude files from coverage when --exclude-coverage is used',
        () async {
      when<dynamic>(() => argResults['coverage']).thenReturn(true);
      when<dynamic>(
        () => argResults['exclude-coverage'],
      ).thenReturn('*.g.dart');
      final result = await testCommand.run();
      expect(result, equals(ExitCode.success.code));
      verify(
        () => flutterTest(
          optimizePerformance: true,
          collectCoverage: true,
          excludeFromCoverage: '*.g.dart',
          arguments: defaultArguments,
          progress: logger.progress,
          stdout: logger.write,
          stderr: logger.err,
        ),
      ).called(1);
    });

    test('throws when exception occurs', () async {
      final exception = Exception('oops');
      when(
        () => flutterTest(
          cwd: any(named: 'cwd'),
          recursive: any(named: 'recursive'),
          collectCoverage: any(named: 'collectCoverage'),
          optimizePerformance: any(named: 'optimizePerformance'),
          minCoverage: any(named: 'minCoverage'),
          excludeFromCoverage: any(named: 'excludeFromCoverage'),
          arguments: any(named: 'arguments'),
          progress: any(named: 'progress'),
          stdout: any(named: 'stdout'),
          stderr: any(named: 'stderr'),
        ),
      ).thenThrow(exception);
      final result = await testCommand.run();
      expect(result, equals(ExitCode.unavailable.code));
      verify(
        () => flutterTest(
          optimizePerformance: true,
          arguments: defaultArguments,
          progress: logger.progress,
          stdout: logger.write,
          stderr: logger.err,
        ),
      ).called(1);
      verify(() => logger.err('$exception')).called(1);
    });
  });
}
