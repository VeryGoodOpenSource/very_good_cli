import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:checked_yaml/checked_yaml.dart';
import 'package:mason/mason.dart';
import 'package:test/test.dart';
import 'package:very_good_cli/src/mcp/runner/runner.dart';
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

    group('fromError', () {
      test('classifies network and timeout exceptions as transient', () {
        for (final exception in <Exception>[
          const SocketException('connection refused'),
          const HttpException('bad gateway'),
          const TlsException('handshake failed'),
          TimeoutException('too slow'),
        ]) {
          expect(
            ToolFailureType.fromError(exception),
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
            ToolFailureType.fromError(exception),
            equals(ToolFailureType.validation),
            reason: '$exception',
          );
        }
      });

      test('classifies PathAccessException as permission', () {
        expect(
          ToolFailureType.fromError(
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
          ToolFailureType.fromError(
            const FileSystemException(
              'Cannot open file',
              '/disk',
              OSError('No space left on device', 28),
            ),
          ),
          equals(ToolFailureType.business),
        );
        expect(
          ToolFailureType.fromError(
            const FileSystemException(
              'Input/output error',
              '/disk',
              OSError('I/O error', 5),
            ),
          ),
          equals(ToolFailureType.business),
        );
        expect(
          ToolFailureType.fromError(
            const FileSystemException('Cannot open file', '/disk'),
          ),
          equals(ToolFailureType.business),
        );
      });

      test('classifies unknown exceptions as business', () {
        expect(
          ToolFailureType.fromError(Exception('Invalid SDK hash')),
          equals(ToolFailureType.business),
        );
      });

      test('classifies an error that is not an exception as business', () {
        expect(
          ToolFailureType.fromError(StateError('No terminal attached')),
          equals(ToolFailureType.business),
        );
        expect(
          ToolFailureType.fromError(ArgumentError('bad argument')),
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
}
