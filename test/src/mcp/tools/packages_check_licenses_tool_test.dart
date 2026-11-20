import 'package:dart_mcp/server.dart';
import 'package:test/test.dart';
import 'package:very_good_cli/src/mcp/tools/tools.dart';

import '../../../helpers/helpers.dart';

void main() {
  group(PackagesCheckLicensesTool, () {
    late MockToolRunner runner;
    late PackagesCheckLicensesTool tool;

    setUp(() {
      runner = MockToolRunner();
      tool = PackagesCheckLicensesTool(runner);
      stubRun(runner);
    });

    Future<CallToolResult> call([Map<String, Object?> arguments = const {}]) =>
        tool.call(
          CallToolRequest(
            name: PackagesCheckLicensesTool.name,
            arguments: arguments,
          ),
        );

    test('is named packages_check_licenses and requires no argument', () {
      expect(tool.definition.name, equals('packages_check_licenses'));
      expect(tool.definition.inputSchema.required, isNull);
    });

    test('is annotated read-only, idempotent and closed-world', () {
      final annotations = tool.definition.toolAnnotations!;
      expect(annotations.readOnlyHint, isTrue);
      expect(annotations.idempotentHint, isTrue);
      expect(annotations.openWorldHint, isFalse);
    });

    test('checks the licenses of the current directory by default', () async {
      final result = await call();

      expect(result, equals(stubbedRunResult));
      final run = verifyRun(runner);
      expect(run.args, equals(['packages', 'check', 'licenses']));
      expect(run.toolName, equals('packages_check_licenses'));
      expect(run.directory, isNull);
      expect(run.requestArguments, isEmpty);
      expect(run.timeout, isNull);
    });

    test('forwards every argument', () async {
      const arguments = {
        'directory': 'packages/my_app',
        'ignore_retrieval_failures': true,
        'dependency_type': ['direct-main', 'transitive'],
        'allowed': ['MIT', 'BSD-3-Clause'],
        'forbidden': ['GPL-3.0-only'],
        'skip_packages': ['pkg1'],
      };

      await call(arguments);

      final run = verifyRun(runner);
      expect(
        run.args,
        equals([
          'packages',
          'check',
          'licenses',
          '--ignore-retrieval-failures',
          '--dependency-type',
          'direct-main',
          '--dependency-type',
          'transitive',
          '--allowed',
          'MIT',
          '--allowed',
          'BSD-3-Clause',
          '--forbidden',
          'GPL-3.0-only',
          '--skip-packages',
          'pkg1',
        ]),
      );
      expect(run.directory, equals('packages/my_app'));
      expect(run.requestArguments, equals(arguments));
    });

    test('rejects a dependency type it does not know', () async {
      final result = await call({
        'dependency_type': ['dev'],
      });

      expect(result.isError, isTrue);
      expect(result.structuredContent!['reason'], contains('"dev"'));
      verifyNoRun(runner);
    });
  });
}
