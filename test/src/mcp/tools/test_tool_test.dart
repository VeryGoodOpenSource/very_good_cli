import 'package:dart_mcp/server.dart';
import 'package:test/test.dart';
import 'package:very_good_cli/src/mcp/tools/tools.dart';

import '../../../helpers/helpers.dart';

void main() {
  group(TestTool, () {
    late MockToolRunner runner;
    late TestTool tool;

    setUp(() {
      runner = MockToolRunner();
      tool = TestTool(runner);
      stubRun(runner);
    });

    Future<CallToolResult> call([Map<String, Object?> arguments = const {}]) =>
        tool.call(CallToolRequest(name: TestTool.name, arguments: arguments));

    test('is named test and requires no argument', () {
      expect(tool.definition.name, equals('test'));
      expect(tool.definition.inputSchema.required, isNull);
    });

    test('is annotated as a repeatable, closed-world write', () {
      final annotations = tool.definition.toolAnnotations!;
      expect(annotations.readOnlyHint, isFalse);
      expect(annotations.destructiveHint, isFalse);
      expect(annotations.idempotentHint, isTrue);
      expect(annotations.openWorldHint, isFalse);
    });

    test('runs the Flutter tests without any flag by default', () async {
      final result = await call();

      expect(result, equals(stubbedRunResult));
      final run = verifyRun(runner);
      expect(run.args, equals(['test']));
      expect(run.toolName, equals('test'));
      expect(run.directory, isNull);
      expect(run.requestArguments, isEmpty);
      expect(run.timeout, isNull);
    });

    test('runs without arguments when the request has none', () async {
      await tool.call(CallToolRequest(name: TestTool.name));

      expect(verifyRun(runner).args, equals(['test']));
    });

    test('forwards every argument', () async {
      await call({
        'dart': true,
        'coverage': true,
        'recursive': true,
        'workspace': true,
        'optimization': true,
        'exclude_optimization': ['test/integration/**', 'test/e2e/**'],
        'concurrency': 8,
        'tags': 'a,b',
        'exclude_coverage': '**/*.g.dart',
        'collect_coverage_from': 'all',
        'report_on': ['lib/src', 'lib/other'],
        'exclude_tags': 'c,d',
        'min_coverage': 90,
        'test_randomize_ordering_seed': '123',
        'update_goldens': true,
        'fail_fast': true,
        'flavor': 'development',
        'file_reporter': 'json:reports/tests.json',
        'shard_index': 1,
        'total_shards': 3,
        'dart_define': ['foo=bar', 'baz=qux'],
        'dart_define_from_file': ['my_file.json'],
        'platform': 'chrome',
        'run_skipped': true,
        'check_ignore': true,
        'show_uncovered': true,
      });

      expect(
        verifyRun(runner).args,
        equals([
          'dart',
          'test',
          '--coverage',
          '-r',
          '--workspace',
          '--optimization',
          '--exclude-optimization',
          'test/integration/**',
          '--exclude-optimization',
          'test/e2e/**',
          '-j',
          '8',
          '-t',
          'a,b',
          '--exclude-coverage',
          '**/*.g.dart',
          '--collect-coverage-from',
          'all',
          '--report-on',
          'lib/src',
          '--report-on',
          'lib/other',
          '-x',
          'c,d',
          '--min-coverage',
          '90',
          '--test-randomize-ordering-seed',
          '123',
          '--update-goldens',
          '--fail-fast',
          '--flavor',
          'development',
          '--file-reporter',
          'json:reports/tests.json',
          '--shard-index',
          '1',
          '--total-shards',
          '3',
          '--dart-define',
          'foo=bar',
          '--dart-define',
          'baz=qux',
          '--dart-define-from-file',
          'my_file.json',
          '--platform',
          'chrome',
          '--run-skipped',
          '--check-ignore',
          '--show-uncovered',
        ]),
      );
    });

    test('passes --no-optimization when optimization is false', () async {
      await call({'optimization': false});

      expect(verifyRun(runner).args, equals(['test', '--no-optimization']));
    });

    group('directory', () {
      test('is the working directory, not a positional argument', () async {
        await call({'directory': 'packages/my_app'});

        final run = verifyRun(runner);
        expect(run.args, equals(['test']));
        expect(run.directory, equals('packages/my_app'));
      });

      test('is the working directory of a Dart run too', () async {
        await call({'directory': 'packages/my_cli', 'dart': true});

        final run = verifyRun(runner);
        expect(run.args, equals(['dart', 'test']));
        expect(run.directory, equals('packages/my_cli'));
      });
    });

    group('timeout_seconds', () {
      test('is the budget of the run, not a flag', () async {
        // The runner enforces the budget: `dart test` would reject the flag
        // and `flutter test`'s per-test `--timeout` does not fire for a hang
        // in tester.runAsync.
        await call({'timeout_seconds': 120});

        final run = verifyRun(runner);
        expect(run.args, equals(['test']));
        expect(run.timeout, equals(const Duration(seconds: 120)));
      });

      test('must be at least one second', () async {
        final result = await call({'timeout_seconds': 0});

        expect(result.isError, isTrue);
        verifyNoRun(runner);
      });
    });

    group('paths', () {
      test('are positional test targets behind `--`', () async {
        await call({
          'paths': ['test/src/foo_test.dart', 'test/widgets'],
        });

        expect(
          verifyRun(runner).args,
          equals(['test', '--', 'test/src/foo_test.dart', 'test/widgets']),
        );
      });

      test('go after the options so they are parsed as rest', () async {
        await call({
          'dart': true,
          'concurrency': 8,
          'paths': ['test/src/foo_test.dart'],
        });

        expect(
          verifyRun(runner).args,
          equals(['dart', 'test', '-j', '8', '--', 'test/src/foo_test.dart']),
        );
      });

      test('pass a path beginning with `-` through unparsed', () async {
        await call({
          'paths': ['-weird_test.dart'],
        });

        expect(
          verifyRun(runner).args,
          equals(['test', '--', '-weird_test.dart']),
        );
      });

      test('add no positional target when empty', () async {
        await call({'paths': <String>[]});

        expect(verifyRun(runner).args, equals(['test']));
      });
    });

    group('check_ignore', () {
      test('is rejected when true without dart', () async {
        // `--check-ignore` is only defined by `very_good dart test`.
        // Forwarding it to `very_good test` (Flutter) exits with 64, so the
        // tool rejects the combination before running anything.
        const arguments = {'check_ignore': true};

        final result = await call(arguments);

        expect(result.isError, isTrue);
        final payload = result.structuredContent!;
        expect(payload['failureType'], equals('validation'));
        expect(payload['failureReason'], equals('invalid_input'));
        expect(payload['reason'], contains('check_ignore'));
        expect(payload['reason'], contains('"dart": true'));
        expect(
          payload['attemptedAction'],
          equals({'tool': 'test', 'arguments': arguments}),
        );
        verifyNoRun(runner);
      });

      test('is rejected when true with dart false', () async {
        final result = await call({'check_ignore': true, 'dart': false});

        expect(result.isError, isTrue);
        expect(result.structuredContent!['failureType'], equals('validation'));
        verifyNoRun(runner);
      });

      test('is ignored when false on Flutter tests', () async {
        await call({'check_ignore': false});

        expect(verifyRun(runner).args, equals(['test']));
      });

      test('passes --no-check-ignore when false on Dart tests', () async {
        await call({'dart': true, 'check_ignore': false});

        expect(
          verifyRun(runner).args,
          equals(['dart', 'test', '--no-check-ignore']),
        );
      });
    });

    group('sharding', () {
      test('forwards the shard as integers', () async {
        await call({'shard_index': 2, 'total_shards': 4});

        expect(
          verifyRun(runner).args,
          equals(['test', '--shard-index', '2', '--total-shards', '4']),
        );
      });

      test('rejects a shard index below one', () async {
        final result = await call({'shard_index': 0, 'total_shards': 4});

        expect(result.isError, isTrue);
        expect(result.structuredContent!['reason'], contains('shard_index'));
        verifyNoRun(runner);
      });

      test('rejects a shard count below one', () async {
        final result = await call({'shard_index': 1, 'total_shards': 0});

        expect(result.isError, isTrue);
        expect(result.structuredContent!['reason'], contains('total_shards'));
        verifyNoRun(runner);
      });
    });

    group('collect_coverage_from', () {
      test('forwards imports', () async {
        await call({'collect_coverage_from': 'imports'});

        expect(
          verifyRun(runner).args,
          equals(['test', '--collect-coverage-from', 'imports']),
        );
      });

      test('rejects a mode it does not know', () async {
        final result = await call({'collect_coverage_from': 'none'});

        expect(result.isError, isTrue);
        expect(
          result.structuredContent!['reason'],
          contains('"none" is not one of the allowed values'),
        );
        verifyNoRun(runner);
      });
    });

    test('forwards fail_fast to both runners', () async {
      await call({'fail_fast': true});
      expect(verifyRun(runner).args, equals(['test', '--fail-fast']));

      await call({'dart': true, 'fail_fast': true});
      expect(verifyRun(runner).args, equals(['dart', 'test', '--fail-fast']));
    });

    test('adds no option for an empty list argument', () async {
      await call({'exclude_optimization': <String>[], 'report_on': <String>[]});

      expect(verifyRun(runner).args, equals(['test']));
    });

    test('rejects arguments that do not match the schema', () async {
      final result = await call({
        'force_ansi': true,
        'concurrency': '4',
        'platform': 'firefox',
      });

      expect(result.isError, isTrue);
      final payload = result.structuredContent!;
      expect(payload['failureType'], equals('validation'));
      expect(payload['failureReason'], equals('invalid_input'));
      expect(
        payload['reason'],
        allOf(
          startsWith('Invalid arguments: '),
          contains('Additional property "force_ansi" is not allowed'),
          contains('#root["concurrency"]'),
          contains('"firefox" is not one of the allowed values'),
        ),
      );
      verifyNoRun(runner);
    });
  });
}
