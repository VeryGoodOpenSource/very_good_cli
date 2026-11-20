import 'package:dart_mcp/server.dart';
import 'package:test/test.dart';
import 'package:very_good_cli/src/cli/cli.dart';
import 'package:very_good_cli/src/mcp/runner/runner.dart';

void main() {
  group(StructuredToolSuccess, () {
    test('reports only the attempted action of a silent run', () {
      final result = const StructuredToolSuccess(
        toolName: 'get',
        commandString: 'very_good packages get',
      ).toCallToolResult();

      expect(result.isError, isFalse);
      expect([
        for (final content in result.content) (content as TextContent).text,
      ], equals(['"get" completed successfully.']));
      expect(
        result.structuredContent,
        equals({
          'status': 'success',
          'attemptedAction': {
            'tool': 'get',
            'command': 'very_good packages get',
          },
        }),
      );
    });

    test('reports the output, the arguments and the test results', () {
      final result = const StructuredToolSuccess(
        toolName: 'test',
        commandString: 'very_good test --coverage',
        directory: '/tmp/project',
        capturedOutput: 'All tests passed!',
        attemptedArguments: {'coverage': true},
        testResults: TestRunResults(passed: 3, skipped: 1, durationMs: 1500),
      ).toCallToolResult();

      expect([
        for (final content in result.content) (content as TextContent).text,
      ], equals(['"test" completed successfully.', 'All tests passed!']));
      expect(
        result.structuredContent,
        equals({
          'status': 'success',
          'attemptedAction': {
            'tool': 'test',
            'command': 'very_good test --coverage',
            'directory': '/tmp/project',
            'arguments': {'coverage': true},
          },
          'test': {
            'results': {
              'passed': 3,
              'failed': 0,
              'skipped': 1,
              'durationMs': 1500,
              'failingTests': <Object?>[],
            },
          },
          'output': 'All tests passed!',
        }),
      );
      expect(toolOutputSchema.validate(result.structuredContent), isEmpty);
    });
  });
}
