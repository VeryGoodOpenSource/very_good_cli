import 'package:dart_mcp/server.dart';
import 'package:test/test.dart';
import 'package:very_good_cli/src/mcp/runner/runner.dart';

void main() {
  group('toolOutputSchema', () {
    test('lists every failure type and reason', () {
      final properties = toolOutputSchema.properties!;

      expect(
        (properties['failureType']! as Map<String, Object?>)['enum'],
        equals([
          'validation',
          'permission',
          'transient',
          'timeout',
          'business',
        ]),
      );
      expect(
        (properties['failureReason']! as Map<String, Object?>)['enum'],
        equals([
          for (final reason in ToolFailureReason.values) reason.jsonName,
        ]),
      );
    });

    test('rejects a payload without a status', () {
      expect(
        toolOutputSchema.validate({'attemptedAction': <String, Object?>{}}),
        isNotEmpty,
      );
    });
  });
}
