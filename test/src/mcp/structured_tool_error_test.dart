import 'dart:convert';

import 'package:dart_mcp/server.dart';
import 'package:mason/mason.dart';
import 'package:test/test.dart';
import 'package:very_good_cli/src/mcp/structured_tool_error.dart';

void main() {
  group(ToolFailureType, () {
    test('classifies validation exit codes', () {
      expect(
        ToolFailureType.fromExitCode(ExitCode.usage.code),
        equals(ToolFailureType.validation),
      );
      expect(
        ToolFailureType.fromExitCode(ExitCode.data.code),
        equals(ToolFailureType.validation),
      );
      expect(
        ToolFailureType.fromExitCode(ExitCode.noInput.code),
        equals(ToolFailureType.validation),
      );
      expect(
        ToolFailureType.fromExitCode(ExitCode.config.code),
        equals(ToolFailureType.validation),
      );
    });

    test('classifies permission exit codes', () {
      expect(
        ToolFailureType.fromExitCode(ExitCode.noPerm.code),
        equals(ToolFailureType.permission),
      );
    });

    test('classifies transient exit codes', () {
      expect(
        ToolFailureType.fromExitCode(ExitCode.unavailable.code),
        equals(ToolFailureType.transient),
      );
      expect(
        ToolFailureType.fromExitCode(ExitCode.tempFail.code),
        equals(ToolFailureType.transient),
      );
      expect(
        ToolFailureType.fromExitCode(ExitCode.ioError.code),
        equals(ToolFailureType.transient),
      );
      expect(
        ToolFailureType.fromExitCode(ExitCode.osError.code),
        equals(ToolFailureType.transient),
      );
      expect(
        ToolFailureType.fromExitCode(ExitCode.osFile.code),
        equals(ToolFailureType.transient),
      );
      expect(
        ToolFailureType.fromExitCode(ExitCode.cantCreate.code),
        equals(ToolFailureType.transient),
      );
    });

    test('defaults unknown or software exit codes to business', () {
      expect(
        ToolFailureType.fromExitCode(ExitCode.software.code),
        equals(ToolFailureType.business),
      );
      expect(
        ToolFailureType.fromExitCode(1),
        equals(ToolFailureType.business),
      );
      expect(
        ToolFailureType.fromExitCode(255),
        equals(ToolFailureType.business),
      );
    });
  });

  group('alternativeApproachesFor', () {
    test('returns non-empty suggestions for every known failureType', () {
      for (final type in ToolFailureType.values) {
        expect(
          alternativeApproachesFor(type),
          isNotEmpty,
          reason: '$type must offer at least one alternative approach',
        );
      }
    });
  });

  group(StructuredToolError, () {
    test('emits a "failure" status when no captured output is provided', () {
      final result = const StructuredToolError(
        toolName: 'test',
        reason: 'boom',
        failureType: ToolFailureType.business,
      ).toCallToolResult();
      expect(result.isError, isTrue);
      final payload =
          jsonDecode((result.content.first as TextContent).text)
              as Map<String, Object?>;
      expect(payload['status'], equals('failure'));
      expect(payload['reason'], equals('boom'));
      expect(payload['partialResults'], isNull);
      final action = payload['attemptedAction']! as Map<String, Object?>;
      expect(action, equals({'tool': 'test'}));
    });

    test(
      'emits a "partial_failure" status and preserves captured output',
      () {
        final result = const StructuredToolError(
          toolName: 'create',
          reason: 'crashed',
          failureType: ToolFailureType.transient,
          commandString: 'very_good create flutter_app my_app',
          directory: '/tmp/x',
          attemptedArguments: {'name': 'my_app'},
          capturedOutput: 'compile error',
        ).toCallToolResult();
        final payload =
            jsonDecode((result.content.first as TextContent).text)
                as Map<String, Object?>;
        expect(payload['status'], equals('partial_failure'));
        expect(payload['partialResults'], equals('compile error'));
        final action = payload['attemptedAction']! as Map<String, Object?>;
        expect(
          action['command'],
          equals('very_good create flutter_app my_app'),
        );
        expect(action['directory'], equals('/tmp/x'));
        expect(action['arguments'], equals({'name': 'my_app'}));
      },
    );

    test('omits arguments key when attemptedArguments is empty', () {
      final result = const StructuredToolError(
        toolName: 'test',
        reason: 'oops',
        failureType: ToolFailureType.business,
        attemptedArguments: {},
      ).toCallToolResult();
      final payload =
          jsonDecode((result.content.first as TextContent).text)
              as Map<String, Object?>;
      final action = payload['attemptedAction']! as Map<String, Object?>;
      expect(action.containsKey('arguments'), isFalse);
    });
  });
}
