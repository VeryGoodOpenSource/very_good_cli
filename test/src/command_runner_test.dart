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

class _MockLogger extends Mock implements Logger {}

class _MockPubUpdater extends Mock implements PubUpdater {}

class _MockProgress extends Mock implements Progress {}

class _MockDirectory extends Mock implements Directory {}

class _MockFile extends Mock implements File {}

class _MockStdout extends Mock implements Stdout {}

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
      pubUpdater = _MockPubUpdater();

      when(
        () => pubUpdater.getLatestVersion(any()),
      ).thenAnswer((_) async => packageVersion);

      logger = _MockLogger();

      commandRunner = VeryGoodCommandRunner(
        logger: logger,
        pubUpdater: pubUpdater,
        environment: {'CI': 'true'},
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
          final progress = _MockProgress();
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

      group('_showThankYou', () {
        late Directory cliCache;
        late File versionFile;
        late Stdout stdout;

        setUp(() {
          cliCache = _MockDirectory();
          when(() => cliCache.path).thenReturn('/users/test');

          versionFile = _MockFile();
          when(() => versionFile.readAsStringSync()).thenReturn('0.0.0');

          stdout = _MockStdout();
          when(() => stdout.hasTerminal).thenReturn(true);
          when(() => stdout.supportsAnsiEscapes).thenReturn(true);
          when(() => stdout.terminalColumns).thenReturn(30);
        });

        test('shows message when version changed', () async {
          commandRunner.environmentOverride = {
            'HOME': '/users/test',
          };

          await IOOverrides.runZoned(
            () async {
              final result = await commandRunner.run([]);
              expect(result, equals(ExitCode.success.code));

              verifyInOrder([
                () => logger.info('\nThank you for using Very Good '),
                () => logger.info('Ventures open source '),
                () => logger.info("tools!\nDon't forget to fill "),
                () => logger.info('out this form to get '),
                () => logger.info('information on future updates '),
                () => logger.info('and releases here: '),
                () => logger.info(
                      any(
                        that: contains(
                          'https://verygood.ventures/open-source/cli/subscribe-latest-tool-updates',
                        ),
                      ),
                    ),
              ]);

              verify(
                () => versionFile.createSync(
                  recursive: any(that: isTrue, named: 'recursive'),
                ),
              ).called(1);
              verify(() => versionFile.readAsStringSync()).called(1);
              verify(
                () => versionFile
                    .writeAsStringSync(any(that: equals(packageVersion))),
              ).called(1);
            },
            createDirectory: (path) => cliCache,
            createFile: (path) => versionFile,
            stdout: () => stdout,
          );
        });

        test('cache inside XDG directory', () async {
          commandRunner.environmentOverride = {
            'HOME': '/users/test',
            'XDG_CONFIG_HOME': '/users/test/.xdg',
          };

          final xdgCache = _MockDirectory();
          when(() => xdgCache.path).thenReturn('/users/test/.xdg');

          await IOOverrides.runZoned(
            () async {
              final result = await commandRunner.run([]);
              expect(result, equals(ExitCode.success.code));

              verifyNever(() => cliCache.path);
              verify(() => xdgCache.path).called(1);
            },
            createDirectory: (path) =>
                path.contains('.xdg') ? xdgCache : cliCache,
            createFile: (path) => versionFile,
            stdout: () => stdout,
          );
        });

        test('cache inside local APP_DATA on windows', () async {
          commandRunner
            ..environmentOverride = {'LOCALAPPDATA': '/C/Users/test'}
            ..isWindowsOverride = true;

          final windowsCache = _MockDirectory();
          when(() => windowsCache.path).thenReturn('/C/Users/test');

          await IOOverrides.runZoned(
            () async {
              final result = await commandRunner.run([]);
              expect(result, equals(ExitCode.success.code));

              verifyNever(() => cliCache.path);
              verify(() => windowsCache.path).called(1);
            },
            createDirectory: (path) =>
                path.startsWith('/C/') ? windowsCache : cliCache,
            createFile: (path) => versionFile,
            stdout: () => stdout,
          );
        });
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
