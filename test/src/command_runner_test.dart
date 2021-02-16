// ignore_for_file: no_adjacent_strings_in_list
import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:io/io.dart';
import 'package:mason/mason.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:usage/usage_io.dart';
import 'package:very_good_cli/src/command_runner.dart';
import 'package:very_good_cli/src/version.dart';

class MockAnalytics extends Mock implements Analytics {}

class MockLogger extends Mock implements Logger {}

void main() {
  group('VeryGoodCommandRunner', () {
    List<String> printLogs;
    Analytics analytics;
    Logger logger;
    VeryGoodCommandRunner commandRunner;

    void Function() overridePrint(void Function() fn) {
      return () {
        final spec = ZoneSpecification(print: (_, __, ___, String msg) {
          printLogs.add(msg);
        });
        return Zone.current.fork(specification: spec).run<void>(fn);
      };
    }

    setUp(() {
      printLogs = [];

      analytics = MockAnalytics();
      when(analytics.firstRun).thenReturn(false);
      when(analytics.enabled).thenReturn(false);

      logger = MockLogger();
      commandRunner = VeryGoodCommandRunner(
        analytics: analytics,
        logger: logger,
      );
    });

    test('can be instantiated without an explicit analytics/logger instance',
        () {
      final commandRunner = VeryGoodCommandRunner();
      expect(commandRunner, isNotNull);
    });

    group('run', () {
      test('prompts for analytics collection on first run (y)', () async {
        when(analytics.firstRun).thenReturn(true);
        when(logger.prompt(any)).thenReturn('y');
        final result = await commandRunner.run(['--version']);
        expect(result, equals(ExitCode.success.code));
        verify(analytics.enabled = true);
      });

      test('prompts for analytics collection on first run (n)', () async {
        when(analytics.firstRun).thenReturn(true);
        when(logger.prompt(any)).thenReturn('n');
        final result = await commandRunner.run(['--version']);
        expect(result, equals(ExitCode.success.code));
        verify(analytics.enabled = false);
      });

      test('handles FormatException', () async {
        const exception = FormatException('oops!');
        var isFirstInvocation = true;
        when(logger.info(any)).thenAnswer((_) {
          if (isFirstInvocation) {
            isFirstInvocation = false;
            throw exception;
          }
        });
        final result = await commandRunner.run(['--version']);
        expect(result, equals(ExitCode.usage.code));
        verify(logger.err(exception.message)).called(1);
        verify(logger.info(commandRunner.usage)).called(1);
      });

      test('handles UsageException', () async {
        final exception = UsageException('oops!', commandRunner.usage);
        var isFirstInvocation = true;
        when(logger.info(any)).thenAnswer((_) {
          if (isFirstInvocation) {
            isFirstInvocation = false;
            throw exception;
          }
        });
        final result = await commandRunner.run(['--version']);
        expect(result, equals(ExitCode.usage.code));
        verify(logger.err(exception.message)).called(1);
        verify(logger.info(commandRunner.usage)).called(1);
      });

      test('handles no command', overridePrint(() async {
        const expectedPrintLogs = [
          '🦄 A Very Good Command Line Interface\n'
              '\n'
              'Usage: very_good <command> [arguments]\n'
              '\n'
              'Global options:\n'
              '-h, --help         Print this usage information.\n'
              '    --version      Print the current version.\n'
              '''    --analytics    Opt into or out of anonymous usage statistics.\n'''
              '\n'
              'Available commands:\n'
              '''  create   Creates a new very good flutter application in seconds.\n'''
              '\n'
              '''Run "very_good help <command>" for more information about a command.'''
        ];
        final result = await commandRunner.run([]);
        expect(printLogs, equals(expectedPrintLogs));
        expect(result, equals(ExitCode.success.code));
      }));

      group('--help', () {
        test('outputs usage', overridePrint(() async {
          const expectedPrintLogs = [
            '🦄 A Very Good Command Line Interface\n'
                '\n'
                'Usage: very_good <command> [arguments]\n'
                '\n'
                'Global options:\n'
                '-h, --help         Print this usage information.\n'
                '    --version      Print the current version.\n'
                '''    --analytics    Opt into or out of anonymous usage statistics.\n'''
                '\n'
                'Available commands:\n'
                '''  create   Creates a new very good flutter application in seconds.\n'''
                '\n'
                '''Run "very_good help <command>" for more information about a command.'''
          ];
          final result = await commandRunner.run(['--help']);
          expect(printLogs, equals(expectedPrintLogs));
          expect(result, equals(ExitCode.success.code));

          printLogs.clear();

          final resultAbbr = await commandRunner.run(['-h']);
          expect(printLogs, equals(expectedPrintLogs));
          expect(resultAbbr, equals(ExitCode.success.code));
        }));
      });

      group('--analytics', () {
        test('sets analytics.enabled to true', () async {
          final result = await commandRunner.run(['--analytics', 'true']);
          expect(result, equals(ExitCode.success.code));
          verify(analytics.enabled = true);
        });

        test('sets analytics.enabled to false', () async {
          final result = await commandRunner.run(['--analytics', 'false']);
          expect(result, equals(ExitCode.success.code));
          verify(analytics.enabled = false);
        });

        test('sets analytics.enabled to false (garbage value)', () async {
          final result = await commandRunner.run(['--analytics', 'garbage']);
          expect(result, equals(ExitCode.success.code));
          verify(analytics.enabled = false);
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
          verify(logger.info('very_good version: $packageVersion'));
        });
      });
    });
  });
}
