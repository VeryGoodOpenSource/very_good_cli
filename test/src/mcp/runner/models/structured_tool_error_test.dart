import 'dart:convert';

import 'package:dart_mcp/server.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:very_good_cli/src/cli/cli.dart';
import 'package:very_good_cli/src/mcp/runner/runner.dart';

void main() {
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
      Map<String, Object?> payloadOf({
        TestRunResults? testResults,
        MinCoverageNotMet? coverage,
        ToolFailureReason failureReason = ToolFailureReason.testFailure,
      }) => jsonDecode(
        (StructuredToolError(
                  toolName: 'test',
                  reason: 'failed with exit code 70.',
                  failureType: ToolFailureType.business,
                  failureReason: failureReason,
                  capturedOutput: 'output',
                  testResults: testResults,
                  coverage: coverage,
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
        expect(
          payloadOf(testResults: const TestRunResults()).containsKey('test'),
          isFalse,
        );
      });

      test('reports the results of the test run', () {
        final payload = payloadOf(
          testResults: const TestRunResults(
            passed: 3,
            skipped: 1,
            durationMs: 1500,
            failingTests: [
              (file: 'test/a_test.dart', name: 'a fails', error: 'boom'),
            ],
          ),
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
            },
          }),
        );
      });

      test('reports an unmet coverage threshold', () {
        final payload = payloadOf(
          testResults: const TestRunResults(passed: 1),
          coverage: MinCoverageNotMet(
            97.42,
            minCoverage: 100,
            uncoveredLines: const {
              'lib/src/foo.dart': [12, 13, 40],
            },
            packageRoot: p.join('packages', 'foo'),
          ),
          failureReason: ToolFailureReason.coverageBelowThreshold,
        );
        expect(
          (payload['test']! as Map<String, Object?>)['coverage'],
          equals({
            'actual': 97.42,
            'required': 100,
            'uncoveredLines': [
              {
                'file': p.join('packages', 'foo', 'lib', 'src', 'foo.dart'),
                'lines': [12, 13, 40],
              },
            ],
            'uncoveredLinesTruncated': false,
          }),
        );
      });

      test('omits coverage when no coverage is provided', () {
        final payload = payloadOf(testResults: const TestRunResults(passed: 1));
        expect(
          (payload['test']! as Map<String, Object?>).containsKey('coverage'),
          isFalse,
        );
      });

      test('keeps the first 20 lines of the first 20 files', () {
        List<int> lines(int count) => [for (var i = 1; i <= count; i++) i];

        Map<String, Object?> coverageOf(MinCoverageNotMet coverage) =>
            (payloadOf(
                      coverage: coverage,
                      failureReason: ToolFailureReason.coverageBelowThreshold,
                    )['test']!
                    as Map<String, Object?>)['coverage']!
                as Map<String, Object?>;

        final manyFiles = coverageOf(
          MinCoverageNotMet(
            50,
            minCoverage: 100,
            uncoveredLines: {
              for (var i = 0; i < 21; i++) 'lib/$i.dart': [1],
            },
          ),
        );
        final manyLines = coverageOf(
          MinCoverageNotMet(
            50,
            minCoverage: 100,
            uncoveredLines: {'lib/a.dart': lines(21)},
          ),
        );
        final atTheCaps = coverageOf(
          MinCoverageNotMet(
            50,
            minCoverage: 100,
            uncoveredLines: {
              for (var i = 0; i < 20; i++) 'lib/$i.dart': lines(20),
            },
          ),
        );

        expect(manyFiles['uncoveredLines'], hasLength(20));
        expect(manyFiles['uncoveredLinesTruncated'], isTrue);
        expect(
          manyLines['uncoveredLines'],
          equals([
            {'file': p.join('lib', 'a.dart'), 'lines': lines(20)},
          ]),
        );
        expect(manyLines['uncoveredLinesTruncated'], isTrue);
        expect(atTheCaps['uncoveredLines'], hasLength(20));
        expect(atTheCaps['uncoveredLinesTruncated'], isFalse);
      });

      test('keeps the first 20 failing tests', () {
        final payload = payloadOf(
          testResults: TestRunResults(
            failingTests: [
              for (var i = 0; i < 21; i++)
                (file: 'test/a_test.dart', name: '$i', error: ''),
            ],
          ),
        );

        final results =
            (payload['test']! as Map<String, Object?>)['results']!
                as Map<String, Object?>;

        expect(results['failed'], equals(21));
        expect([
          for (final test in results['failingTests']! as List<Object?>)
            (test! as Map<String, Object?>)['name'],
        ], equals([for (var i = 0; i < 20; i++) '$i']));
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

    test('returns the payload as structured content', () {
      const error = StructuredToolError(
        toolName: 'test',
        reason: 'boom',
        failureType: ToolFailureType.business,
        failureReason: ToolFailureReason.testFailure,
        capturedOutput: 'output',
      );

      final result = error.toCallToolResult();

      expect(result.structuredContent, equals(error.toJson()));
      expect(toolOutputSchema.validate(result.structuredContent), isEmpty);
    });
  });
}
