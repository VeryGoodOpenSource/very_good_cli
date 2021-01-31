// ignore_for_file: no_adjacent_strings_in_list
import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:io/io.dart';
import 'package:mason/mason.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:very_good_cli/src/command_runner.dart';
import 'package:very_good_cli/src/version.dart';

class MockLogger extends Mock implements Logger {}

void main() {
  group('VeryGoodCommandRunner', () {
    List<String> printLogs;
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
      logger = MockLogger();
      commandRunner = VeryGoodCommandRunner(logger: logger);
    });

    test('can be instantiated without an explicit logger instance', () {
      final commandRunner = VeryGoodCommandRunner();
      expect(commandRunner, isNotNull);
    });

    group('run', () {
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
              '-h, --help       Print this usage information.\n'
              '    --version    Print the current version.\n'
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
                '-h, --help       Print this usage information.\n'
                '    --version    Print the current version.\n'
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
