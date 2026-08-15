// Expected usage of the plugin will need to be adjacent strings due to format
// and also be longer than 80 chars.
// ignore_for_file: no_adjacent_strings_in_list

import 'dart:io';

import 'package:mason/mason.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:universal_io/io.dart';
import 'package:very_good_cli/src/commands/workspace/commands/matrix.dart';
import 'package:very_good_cli/src/workspace_matrix/workspace_matrix.dart';

import '../../../../helpers/command_helper.dart';

class _MockLogger extends Mock implements Logger {}

const _expectedWorkspaceMatrixUsage = [
  'Return a JSON list of affected projects in the current workspace.\n'
      '\n'
      'Usage: very_good workspace matrix [arguments]\n'
      '-h, --help          Print this usage information.\n'
      '    --base=<ref>    Base git ref used for diffing changes (for example, origin/main).\n'
      '\n'
      'Run "very_good help" to see global options.',
];

void main() {
  group('workspace matrix', () {
    test(
      'help',
      withRunner((commandRunner, logger, pubUpdater, printLogs) async {
        final result = await commandRunner.run([
          'workspace',
          'matrix',
          '--help',
        ]);
        expect(printLogs, equals(_expectedWorkspaceMatrixUsage));
        expect(result, equals(ExitCode.success.code));

        printLogs.clear();

        final resultAbbr = await commandRunner.run([
          'workspace',
          'matrix',
          '-h',
        ]);
        expect(printLogs, equals(_expectedWorkspaceMatrixUsage));
        expect(resultAbbr, equals(ExitCode.success.code));
      }),
    );

    test(
      'returns usage exit code when --base is missing',
      withRunner((commandRunner, logger, pubUpdater, printLogs) async {
        final result = await commandRunner.run(['workspace', 'matrix']);

        expect(result, equals(ExitCode.usage.code));
      }),
    );

    test(
      'returns usage exit code when positional arguments are provided',
      withRunner((commandRunner, logger, pubUpdater, printLogs) async {
        final result = await commandRunner.run([
          'workspace',
          'matrix',
          '--base',
          'origin/main',
          'extra',
        ]);

        expect(result, equals(ExitCode.usage.code));
      }),
    );

    test('returns JSON encoded affected projects', () async {
      final logger = _MockLogger();
      when(() => logger.info(any())).thenReturn(null);
      when(() => logger.err(any())).thenReturn(null);

      final command = WorkspaceMatrixCommand(
        logger: logger,
        gitChangedFiles:
            ({required baseRef, required cwd, required logger}) async => [
              'packages/core/pubspec.yaml',
            ],
        resolveAffectedProjects:
            ({required rootDirectory, required changedFiles}) {
              return changedFiles.contains('packages/core/pubspec.yaml')
                  ? const [
                      WorkspaceProject(name: 'core', path: 'packages/core'),
                    ]
                  : const [];
            },
      );
      command.argResultOverrides = command.argParser.parse([
        '--base',
        'origin/main',
      ]);

      final result = await command.run();

      expect(result, equals(ExitCode.success.code));
      verify(
        () => logger.info('[{"name":"core","path":"packages/core"}]'),
      ).called(1);
    });

    test('returns unavailable when git diff fails', () async {
      final logger = _MockLogger();
      when(() => logger.info(any())).thenReturn(null);
      when(() => logger.err(any())).thenReturn(null);

      final command = WorkspaceMatrixCommand(
        logger: logger,
        gitChangedFiles:
            ({required baseRef, required cwd, required logger}) async {
              throw const ProcessException('git', ['diff']);
            },
      );
      command.argResultOverrides = command.argParser.parse([
        '--base',
        'origin/main',
      ]);

      final result = await command.run();

      expect(result, equals(ExitCode.unavailable.code));
      verify(
        () => logger.err(any(that: contains('ProcessException'))),
      ).called(1);
    });
  });
}
