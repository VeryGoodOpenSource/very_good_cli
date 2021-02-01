import 'dart:io';

import 'package:io/ansi.dart';
import 'package:io/io.dart';
import 'package:mason/mason.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:very_good_cli/src/command_runner.dart';
import 'package:very_good_cli/src/commands/create.dart';

class MockLogger extends Mock implements Logger {}

void main() {
  group('Create', () {
    Logger logger;
    VeryGoodCommandRunner commandRunner;

    setUp(() {
      logger = MockLogger();
      when(logger.progress(any)).thenReturn((_) {});
      commandRunner = VeryGoodCommandRunner(logger: logger);
    });

    test('can be instantiated without an explicit Logger instance', () {
      final command = CreateCommand();
      expect(command, isNotNull);
    });

    test(
        'throws UsageException when --project-name is missing '
        'and directory base is not a valid package name', () async {
      const expectedErrorMessage = '".tmp" is not a valid package name.\n\n'
          'See https://dart.dev/tools/pub/pubspec#name for more information.';
      final result = await commandRunner.run(['create', '.tmp']);
      expect(result, equals(ExitCode.usage.code));
      verify(logger.err(expectedErrorMessage)).called(1);
    });

    test('throws UsageException when --project-name is invalid', () async {
      const expectedErrorMessage = '"My App" is not a valid package name.\n\n'
          'See https://dart.dev/tools/pub/pubspec#name for more information.';
      final result = await commandRunner.run(
        ['create', '.', '--project-name', 'My App'],
      );
      expect(result, equals(ExitCode.usage.code));
      verify(logger.err(expectedErrorMessage)).called(1);
    });

    test('throws UsageException when output directory is missing', () async {
      const expectedErrorMessage =
          'No option specified for the output directory.';
      final result = await commandRunner.run(['create']);
      expect(result, equals(ExitCode.usage.code));
      verify(logger.err(expectedErrorMessage)).called(1);
    });

    test('throws UsageException when multiple output directories are provided',
        () async {
      const expectedErrorMessage = 'Multiple output directories specified.';
      final result = await commandRunner.run(['create', './a', './b']);
      expect(result, equals(ExitCode.usage.code));
      verify(logger.err(expectedErrorMessage)).called(1);
    });

    test('completes successfully with correct output', () async {
      final result = await commandRunner.run(
        ['create', '.tmp', '--project-name', 'my_app'],
      );
      expect(result, equals(ExitCode.success.code));
      verify(logger.progress('Bootstrapping')).called(1);
      verify(logger.info(
        '${lightGreen.wrap('✓')} '
        'Generated 62 file(s):',
      ));
      verify(logger.alert('Created a Very Good App! 🦄')).called(1);
      expect(
        Future.wait([
          _Cmd.run('flutter', ['analyze'], processWorkingDir: '.tmp'),
          _Cmd.run('flutter', ['test'], processWorkingDir: '.tmp')
        ]),
        completes,
      );
    });
  });
}

class _Cmd {
  static Future<ProcessResult> run(
    String cmd,
    List<String> args, {
    bool throwOnError = true,
    String processWorkingDir,
  }) async {
    final result = await Process.run(cmd, args,
        workingDirectory: processWorkingDir, runInShell: true);

    if (throwOnError) {
      _throwIfProcessFailed(result, cmd, args);
    }
    return result;
  }

  static void _throwIfProcessFailed(
    ProcessResult pr,
    String process,
    List<String> args,
  ) {
    assert(pr != null);
    if (pr.exitCode != 0) {
      final values = {
        'Standard out': pr.stdout.toString().trim(),
        'Standard error': pr.stderr.toString().trim()
      }..removeWhere((k, v) => v.isEmpty);

      String message;
      if (values.isEmpty) {
        message = 'Unknown error';
      } else if (values.length == 1) {
        message = values.values.single;
      } else {
        message = values.entries.map((e) => '${e.key}\n${e.value}').join('\n');
      }

      throw ProcessException(process, args, message, pr.exitCode);
    }
  }
}
