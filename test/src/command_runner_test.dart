// ignore_for_file: no_adjacent_strings_in_list
import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mason/mason.dart' hide packageVersion;
import 'package:mocktail/mocktail.dart';
import 'package:pub_updater/pub_updater.dart';
import 'package:test/test.dart';
import 'package:very_good_cli/src/command_runner.dart';
import 'package:very_good_cli/src/version.dart';

class MockLogger extends Mock implements Logger {}

class MockPubUpdater extends Mock implements PubUpdater {}

class MockProgress extends Mock implements Progress {}

const expectedUsage = [
  '🦄 A Very Good Command-Line Interface\n'
      '\n'
      'Usage: very_good <command> [arguments]\n'
      '\n'
      'Global options:\n'
      '-h, --help            Print this usage information.\n'
      '    --version         Print the current version.\n'
      '''    --[no-]verbose    Noisy logging, including all shell commands executed.\n'''
      '\n'
      'Available commands:\n'
      '  create     very_good create <subcommand> <project-name> [arguments]\n'
      '''             Creates a new very good project in the specified directory.\n'''
      '  packages   Command for managing packages.\n'
      '  test       Run tests in a Dart or Flutter project.\n'
      '  update     Update Very Good CLI.\n'
      '\n'
      'Run "very_good help <command>" for more information about a command.'
];

const responseBody =
    '{"name": "very_good_cli", "versions": ["0.4.0", "0.3.3"]}';

const latestVersion = '0.0.0';

final updatePrompt = '''
${lightYellow.wrap('Update available!')} ${lightCyan.wrap(packageVersion)} \u2192 ${lightCyan.wrap(latestVersion)}
${lightYellow.wrap('Changelog:')} ${lightCyan.wrap('https://github.com/verygoodopensource/very_good_cli/releases/tag/v$latestVersion')}
Run ${lightCyan.wrap('very_good update')} to update''';

void main() {
  final successProcessResult = ProcessResult(
    42,
    ExitCode.success.code,
    '',
    '',
  );

  group('VeryGoodCommandRunner', () {
    late PubUpdater pubUpdater;
    late Logger logger;
    late VeryGoodCommandRunner commandRunner;

    setUp(() {
      pubUpdater = MockPubUpdater();

      when(
        () => pubUpdater.getLatestVersion(any()),
      ).thenAnswer((_) async => packageVersion);

      logger = MockLogger();

      commandRunner = VeryGoodCommandRunner(
        logger: logger,
        pubUpdater: pubUpdater,
      );
    });

    test('can be instantiated without optional parameters', () {
      expect(VeryGoodCommandRunner.new, returnsNormally);
    });

    group('run', () {
      test('shows update message when newer version exists', () async {
        when(
          () => pubUpdater.getLatestVersion(any()),
        ).thenAnswer((_) async => latestVersion);

        final result = await commandRunner.run(['--version']);
        expect(result, equals(ExitCode.success.code));
        verify(() => logger.info(updatePrompt)).called(1);
      });

      test(
        'does not show update message when using the update command',
        () async {
          when(
            () => pubUpdater.getLatestVersion(any()),
          ).thenAnswer((_) async => latestVersion);
          when(
            () => pubUpdater.update(
              packageName: packageName,
              versionConstraint: latestVersion,
            ),
          ).thenAnswer((_) => Future.value(successProcessResult));
          when(
            () => pubUpdater.isUpToDate(
              packageName: any(named: 'packageName'),
              currentVersion: any(named: 'currentVersion'),
            ),
          ).thenAnswer((_) => Future.value(true));
          final progress = MockProgress();
          final progressLogs = <String>[];
          when(() => progress.complete(any())).thenAnswer((_) {
            final message = _.positionalArguments.elementAt(0) as String?;
            if (message != null) progressLogs.add(message);
          });
          when(() => logger.progress(any())).thenReturn(progress);

          final result = await commandRunner.run(['update']);
          expect(result, equals(ExitCode.success.code));
          verifyNever(() => logger.info(updatePrompt));
        },
      );

      test('handles pub update errors gracefully', () async {
        when(
          () => pubUpdater.getLatestVersion(any()),
        ).thenThrow(Exception('oops'));

        final result = await commandRunner.run(['--version']);
        expect(result, equals(ExitCode.success.code));
        verifyNever(() => logger.info(updatePrompt));
      });

      test('handles FormatException', () async {
        const exception = FormatException('oops!');
        var isFirstInvocation = true;
        when(() => logger.info(any())).thenAnswer((_) {
          if (isFirstInvocation) {
            isFirstInvocation = false;
            throw exception;
          }
        });
        final result = await commandRunner.run(['--version']);
        expect(result, equals(ExitCode.usage.code));
        verify(() => logger.err(exception.message)).called(1);
        verify(() => logger.info(commandRunner.usage)).called(1);
      });

      test('handles UsageException', () async {
        final exception = UsageException('oops!', 'exception usage');
        var isFirstInvocation = true;
        when(() => logger.info(any())).thenAnswer((_) {
          if (isFirstInvocation) {
            isFirstInvocation = false;
            throw exception;
          }
        });
        final result = await commandRunner.run(['--version']);
        expect(result, equals(ExitCode.usage.code));
        verify(() => logger.err(exception.message)).called(1);
        verify(() => logger.info('exception usage')).called(1);
      });

      test('handles no command', () async {
        final result = await commandRunner.run([]);
        verify(() => logger.info(expectedUsage.join())).called(1);
        expect(result, equals(ExitCode.success.code));
      });

      test('handles completion command', () async {
        final result = await commandRunner.run(['completion']);
        verifyNever(() => logger.info(any()));
        verifyNever(() => logger.err(any()));
        verifyNever(() => logger.warn(any()));
        verifyNever(() => logger.write(any()));
        verifyNever(() => logger.success(any()));
        verifyNever(() => logger.detail(any()));

        expect(result, equals(ExitCode.success.code));
      });

      group('--help', () {
        test('outputs usage', () async {
          final result = await commandRunner.run(['--help']);
          verify(() => logger.info(expectedUsage.join())).called(1);
          expect(result, equals(ExitCode.success.code));

          final resultAbbr = await commandRunner.run(['-h']);
          verify(() => logger.info(expectedUsage.join())).called(1);
          expect(resultAbbr, equals(ExitCode.success.code));
        });
      });

      group('--version', () {
        test('outputs current version', () async {
          final result = await commandRunner.run(['--version']);
          expect(result, equals(ExitCode.success.code));
          verify(() => logger.info(packageVersion)).called(1);
        });
      });

      group('--verbose', () {
        test('enables verbose logging', () async {
          final result = await commandRunner.run(['--verbose']);
          expect(result, equals(ExitCode.success.code));

          verify(() => logger.detail('Argument information:')).called(1);
          verify(() => logger.detail('  Top level options:')).called(1);
          verify(() => logger.detail('  - verbose: true')).called(1);
          verifyNever(() => logger.detail('    Command options:'));
        });

        test('enables verbose logging for sub commands', () async {
          final result = await commandRunner.run([
            '--verbose',
            'create',
            '--help',
          ]);
          expect(result, equals(ExitCode.success.code));

          verify(() => logger.detail('Argument information:')).called(1);
          verify(() => logger.detail('  Top level options:')).called(1);
          verify(() => logger.detail('  - verbose: true')).called(1);
          verify(() => logger.detail('  Command: create')).called(1);
          verify(() => logger.detail('    - help: true')).called(1);
        });
      });
    });
  });
}
