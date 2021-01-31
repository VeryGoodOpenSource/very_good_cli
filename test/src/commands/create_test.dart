import 'package:io/io.dart';
import 'package:mason/mason.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:very_good_cli/src/command_runner.dart';
import 'package:very_good_cli/src/commands/commands.dart';

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

    test('throws UsageException when --project-name is missing', () async {
      const expectedErrorMessage = 'Required: --project-name.\n\n'
          'e.g: very_good create --project-name my_app';
      final result = await commandRunner.run(['create']);
      expect(result, equals(ExitCode.usage.code));
      verify(logger.err(expectedErrorMessage)).called(1);
    });

    test('throws UsageException when --project-name is invalid', () async {
      const expectedErrorMessage = '"My App" is not a valid package name.\n\n'
          'See https://dart.dev/tools/pub/pubspec#name for more information.';
      final result = await commandRunner.run(
        ['create', '--project-name', 'My App'],
      );
      expect(result, equals(ExitCode.usage.code));
      verify(logger.err(expectedErrorMessage)).called(1);
    });

    test('completes successfully with correct output', () async {
      final result = await commandRunner.run(
        ['create', '--project-name', 'my_app'],
      );
      expect(result, equals(ExitCode.success.code));
      verify(logger.alert('Created a Very Good App! 🦄')).called(1);
    });
  });
}
