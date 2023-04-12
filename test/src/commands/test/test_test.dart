import 'dart:io';

import 'package:args/args.dart';
import 'package:mason/mason.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as path;
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
      '''                                      (defaults to on)\n'''
      '''-j, --concurrency                     The number of concurrent test suites run.\n'''
      '''                                      (defaults to "4")\n'''
      '''-t, --tags                            Run only tests associated with the specified tags.\n'''
      '''    --exclude-coverage                A glob which will be used to exclude files that match from the coverage.\n'''
      '''-x, --exclude-tags                    Run only tests that do not have the specified tags.\n'''
      '''    --min-coverage                    Whether to enforce a minimum coverage percentage.\n'''
      '''    --test-randomize-ordering-seed    The seed to randomize the execution order of test cases within test files.\n'''
      '''    --update-goldens                  Whether "matchesGoldenFile()" calls within your test methods should update the golden files.\n'''
      '''    --force-ansi                      Whether to force ansi output. If not specified, it will maintain the default behavior based on stdout and stderr.\n'''
      '''    --dart-define=<foo=bar>           Additional key-value pairs that will be available as constants from the String.fromEnvironment, bool.fromEnvironment, int.fromEnvironment, and double.fromEnvironment constructors. Multiple defines can be passed by repeating "--dart-define" multiple times.\n'''
      '\n'
      'Run "very_good help" to see global options.'
];

// ignore: one_member_abstracts
abstract class FlutterTestCommand {
  Future<List<int>> call({
    String cwd = '.',
    bool recursive = false,
    bool collectCoverage = false,
    bool optimizePerformance = false,
    double? minCoverage,
    String? excludeFromCoverage,
    String? randomSeed,
    List<String>? arguments,
    Logger? logger,
    void Function(String)? stdout,
    void Function(String)? stderr,
    bool? forceAnsi,
  });
}

class MockLogger extends Mock implements Logger {}

class MockArgResults extends Mock implements ArgResults {}

class MockFlutterTestCommand extends Mock implements FlutterTestCommand {}

void main() {
  group('test', () {
    final cwd = Directory.current;
    const concurrency = '4';
    const defaultArguments = ['-j', concurrency, '--no-pub'];

    late Logger logger;
    late bool isFlutterInstalled;
    late ArgResults argResults;
    late FlutterTestCommand flutterTest;
    late TestCommand testCommand;

    setUp(() {
      logger = MockLogger();
      isFlutterInstalled = true;
      argResults = MockArgResults();
      flutterTest = MockFlutterTestCommand();
      testCommand = TestCommand(
        logger: logger,
        flutterInstalled: ({required Logger logger}) async =>
            isFlutterInstalled,
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
          randomSeed: any(named: 'randomSeed'),
          arguments: any(named: 'arguments'),
          logger: any(named: 'logger'),
          stdout: any(named: 'stdout'),
          stderr: any(named: 'stderr'),
          forceAnsi: any(named: 'forceAnsi'),
        ),
      ).thenAnswer((_) async => [0]);
      when<dynamic>(() => argResults['concurrency']).thenReturn(concurrency);
      when<dynamic>(() => argResults['recursive']).thenReturn(false);
      when<dynamic>(() => argResults['coverage']).thenReturn(false);
      when<dynamic>(() => argResults['update-goldens']).thenReturn(false);
      when<dynamic>(() => argResults['optimization']).thenReturn(true);
      when(() => argResults.rest).thenReturn([]);
    });

    tearDown(() {
      Directory.current = cwd;
    });

    test(
      'help',
      withRunner((commandRunner, logger, pubUpdater, printLogs) async {
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
      withRunner((commandRunner, logger, pubUpdater, printLogs) async {
        final tempDirectory = Directory.systemTemp.createTempSync();
        addTearDown(() => tempDirectory.deleteSync(recursive: true));

        Directory.current = tempDirectory.path;
        final result = await commandRunner.run(['test']);
        expect(result, equals(ExitCode.noInput.code));
        verify(() {
          logger.err(any(that: contains('Could not find a pubspec.yaml in')));
        }).called(1);
      }),
    );

    test(
      'completes normally when no pubspec.yaml exists (recursive)',
      withRunner((commandRunner, logger, pubUpdater, printLogs) async {
        final tempDirectory = Directory.systemTemp.createTempSync();
        addTearDown(() => tempDirectory.deleteSync(recursive: true));

        Directory.current = tempDirectory.path;

        Directory(path.join(Directory.current.path, 'project')).createSync();
        File(
          path.join(
            Directory.current.path,
            'project',
            'pubspec.yaml',
          ),
        ).createSync();

        final result = await commandRunner.run(['test', '-r']);
        expect(result, equals(ExitCode.success.code));
      }),
    );

    test('completes normally', () async {
      final result = await testCommand.run();
      expect(result, equals(ExitCode.success.code));
      verify(
        () => flutterTest(
          optimizePerformance: true,
          arguments: defaultArguments,
          logger: logger,
          stdout: logger.write,
          stderr: logger.err,
        ),
      ).called(1);
    });

    test('exits with 70 when tests do not pass', () async {
      when(
        () => flutterTest(
          cwd: any(named: 'cwd'),
          recursive: any(named: 'recursive'),
          collectCoverage: any(named: 'collectCoverage'),
          optimizePerformance: any(named: 'optimizePerformance'),
          minCoverage: any(named: 'minCoverage'),
          excludeFromCoverage: any(named: 'excludeFromCoverage'),
          arguments: any(named: 'arguments'),
          logger: any(named: 'logger'),
          stdout: any(named: 'stdout'),
          stderr: any(named: 'stderr'),
        ),
      ).thenAnswer(
        (_) async => [ExitCode.success.code, ExitCode.unavailable.code],
      );
      final result = await testCommand.run();
      expect(result, equals(ExitCode.unavailable.code));
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
          logger: logger,
          stdout: logger.write,
          stderr: logger.err,
        ),
      ).called(1);
    });

    test('completes normally --concurrency 1', () async {
      when<dynamic>(() => argResults['concurrency']).thenReturn('1');
      final result = await testCommand.run();
      expect(result, equals(ExitCode.success.code));
      verify(
        () => flutterTest(
          arguments: ['-j', '1', '--no-pub'],
          optimizePerformance: true,
          logger: logger,
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
          logger: logger,
          stdout: logger.write,
          stderr: logger.err,
        ),
      ).called(1);
    });

    test('completes normally --update-goldens', () async {
      when<dynamic>(() => argResults['update-goldens']).thenReturn(true);
      final result = await testCommand.run();
      expect(result, equals(ExitCode.success.code));
      verify(
        () => flutterTest(
          arguments: ['--update-goldens', ...defaultArguments],
          logger: logger,
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
          arguments: defaultArguments,
          optimizePerformance: true,
          randomSeed: any(named: 'randomSeed', that: isNotEmpty),
          logger: logger,
          stdout: logger.write,
          stderr: logger.err,
        ),
      ).called(1);
    });

    test('completes normally --test-randomize-ordering-seed 2305182648',
        () async {
      const randomSeed = '2305182648';
      when<dynamic>(
        () => argResults['test-randomize-ordering-seed'],
      ).thenReturn(randomSeed);
      final result = await testCommand.run();
      expect(result, equals(ExitCode.success.code));
      verify(
        () => flutterTest(
          arguments: defaultArguments,
          randomSeed: randomSeed,
          optimizePerformance: true,
          logger: logger,
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
          logger: logger,
          stdout: logger.write,
          stderr: logger.err,
        ),
      ).called(1);
    });

    test('completes normally -t test-tag', () async {
      when<dynamic>(() => argResults['tags']).thenReturn('test-tag');
      final result = await testCommand.run();
      expect(result, equals(ExitCode.success.code));
      verify(
        () => flutterTest(
          optimizePerformance: true,
          arguments: ['-t', 'test-tag', ...defaultArguments],
          logger: logger,
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
          logger: logger,
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
          logger: logger,
          stdout: logger.write,
          stderr: logger.err,
        ),
      ).called(1);
    });

    test('enables coverage collection when --min-coverage is supplied',
        () async {
      when<dynamic>(() => argResults['min-coverage']).thenReturn('0');
      final result = await testCommand.run();
      expect(result, equals(ExitCode.success.code));
      verify(
        () => flutterTest(
          optimizePerformance: true,
          collectCoverage: true,
          arguments: defaultArguments,
          minCoverage: 0,
          logger: logger,
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
          logger: any(named: 'logger'),
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
          logger: logger,
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
          logger: logger,
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
          logger: any(named: 'logger'),
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
          logger: logger,
          stdout: logger.write,
          stderr: logger.err,
        ),
      ).called(1);
      verify(() => logger.err('$exception')).called(1);
    });

    test('completes normally --dart-define', () async {
      when<dynamic>(
        () => argResults['dart-define'],
      ).thenReturn(['FOO=bar', 'X=42']);
      final result = await testCommand.run();
      expect(result, equals(ExitCode.success.code));
      verify(
        () => flutterTest(
          optimizePerformance: true,
          arguments: [
            '--dart-define=FOO=bar',
            '--dart-define=X=42',
            ...defaultArguments,
          ],
          logger: logger,
          stdout: logger.write,
          stderr: logger.err,
        ),
      ).called(1);
    });

    test('completes normally --force-ansi', () async {
      when<dynamic>(() => argResults['force-ansi']).thenReturn(true);
      final result = await testCommand.run();
      expect(result, equals(ExitCode.success.code));
      verify(
        () => flutterTest(
          optimizePerformance: true,
          arguments: [
            ...defaultArguments,
          ],
          logger: logger,
          stdout: logger.write,
          stderr: logger.err,
          forceAnsi: true,
        ),
      ).called(1);
    });
  });
}
