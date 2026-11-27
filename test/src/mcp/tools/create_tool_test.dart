import 'dart:io';

import 'package:dart_mcp/server.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:very_good_cli/src/mcp/tools/tools.dart';

import '../../../helpers/helpers.dart';

void main() {
  group(CreateTool, () {
    late MockToolRunner runner;
    late CreateTool tool;
    // Stands in for the directory the server was started in, so the tests
    // control what already exists where a project would be generated.
    late Directory startDirectory;

    setUp(() {
      startDirectory = Directory.systemTemp.createTempSync('vgmcp_create_');
      addTearDown(() => startDirectory.deleteSync(recursive: true));
      runner = MockToolRunner();
      when(() => runner.startDirectory).thenReturn(startDirectory.path);
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

    group('when the project folder already exists', () {
      /// Creates `<startDirectory>/[relativePath]` holding one file, as a
      /// previously generated project would.
      Directory existingProject(String relativePath) {
        final directory = Directory(
          path.join(startDirectory.path, relativePath),
        )..createSync(recursive: true);
        File(path.join(directory.path, 'README.md')).writeAsStringSync('#');
        return directory;
      }

      void expectRefused(CallToolResult result, Directory directory) {
        expect(result.isError, isTrue);
        final payload = result.structuredContent!;
        expect(payload['status'], equals('failure'));
        expect(payload['failureType'], equals('validation'));
        expect(payload['failureReason'], equals('invalid_input'));
        expect(
          payload['reason'],
          equals(
            'Project directory "${directory.path}" already exists and is '
            'not empty. Pick another "output_directory" or "name", or '
            'remove the existing project before retrying.',
          ),
        );
        verifyNoRun(runner);
      }

      test('refuses to create over it in the start directory', () async {
        final existing = existingProject('my_app');
        const arguments = {'subcommand': 'flutter_app', 'name': 'my_app'};

        final result = await call(arguments);

        expectRefused(result, existing);
        expect(
          result.structuredContent!['attemptedAction'],
          equals({'tool': 'create', 'arguments': arguments}),
        );
      });

      test(
        'refuses to create over it in a relative output_directory',
        () async {
          final existing = existingProject(path.join('out', 'my_docs'));

          final result = await call({
            'subcommand': 'docs_site',
            'name': 'my_docs',
            'output_directory': 'out',
          });

          expectRefused(result, existing);
        },
      );

      test(
        'refuses to create over it in an absolute output_directory',
        () async {
          final existing = existingProject(path.join('out', 'my_docs'));

          final result = await call({
            'subcommand': 'docs_site',
            'name': 'my_docs',
            'output_directory': path.join(startDirectory.path, 'out'),
          });

          expectRefused(result, existing);
        },
      );

      test('still creates into it when it is empty', () async {
        Directory(path.join(startDirectory.path, 'my_app')).createSync();

        final result = await call({
          'subcommand': 'flutter_app',
          'name': 'my_app',
        });

        expect(result, equals(stubbedRunResult));
        expect(
          verifyRun(runner).args,
          equals(['create', 'flutter_app', 'my_app']),
        );
      });

      test('does not resolve a relative output_directory against the current '
          'directory', () async {
        // Another run may have switched the process working directory; the
        // check must follow the directory the server was started in.
        final elsewhere = Directory.systemTemp.createTempSync('vgmcp_cwd_');
        final originalCwd = Directory.current;
        addTearDown(() {
          Directory.current = originalCwd;
          elsewhere.deleteSync(recursive: true);
        });
        Directory(path.join(elsewhere.path, 'out', 'my_docs'))
            .createSync(recursive: true);
        File(path.join(elsewhere.path, 'out', 'my_docs', 'README.md'))
            .writeAsStringSync('#');
        Directory.current = elsewhere;

        final result = await call({
          'subcommand': 'docs_site',
          'name': 'my_docs',
          'output_directory': 'out',
        });

        expect(result, equals(stubbedRunResult));
        verifyRun(runner);
      });
    });
  });
}
