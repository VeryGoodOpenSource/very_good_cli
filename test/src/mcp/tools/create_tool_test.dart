import 'package:dart_mcp/server.dart';
import 'package:test/test.dart';
import 'package:very_good_cli/src/mcp/tools/tools.dart';

import '../../../helpers/helpers.dart';

void main() {
  group(CreateTool, () {
    late MockToolRunner runner;
    late CreateTool tool;

    setUp(() {
      runner = MockToolRunner();
      tool = CreateTool(runner);
      stubRun(runner);
    });

    Future<CallToolResult> call(Map<String, Object?> arguments) =>
        tool.call(CallToolRequest(name: CreateTool.name, arguments: arguments));

    test('is named create and requires subcommand and name', () {
      expect(tool.definition.name, equals('create'));
      expect(
        tool.definition.inputSchema.required,
        equals(['subcommand', 'name']),
      );
    });

    test('is annotated as an additive, open-world write', () {
      final annotations = tool.definition.toolAnnotations!;
      expect(annotations.readOnlyHint, isFalse);
      expect(annotations.destructiveHint, isFalse);
      expect(annotations.idempotentHint, isFalse);
      expect(annotations.openWorldHint, isTrue);
    });

    test('creates a project from the subcommand and name', () async {
      const arguments = {'subcommand': 'flutter_app', 'name': 'my_app'};

      final result = await call(arguments);

      expect(result, equals(stubbedRunResult));
      final run = verifyRun(runner);
      expect(run.args, equals(['create', 'flutter_app', 'my_app']));
      expect(run.toolName, equals('create'));
      expect(run.directory, isNull);
      expect(run.requestArguments, equals(arguments));
      expect(run.timeout, isNull);
    });

    test('forwards every argument', () async {
      await call({
        'subcommand': 'flutter_app',
        'name': 'my_app',
        'description': 'my_desc',
        'org_name': 'com.test',
        'output_directory': 'my_dir',
        'application_id': 'com.test.my_app',
        'platforms': ['ios', 'web'],
        'publishable': true,
        'workspace': true,
        'executable_name': 'my_cli',
      });

      expect(
        verifyRun(runner).args,
        equals([
          'create',
          'flutter_app',
          'my_app',
          '--desc',
          'my_desc',
          '--org-name',
          'com.test',
          '-o',
          'my_dir',
          '--application-id',
          'com.test.my_app',
          '--platforms',
          'ios',
          '--platforms',
          'web',
          '--publishable',
          '--workspace',
          '--executable-name',
          'my_cli',
        ]),
      );
    });

    test('passes --no-workspace when workspace is false', () async {
      await call({
        'subcommand': 'dart_package',
        'name': 'my_pkg',
        'workspace': false,
      });

      expect(
        verifyRun(runner).args,
        equals(['create', 'dart_package', 'my_pkg', '--no-workspace']),
      );
    });

    test('does not forward workspace to docs_site', () async {
      await call({
        'subcommand': 'docs_site',
        'name': 'my_docs',
        'workspace': true,
      });

      expect(
        verifyRun(runner).args,
        equals(['create', 'docs_site', 'my_docs']),
      );
    });

    test('rejects a call without a name before running anything', () async {
      const arguments = {'subcommand': 'flutter_app'};

      final result = await call(arguments);

      expect(result.isError, isTrue);
      final payload = result.structuredContent!;
      expect(payload['failureType'], equals('validation'));
      expect(payload['failureReason'], equals('invalid_input'));
      expect(
        payload['reason'],
        contains('Required property "name" is missing at path #root'),
      );
      expect(
        payload['attemptedAction'],
        equals({'tool': 'create', 'arguments': arguments}),
      );
      verifyNoRun(runner);
    });

    test('rejects a platform it does not know', () async {
      final result = await call({
        'subcommand': 'flutter_app',
        'name': 'my_app',
        'platforms': ['fuchsia'],
      });

      expect(result.isError, isTrue);
      expect(result.structuredContent!['reason'], contains('"fuchsia"'));
      verifyNoRun(runner);
    });
  });
}
