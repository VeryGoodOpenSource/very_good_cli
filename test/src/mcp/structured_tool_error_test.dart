import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:checked_yaml/checked_yaml.dart';
import 'package:dart_mcp/server.dart';
import 'package:mason/mason.dart';
import 'package:test/test.dart';
import 'package:very_good_cli/src/cli/cli.dart';
import 'package:very_good_cli/src/mcp/structured_tool_error.dart';
import 'package:yaml/yaml.dart';

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
      expect(ToolFailureType.fromExitCode(1), equals(ToolFailureType.business));
      expect(
        ToolFailureType.fromExitCode(255),
        equals(ToolFailureType.business),
      );
    });

    group('fromException', () {
      test('classifies network and timeout exceptions as transient', () {
        for (final exception in <Exception>[
          const SocketException('connection refused'),
          const HttpException('bad gateway'),
          const TlsException('handshake failed'),
          TimeoutException('too slow'),
        ]) {
          expect(
            ToolFailureType.fromException(exception),
            equals(ToolFailureType.transient),
            reason: '$exception',
          );
        }
      });

      test('classifies bad input exceptions as validation', () {
        for (final exception in <Exception>[
          UsageException('bad flag', 'usage'),
          const FormatException('bad format'),
          YamlException('bad yaml', null),
          ParsedYamlException.fromYamlException(
            YamlException('bad yaml', null),
          ),
          const PathNotFoundException(
            '/missing',
            OSError('No such file or directory', 2),
          ),
        ]) {
          expect(
            ToolFailureType.fromException(exception),
            equals(ToolFailureType.validation),
            reason: '$exception',
          );
        }
      });

      test('classifies PathAccessException as permission', () {
        expect(
          ToolFailureType.fromException(
            const PathAccessException(
              '/locked',
              OSError('Permission denied', 13),
              'Cannot open file',
            ),
          ),
          equals(ToolFailureType.permission),
        );
      });

      test('classifies other file system errors as business', () {
        expect(
          ToolFailureType.fromException(
            const FileSystemException(
              'Cannot open file',
              '/disk',
              OSError('No space left on device', 28),
            ),
          ),
          equals(ToolFailureType.business),
        );
        expect(
          ToolFailureType.fromException(
            const FileSystemException(
              'Input/output error',
              '/disk',
              OSError('I/O error', 5),
            ),
          ),
          equals(ToolFailureType.business),
        );
        expect(
          ToolFailureType.fromException(
            const FileSystemException('Cannot open file', '/disk'),
          ),
          equals(ToolFailureType.business),
        );
      });

      test('classifies unknown exceptions as business', () {
        expect(
          ToolFailureType.fromException(Exception('Invalid SDK hash')),
          equals(ToolFailureType.business),
        );
      });
    });
  });

  group(ToolFailureReason, () {
    test('names every reason in snake case', () {
      expect(
        {
          for (final reason in ToolFailureReason.values)
            reason: reason.jsonName,
        },
        equals({
          ToolFailureReason.testFailure: 'test_failure',
          ToolFailureReason.coverageBelowThreshold: 'coverage_below_threshold',
          ToolFailureReason.checkFailed: 'check_failed',
          ToolFailureReason.toolCrash: 'tool_crash',
          ToolFailureReason.invalidInput: 'invalid_input',
          ToolFailureReason.usageError: 'usage_error',
          ToolFailureReason.timeout: 'timeout',
          ToolFailureReason.permissionDenied: 'permission_denied',
        }),
      );
    });
  });

  group('ToolFailureReason.alternativeApproaches', () {
    test('returns non-empty suggestions for every failureReason', () {
      for (final reason in ToolFailureReason.values) {
        expect(
          reason.alternativeApproaches,
          isNotEmpty,
          reason: '$reason must offer at least one alternative approach',
        );
      }
    });

    test('advises a retry only for a crashed tool', () {
      for (final reason in ToolFailureReason.values) {
        expect(
          reason.alternativeApproaches,
          reason == ToolFailureReason.toolCrash
              ? contains(startsWith('Retry the command'))
              : everyElement(isNot(startsWith('Retry the command'))),
          reason: '$reason',
        );
      }
    });
  });

  group('ToolFailureType.failureReason', () {
    test('returns the default reason for each failure type', () {
      expect(
        {for (final type in ToolFailureType.values) type: type.failureReason},
        equals({
          ToolFailureType.validation: ToolFailureReason.invalidInput,
          ToolFailureType.permission: ToolFailureReason.permissionDenied,
          ToolFailureType.transient: ToolFailureReason.toolCrash,
          ToolFailureType.timeout: ToolFailureReason.timeout,
          ToolFailureType.business: ToolFailureReason.checkFailed,
        }),
      );
    });
  });

  group(StructuredToolError, () {
    test('emits a "failure" status when no captured output is provided', () {
      final result = const StructuredToolError(
        toolName: 'test',
        reason: 'boom',
        failureType: ToolFailureType.business,
        failureReason: ToolFailureReason.testFailure,
      ).toCallToolResult();
      expect(result.isError, isTrue);
      final payload = jsonDecode(
        (result.content.first as TextContent).text,
      ) as Map<String, Object?>;
      expect(payload['status'], equals('failure'));
      expect(
        payload.keys.take(3),
        equals(['status', 'failureType', 'failureReason']),
      );
      expect(payload['failureType'], equals('business'));
      expect(payload['failureReason'], equals('test_failure'));
      expect(
        payload['alternativeApproaches'],
        equals(ToolFailureReason.testFailure.alternativeApproaches),
      );
      expect(payload['reason'], equals('boom'));
      expect(payload['partialResults'], isNull);
      final action = payload['attemptedAction']! as Map<String, Object?>;
      expect(action, equals({'tool': 'test'}));
    });

    test('emits a "partial_failure" status and preserves captured output', () {
      final result = const StructuredToolError(
        toolName: 'create',
        reason: 'crashed',
        failureType: ToolFailureType.transient,
        failureReason: ToolFailureReason.toolCrash,
        commandString: 'very_good create flutter_app my_app',
        directory: '/tmp/x',
        attemptedArguments: {'name': 'my_app'},
        capturedOutput: 'compile error',
      ).toCallToolResult();
      final payload = jsonDecode(
        (result.content.first as TextContent).text,
      ) as Map<String, Object?>;
      expect(payload['status'], equals('partial_failure'));
      expect(payload['partialResults'], equals('compile error'));
      final action = payload['attemptedAction']! as Map<String, Object?>;
      expect(action['command'], equals('very_good create flutter_app my_app'));
      expect(action['directory'], equals('/tmp/x'));
      expect(action['arguments'], equals({'name': 'my_app'}));
    });

    group('test', () {
      Map<String, Object?> payloadOf(TestRunRecorder testRun) => jsonDecode(
        (StructuredToolError(
                  toolName: 'test',
                  reason: 'failed with exit code 70.',
                  failureType: ToolFailureType.business,
                  failureReason: ToolFailureReason.testFailure,
                  capturedOutput: 'output',
                  testRun: testRun,
                ).toCallToolResult().content.first
                as TextContent)
            .text,
      ) as Map<String, Object?>;

      test('is omitted without a test run', () {
        final payload = jsonDecode(
          (const StructuredToolError(
                    toolName: 'create',
                    reason: 'boom',
                    failureType: ToolFailureType.business,
                    failureReason: ToolFailureReason.toolCrash,
                  ).toCallToolResult().content.first
                  as TextContent)
              .text,
        ) as Map<String, Object?>;

        expect(payload.containsKey('test'), isFalse);
      });

      test('is omitted when the test run has no results', () {
        expect(payloadOf(TestRunRecorder()).containsKey('test'), isFalse);
      });

      test('reports the results of the test run', () {
        final payload = payloadOf(
          TestRunRecorder()
            ..passed = 3
            ..skipped = 1
            ..durationMs = 1500
            ..failingTests.add((
              file: 'test/a_test.dart',
              name: 'a fails',
              error: 'boom',
            )),
        );

        expect(
          payload.keys,
          equals([
            'status',
            'failureType',
            'failureReason',
            'attemptedAction',
            'reason',
            'test',
            'partialResults',
            'alternativeApproaches',
          ]),
        );
        expect(
          payload['test'],
          equals({
            'results': {
              'passed': 3,
              'failed': 1,
              'skipped': 1,
              'durationMs': 1500,
              'failingTests': [
                {
                  'file': 'test/a_test.dart',
                  'name': 'a fails',
                  'error': 'boom',
                },
              ],
              'failingTestsTruncated': false,
            },
          }),
        );
      });

      test('keeps the first 20 failing tests', () {
        final testRun = TestRunRecorder();
        for (var i = 0; i < 21; i++) {
          testRun.failingTests.add((
            file: 'test/a_test.dart',
            name: '$i',
            error: '',
          ));
        }

        final results =
            (payloadOf(testRun)['test']! as Map<String, Object?>)['results']!
                as Map<String, Object?>;

        expect(results['failed'], equals(21));
        expect([
          for (final test in results['failingTests']! as List<Object?>)
            (test! as Map<String, Object?>)['name'],
        ], equals([for (var i = 0; i < 20; i++) '$i']));
        expect(results['failingTestsTruncated'], isTrue);
      });
    });

    test('omits arguments key when attemptedArguments is empty', () {
      final result = const StructuredToolError(
        toolName: 'test',
        reason: 'oops',
        failureType: ToolFailureType.business,
        failureReason: ToolFailureReason.toolCrash,
        attemptedArguments: {},
      ).toCallToolResult();
      final payload = jsonDecode(
        (result.content.first as TextContent).text,
      ) as Map<String, Object?>;
      final action = payload['attemptedAction']! as Map<String, Object?>;
      expect(action.containsKey('arguments'), isFalse);
    });
  });
}
