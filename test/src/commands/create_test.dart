import 'package:io/io.dart';
import 'package:mason/mason.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:very_good_cli/src/commands/create.dart';

class MockLogger extends Mock implements Logger {}

void main() {
  group('Create', () {
    Logger logger;
    CreateCommand command;

    setUp(() {
      logger = MockLogger();
      command = CreateCommand(logger: logger);
    });

    test('can be instantiated without an explicit Logger instance', () {
      final command = CreateCommand();
      expect(command, isNotNull);
    });

    test('completes successfully with correct output', () async {
      final result = await command.run();
      expect(result, equals(ExitCode.success.code));
      verify(logger.alert('Created a Very Good App! 🦄')).called(1);
    });
  });
}
