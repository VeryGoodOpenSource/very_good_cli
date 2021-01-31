import 'package:io/io.dart';
import 'package:mason/mason.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:very_good_cli/src/command_runner.dart';
import 'package:very_good_cli/src/commands/create.dart';

class MockLogger extends Mock implements Logger {}

void main() {
  group('Create', () {
    Logger logger;
    VeryGoodCommandRunner commandRunner;

    setUp(() {
      logger = MockLogger();
      commandRunner = VeryGoodCommandRunner(logger: logger);
    });

    test('can be instantiated without an explicit Logger instance', () {
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
      final result = await commandRunner.run(
        ['create', '.', '--project-name', 'my_app'],
      );
      expect(result, equals(ExitCode.success.code));
      verify(logger.alert('Created a Very Good App! 🦄')).called(1);
    });
  });
}
