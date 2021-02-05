import 'package:args/args.dart';
import 'package:io/ansi.dart';
import 'package:io/io.dart';
import 'package:mason/mason.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:very_good_cli/src/command_runner.dart';
import 'package:very_good_cli/src/commands/create.dart';

class MockArgResults extends Mock implements ArgResults {}

class MockLogger extends Mock implements Logger {}

class MockMasonGenerator extends Mock implements MasonGenerator {}

void main() {
  group('Create', () {
    Logger logger;
    VeryGoodCommandRunner commandRunner;

    setUp(() {
      logger = MockLogger();
      when(logger.progress(any)).thenReturn((_) {});
      commandRunner = VeryGoodCommandRunner(logger: logger);
    });

    test('can be instantiated without any explicit dependencies', () {
      final command = CreateCommand();
      expect(command, isNotNull);
    });

    test(
        'throws UsageException when --project-name is missing '
        'and directory base is not a valid package name', () async {
      const expectedErrorMessage = '".tmp" is not a valid package name.\n\n'
          'See https://dart.dev/tools/pub/pubspec#name for more information.';
      final result = await commandRunner.run(['create', '.tmp']);
      expect(result, equals(ExitCode.usage.code));
      verify(logger.err(expectedErrorMessage)).called(1);
    });

    test('throws UsageException when --project-name is invalid', () async {
      const expectedErrorMessage = '"My App" is not a valid package name.\n\n'
          'See https://dart.dev/tools/pub/pubspec#name for more information.';
      final result = await commandRunner.run(
        ['create', '.', '--project-name', 'My App'],
      );
      expect(result, equals(ExitCode.usage.code));
      verify(logger.err(expectedErrorMessage)).called(1);
    });

    test('throws UsageException when output directory is missing', () async {
      const expectedErrorMessage =
          'No option specified for the output directory.';
      final result = await commandRunner.run(['create']);
      expect(result, equals(ExitCode.usage.code));
      verify(logger.err(expectedErrorMessage)).called(1);
    });

    test('throws UsageException when multiple output directories are provided',
        () async {
      const expectedErrorMessage = 'Multiple output directories specified.';
      final result = await commandRunner.run(['create', './a', './b']);
      expect(result, equals(ExitCode.usage.code));
      verify(logger.err(expectedErrorMessage)).called(1);
    });

    test('completes successfully with correct output', () async {
      final argResults = MockArgResults();
      final generator = MockMasonGenerator();
      final command = CreateCommand(
        logger: logger,
        generator: (_) async => generator,
      )..argResultOverrides = argResults;
      when(argResults['project-name']).thenReturn('my_app');
      when(argResults.rest).thenReturn(['.tmp']);
      when(generator.generate(any, vars: anyNamed('vars')))
          .thenAnswer((_) async => 62);
      final result = await command.run();
      expect(result, equals(ExitCode.success.code));
      verify(logger.progress('Bootstrapping')).called(1);
      verify(logger.info(
        '${lightGreen.wrap('✓')} '
        'Generated 62 file(s):',
      ));
      verify(logger.alert('Created a Very Good App! 🦄')).called(1);
      verify(
        generator.generate(
          argThat(
            isA<DirectoryGeneratorTarget>().having(
              (g) => g.dir.path,
              'dir',
              '.tmp',
            ),
          ),
          vars: {'project_name': 'my_app'},
        ),
      ).called(1);
    });
  });
}
