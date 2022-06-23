// ignore_for_file: no_adjacent_strings_in_list
import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:mason/mason.dart' hide packageVersion;
import 'package:mocktail/mocktail.dart';
import 'package:pub_updater/pub_updater.dart';
import 'package:test/test.dart';
import 'package:usage/usage_io.dart';
import 'package:very_good_cli/src/command_runner.dart';
import 'package:very_good_cli/src/version.dart';

class MockAnalytics extends Mock implements Analytics {}

class MockLogger extends Mock implements Logger {}

class MockPubUpdater extends Mock implements PubUpdater {}

const expectedUsage = [
  '🦄 A Very Good Command Line Interface\n'
      '\n'
      'Usage: very_good <command> [arguments]\n'
      '\n'
      'Global options:\n'
      '-h, --help           Print this usage information.\n'
      '    --version        Print the current version.\n'
      '    --analytics      Toggle anonymous usage statistics.\n'
      '\n'
      '          [false]    Disable anonymous usage statistics\n'
      '          [true]     Enable anonymous usage statistics\n'
      '\n'
      'Available commands:\n'
      '  create     very_good create <output directory>\n'
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
Run ${lightCyan.wrap('dart pub global activate very_good_cli')} to update''';

void main() {
  group('VeryGoodCommandRunner', () {
    late List<String> printLogs;
    late Analytics analytics;
    late PubUpdater pubUpdater;
    late Logger logger;
    late VeryGoodCommandRunner commandRunner;

    void Function() overridePrint(void Function() fn) {
      return () {
        final spec = ZoneSpecification(
          print: (_, __, ___, String msg) {
            printLogs.add(msg);
          },
        );
        return Zone.current.fork(specification: spec).run<void>(fn);
      };
    }

    setUp(() {
      printLogs = [];

      analytics = MockAnalytics();
      pubUpdater = MockPubUpdater();

      when(() => analytics.firstRun).thenReturn(false);
      when(() => analytics.enabled).thenReturn(false);
      when(
        () => pubUpdater.getLatestVersion(any()),
      ).thenAnswer((_) async => packageVersion);

      logger = MockLogger();

      commandRunner = VeryGoodCommandRunner(
        analytics: analytics,
        logger: logger,
        pubUpdater: pubUpdater,
      );
    });

    test('can be instantiated without an explicit analytics/logger instance',
        () {
      final commandRunner = VeryGoodCommandRunner();
      expect(commandRunner, isNotNull);
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

      test('handles pub update errors gracefully', () async {
        when(
          () => pubUpdater.getLatestVersion(any()),
        ).thenThrow(Exception('oops'));

        final result = await commandRunner.run(['--version']);
        expect(result, equals(ExitCode.success.code));
        verifyNever(() => logger.info(updatePrompt));
      });

      test('prompts for analytics collection on first run (y)', () async {
        when(() => analytics.firstRun).thenReturn(true);
        when(() => logger.prompt(any())).thenReturn('y');
        final result = await commandRunner.run(['--version']);
        expect(result, equals(ExitCode.success.code));
        verify(() => analytics.enabled = true);
      });

      test('prompts for analytics collection on first run (n)', () async {
        when(() => analytics.firstRun).thenReturn(true);
        when(() => logger.prompt(any())).thenReturn('n');
        final result = await commandRunner.run(['--version']);
        expect(result, equals(ExitCode.success.code));
        verify(() => analytics.enabled = false);
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

      test(
        'handles no command',
        overridePrint(() async {
          final result = await commandRunner.run([]);
          expect(printLogs, equals(expectedUsage));
          expect(result, equals(ExitCode.success.code));
        }),
      );

      group('--help', () {
        test(
          'outputs usage',
          overridePrint(() async {
            final result = await commandRunner.run(['--help']);
            expect(printLogs, equals(expectedUsage));
            expect(result, equals(ExitCode.success.code));

            printLogs.clear();

            final resultAbbr = await commandRunner.run(['-h']);
            expect(printLogs, equals(expectedUsage));
            expect(resultAbbr, equals(ExitCode.success.code));
          }),
        );
      });

      group('--analytics', () {
        test('sets analytics.enabled to true', () async {
          final result = await commandRunner.run(['--analytics', 'true']);
          expect(result, equals(ExitCode.success.code));
          verify(() => analytics.enabled = true);
        });

        test('sets analytics.enabled to false', () async {
          final result = await commandRunner.run(['--analytics', 'false']);
          expect(result, equals(ExitCode.success.code));
          verify(() => analytics.enabled = false);
        });

        test('does not accept erroneous input', () async {
          final result = await commandRunner.run(['--analytics', 'garbage']);
          expect(result, equals(ExitCode.usage.code));
          verifyNever(() => analytics.enabled);
          verify(
            () => logger.err(
              '"garbage" is not an allowed value for option "analytics".',
            ),
          ).called(1);
        });

        test('exits with bad usage when missing value', () async {
          final result = await commandRunner.run(['--analytics']);
          expect(result, equals(ExitCode.usage.code));
        });
      });

      group('--version', () {
        test('outputs current version', () async {
          final result = await commandRunner.run(['--version']);
          expect(result, equals(ExitCode.success.code));
          verify(() => logger.info(packageVersion)).called(1);
        });
      });
    });
  });
}
