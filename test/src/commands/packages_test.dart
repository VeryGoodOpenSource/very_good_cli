import 'dart:async';

import 'package:io/io.dart';
import 'package:mason/mason.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:universal_io/io.dart';
import 'package:very_good_cli/src/command_runner.dart';

class MockLogger extends Mock implements Logger {}

const expectedPackagesUsage = [
  // ignore: no_adjacent_strings_in_list
  'Command for managing packages.\n'
      '\n'
      'Usage: very_good packages <subcommand> [arguments]\n'
      '-h, --help    Print this usage information.\n'
      '\n'
      'Available subcommands:\n'
      '  get   Get packages in a Dart or Flutter project.\n'
      '\n'
      'Run "very_good help" to see global options.'
];

const expectedPackagesGetUsage = [
  // ignore: no_adjacent_strings_in_list
  'Get packages in a Dart or Flutter project.\n'
      '\n'
      'Usage: very_good packages get [arguments]\n'
      '-h, --help              Print this usage information.\n'
      '''-r, --[no-]recursive    Install dependencies recursively for all nested packages.\n'''
      '\n'
      'Run "very_good help" to see global options.'
];

void main() {
  group('packages', () {
    late Logger logger;
    late List<String> printLogs;
    late List<String> progressLogs;
    late VeryGoodCommandRunner commandRunner;

    void Function() overridePrint(void Function() fn) {
      return () {
        final spec = ZoneSpecification(print: (_, __, ___, String msg) {
          printLogs.add(msg);
        });
        return Zone.current.fork(specification: spec).run<void>(fn);
      };
    }

    setUp(() {
      logger = MockLogger();
      printLogs = [];
      progressLogs = [];
      commandRunner = VeryGoodCommandRunner(logger: logger);

      when(() => logger.progress(any())).thenReturn(
        ([_]) {
          if (_ != null) progressLogs.add(_);
        },
      );
    });

    test('help', overridePrint(() async {
      final result = await commandRunner.run(['packages', '--help']);
      expect(printLogs, equals(expectedPackagesUsage));
      expect(result, equals(ExitCode.success.code));

      printLogs.clear();

      final resultAbbr = await commandRunner.run(['packages', '-h']);
      expect(printLogs, equals(expectedPackagesUsage));
      expect(resultAbbr, equals(ExitCode.success.code));
    }));

    group('get', () {
      test('help', overridePrint(() async {
        final result = await commandRunner.run(['packages', 'get', '--help']);
        expect(printLogs, equals(expectedPackagesGetUsage));
        expect(result, equals(ExitCode.success.code));

        printLogs.clear();

        final resultAbbr = await commandRunner.run(['packages', 'get', '-h']);
        expect(printLogs, equals(expectedPackagesGetUsage));
        expect(resultAbbr, equals(ExitCode.success.code));
      }));

      test(
          'throws usage exception '
          'when too many arguments are provided', () async {
        final result = await commandRunner.run(
          ['packages', 'get', 'arg1', 'arg2'],
        );
        expect(result, equals(ExitCode.usage.code));
      });

      test(
          'throws pubspec not found exception '
          'when no pubspec.yaml exists', () async {
        final result = await commandRunner.run(['packages', 'get', 'test']);
        expect(result, equals(ExitCode.noInput.code));
        verify(() {
          logger.err(any(that: contains('Could not find a pubspec.yaml in')));
        }).called(1);
      });

      test(
          'throws pubspec not found exception '
          'when no pubspec.yaml exists (recursive)', () async {
        final result = await commandRunner.run(
          ['packages', 'get', '-r', 'test'],
        );
        expect(result, equals(ExitCode.noInput.code));
        verify(() {
          logger.err(any(that: contains('Could not find a pubspec.yaml in')));
        }).called(1);
      });

      test('throws when installation fails', () async {
        final directory = Directory.systemTemp.createTempSync();
        File(path.join(directory.path, 'pubspec.yaml')).writeAsStringSync('');
        final result = await commandRunner.run(
          ['packages', 'get', directory.path],
        );
        expect(result, equals(ExitCode.unavailable.code));
      });

      test(
          'completes normally '
          'when pubspec.yaml exists', () async {
        final result = await commandRunner.run(['packages', 'get']);
        expect(result, equals(ExitCode.success.code));
        verify(() {
          logger.progress(
            any(that: contains('Running "flutter packages get" in')),
          );
        }).called(1);
      });

      test(
          'completes normally '
          'when pubspec.yaml exists (recursive)', () async {
        final result = await commandRunner.run(
          ['packages', 'get', '--recursive'],
        );
        expect(result, equals(ExitCode.success.code));
        verify(() {
          logger.progress(
            any(that: contains('Running "flutter packages get" in')),
          );
        }).called(1);
      });
    });
  });
}
