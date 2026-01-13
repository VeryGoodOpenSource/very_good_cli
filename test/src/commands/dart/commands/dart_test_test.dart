// Expected usage of the plugin will need to be adjacent strings due to format
// and also be longer than 80 chars.
// ignore_for_file: no_adjacent_strings_in_list, lines_longer_than_80_chars

import 'dart:io';

import 'package:args/args.dart';
import 'package:mason/mason.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:very_good_cli/src/cli/cli.dart';
import 'package:very_good_cli/src/commands/dart/commands/commands.dart';

import '../../../../helpers/helpers.dart';

class _MockLogger extends Mock implements Logger {}

class _MockArgResults extends Mock implements ArgResults {}

class _MockDartTestCommand extends Mock implements DartTestCommandCall {}

const expectedTestUsage = [
  'Run tests in a Dart project.\n'
      '\n'
      'Usage: very_good dart test [arguments]\n'
      '-h, --help                            Print this usage information.\n'
      '    --coverage                        Whether to collect coverage information.\n'
      '-r, --recursive                       Run tests recursively for all nested packages.\n'
      '    --[no-]optimization               Whether to apply optimizations for test performance.\n'
      '                                      Automatically disabled when --platform is specified.\n'
      '                                      Add the `skip_very_good_optimization` tag to specific test files to disable them individually.\n'
      '                                      (defaults to on)\n'
      '-j, --concurrency                     The number of concurrent test suites run. Automatically set to 1 when --platform is specified.\n'
      '                                      (defaults to "4")\n'
      '-t, --tags                            Run only tests associated with the specified tags.\n'
      '    --exclude-coverage                A glob which will be used to exclude files that match from the coverage (e.g. \'**/*.g.dart\').\n'
      '-x, --exclude-tags                    Run only tests that do not have the specified tags.\n'
      '    --min-coverage                    Whether to enforce a minimum coverage percentage.\n'
      '    --test-randomize-ordering-seed    The seed to randomize the execution order of test cases within test files.\n'
      '    --force-ansi                      Whether to force ansi output. If not specified, it will maintain the default behavior based on stdout and stderr.\n'
      '    --report-on=<lib/>                An optional file path to report coverage information to. This should be a path relative to the current working directory.\n'
      '    --platform=<chrome|vm>            The platform to run tests on. \n'
      '\n'
      'Run "very_good help" to see global options.',
];

// A concrete class should have methods with body
// and we just want to mock this class for the test.
// ignore: one_member_abstracts
abstract class DartTestCommandCall {
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
    String? reportOn,
  });
}

void main() {
  group('dart test', () {
    final cwd = Directory.current;
    const concurrency = '4';
    const defaultArguments = ['-j', concurrency];

    late Logger logger;
    late bool isFlutterInstalled;
    late ArgResults argResults;
    late DartTestCommandCall dartTest;
    late DartTestCommand testCommand;

    setUp(() {
      logger = _MockLogger();
      isFlutterInstalled = true;
      argResults = _MockArgResults();
      dartTest = _MockDartTestCommand();
      testCommand = DartTestCommand(
        logger: logger,
        dartInstalled: ({required Logger logger}) async => isFlutterInstalled,
        dartTest: dartTest.call,
      )..argResultOverrides = argResults;
      when(
        () => dartTest(
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
          reportOn: any(named: 'reportOn'),
        ),
      ).thenAnswer((_) async => [0]);
      when<dynamic>(() => argResults['concurrency']).thenReturn(concurrency);
      when<dynamic>(() => argResults['recursive']).thenReturn(false);
      when<dynamic>(() => argResults['coverage']).thenReturn(false);
      when<dynamic>(() => argResults['optimization']).thenReturn(true);
      when<dynamic>(() => argResults['platform']).thenReturn(null);
      when(() => argResults.rest).thenReturn([]);
    });

    tearDown(() {
      Directory.current = cwd;
    });

    test(
      'help',
      withRunner((commandRunner, logger, pubUpdater, printLogs) async {
        final result = await commandRunner.run(['dart', 'test', '--help']);
        expect(printLogs, equals(expectedTestUsage));
        expect(result, equals(ExitCode.success.code));

        printLogs.clear();

        final resultAbbr = await commandRunner.run(['dart', 'test', '-h']);
        expect(printLogs, equals(expectedTestUsage));
        expect(resultAbbr, equals(ExitCode.success.code));
      }),
    );

    test(
      'throws pubspec not found exception '
      'when no pubspec.yaml exists',
      withRunner((commandRunner, logger, pubUpdater, printLogs) async {
        final tempDirectory = Directory.systemTemp.createTempSync();
        addTearDown(() {
          Directory.current = cwd;
          tempDirectory.deleteSync(recursive: true);
        });

        Directory.current = tempDirectory.path;
        final result = await commandRunner.run(['dart', 'test']);
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
        addTearDown(() {
          Directory.current = cwd;
          tempDirectory.deleteSync(recursive: true);
        });

        Directory.current = tempDirectory.path;

        Directory(path.join(Directory.current.path, 'project')).createSync();
        File(
          path.join(
            Directory.current.path,
            'project',
            'pubspec.yaml',
          ),
        ).createSync();

        final result = await commandRunner.run(['dart', 'test', '-r']);
        expect(result, equals(ExitCode.success.code));
      }),
    );

    test('completes normally', () async {
      final result = await testCommand.run();
      expect(result, equals(ExitCode.success.code));
      verify(
        () => dartTest(
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
        () => dartTest(
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
        () => dartTest(
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
        () => dartTest(
          arguments: ['-j', '1'],
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
        () => dartTest(
          arguments: defaultArguments,
          logger: logger,
          stdout: logger.write,
          stderr: logger.err,
        ),
      ).called(1);
    });

    test('completes normally --platform chrome', () async {
      when<dynamic>(() => argResults['platform']).thenReturn('chrome');
      final result = await testCommand.run();
      expect(result, equals(ExitCode.success.code));
      verify(
        () => dartTest(
          arguments: ['--platform', 'chrome'],
          logger: logger,
          stdout: logger.write,
          stderr: logger.err,
        ),
      ).called(1);
    });

    test('disables optimization when --platform is specified', () async {
      when<dynamic>(() => argResults['platform']).thenReturn('chrome');
      final result = await testCommand.run();
      expect(result, equals(ExitCode.success.code));
      verify(
        () => dartTest(
          arguments: ['--platform', 'chrome'],
          logger: logger,
          stdout: logger.write,
          stderr: logger.err,
        ),
      ).called(1);
    });

    test('disables concurrency when --platform is specified', () async {
      when<dynamic>(() => argResults['platform']).thenReturn('chrome');
      final result = await testCommand.run();
      expect(result, equals(ExitCode.success.code));
      verify(
        () => dartTest(
          arguments: ['--platform', 'chrome'],
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
        () => dartTest(
          arguments: defaultArguments,
          optimizePerformance: true,
          randomSeed: any(named: 'randomSeed', that: isNotEmpty),
          logger: logger,
          stdout: logger.write,
          stderr: logger.err,
        ),
      ).called(1);
    });

    test(
      'completes normally --test-randomize-ordering-seed 2305182648',
      () async {
        const randomSeed = '2305182648';
        when<dynamic>(
          () => argResults['test-randomize-ordering-seed'],
        ).thenReturn(randomSeed);
        final result = await testCommand.run();
        expect(result, equals(ExitCode.success.code));
        verify(
          () => dartTest(
            arguments: defaultArguments,
            randomSeed: randomSeed,
            optimizePerformance: true,
            logger: logger,
            stdout: logger.write,
            stderr: logger.err,
          ),
        ).called(1);
      },
    );

    test('completes normally --coverage', () async {
      when<dynamic>(() => argResults['coverage']).thenReturn(true);
      final result = await testCommand.run();
      expect(result, equals(ExitCode.success.code));
      verify(
        () => dartTest(
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
        () => dartTest(
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
        () => dartTest(
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
        () => dartTest(
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

    test(
      'enables coverage collection when --min-coverage is supplied',
      () async {
        when<dynamic>(() => argResults['min-coverage']).thenReturn('0');
        final result = await testCommand.run();
        expect(result, equals(ExitCode.success.code));
        verify(
          () => dartTest(
            optimizePerformance: true,
            collectCoverage: true,
            arguments: defaultArguments,
            minCoverage: 0,
            logger: logger,
            stdout: logger.write,
            stderr: logger.err,
          ),
        ).called(1);
      },
    );

    test(
      'reports on a different directory when --report-on is supplied',
      () async {
        when<dynamic>(() => argResults['min-coverage']).thenReturn('0');
        when<dynamic>(() => argResults['report-on']).thenReturn('routes');
        final result = await testCommand.run();
        expect(result, equals(ExitCode.success.code));
        verify(
          () => dartTest(
            optimizePerformance: true,
            collectCoverage: true,
            arguments: defaultArguments,
            minCoverage: 0,
            logger: logger,
            stdout: logger.write,
            stderr: logger.err,
            reportOn: 'routes',
          ),
        ).called(1);
      },
    );

    test('fails when coverage not met', () async {
      when<dynamic>(() => argResults['coverage']).thenReturn(true);
      when<dynamic>(() => argResults['min-coverage']).thenReturn('100');
      const exception = MinCoverageNotMet(0);
      when(
        () => dartTest(
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
        () => dartTest(
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

    test('displays required precision see why coverage was not met', () async {
      when<dynamic>(() => argResults['coverage']).thenReturn(true);
      when<dynamic>(() => argResults['min-coverage']).thenReturn('100');
      const exception = MinCoverageNotMet(99.999995);
      when(
        () => dartTest(
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
        () => dartTest(
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
        () => logger.err(
          'Expected coverage >= 100.000000% but actual is 99.999995%.',
        ),
      ).called(1);
    });

    test(
      'exclude files from coverage when --exclude-coverage is used',
      () async {
        when<dynamic>(() => argResults['coverage']).thenReturn(true);
        when<dynamic>(
          () => argResults['exclude-coverage'],
        ).thenReturn('*.g.dart');
        final result = await testCommand.run();
        expect(result, equals(ExitCode.success.code));
        verify(
          () => dartTest(
            optimizePerformance: true,
            collectCoverage: true,
            excludeFromCoverage: '*.g.dart',
            arguments: defaultArguments,
            logger: logger,
            stdout: logger.write,
            stderr: logger.err,
          ),
        ).called(1);
      },
    );

    test('throws when exception occurs', () async {
      final exception = Exception('oops');
      when(
        () => dartTest(
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
        () => dartTest(
          optimizePerformance: true,
          arguments: defaultArguments,
          logger: logger,
          stdout: logger.write,
          stderr: logger.err,
        ),
      ).called(1);
      verify(() => logger.err('$exception')).called(1);
    });

    test('completes normally --force-ansi', () async {
      when<dynamic>(() => argResults['force-ansi']).thenReturn(true);
      final result = await testCommand.run();
      expect(result, equals(ExitCode.success.code));
      verify(
        () => dartTest(
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

    test(
      '''disables optimizePerformance when rest arguement is not an option''',
      () async {
        when(() => argResults.rest).thenReturn(['my-test.dart']);

        final result = await testCommand.run();

        expect(result, equals(ExitCode.success.code));
        verify(
          () => dartTest(
            arguments: [
              ...defaultArguments,
              ...argResults.rest,
            ],
            logger: logger,
            stdout: logger.write,
            stderr: logger.err,
          ),
        ).called(1);
      },
    );

    test(
      'enables optimizePerformance when rest arguement is an option',
      () async {
        when(() => argResults.rest).thenReturn(['--track-wdiget-creation']);

        final result = await testCommand.run();

        expect(result, equals(ExitCode.success.code));
        verify(
          () => dartTest(
            optimizePerformance: true,
            arguments: [
              ...defaultArguments,
              ...argResults.rest,
            ],
            logger: logger,
            stdout: logger.write,
            stderr: logger.err,
          ),
        ).called(1);
      },
    );
  });
}
