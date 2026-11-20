import 'package:dart_mcp/server.dart';
import 'package:test/test.dart';
import 'package:very_good_cli/src/mcp/tools/tools.dart';

import '../../../helpers/helpers.dart';

void main() {
  group(PackagesGetTool, () {
    late MockToolRunner runner;
    late PackagesGetTool tool;

    setUp(() {
      runner = MockToolRunner();
      tool = PackagesGetTool(runner);
      stubRun(runner);
    });

    Future<CallToolResult> call([Map<String, Object?> arguments = const {}]) =>
        tool.call(
          CallToolRequest(name: PackagesGetTool.name, arguments: arguments),
        );

    test('is named packages_get and requires no argument', () {
      expect(tool.definition.name, equals('packages_get'));
      expect(tool.definition.inputSchema.required, isNull);
    });

    test('is annotated as a repeatable, open-world write', () {
      final annotations = tool.definition.toolAnnotations!;
      expect(annotations.readOnlyHint, isFalse);
      expect(annotations.destructiveHint, isFalse);
      expect(annotations.idempotentHint, isTrue);
      expect(annotations.openWorldHint, isTrue);
    });

    test('gets the packages of the current directory by default', () async {
      final result = await call();

      expect(result, equals(stubbedRunResult));
      final run = verifyRun(runner);
      expect(run.args, equals(['packages', 'get']));
      expect(run.toolName, equals('packages_get'));
      expect(run.directory, isNull);
      expect(run.requestArguments, isEmpty);
      expect(run.timeout, isNull);
    });

    test('forwards every argument', () async {
      const arguments = {
        'directory': 'packages/my_app',
        'recursive': true,
        'ignore': ['pkg1', 'pkg2'],
      };

      await call(arguments);

      final run = verifyRun(runner);
      expect(
        run.args,
        equals([
          'packages',
          'get',
          '--recursive',
          '--ignore',
          'pkg1',
          '--ignore',
          'pkg2',
        ]),
      );
      expect(run.directory, equals('packages/my_app'));
      expect(run.requestArguments, equals(arguments));
    });

    test('rejects a comma-separated ignore string', () async {
      final result = await call({'ignore': 'pkg1,pkg2'});

      expect(result.isError, isTrue);
      expect(
        result.structuredContent!['failureReason'],
        equals('invalid_input'),
      );
      verifyNoRun(runner);
    });
  });
}
