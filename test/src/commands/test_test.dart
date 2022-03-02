import 'dart:io';

import 'package:mason/mason.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import 'command_helper.dart';

const expectedTestUsage = [
  // ignore: no_adjacent_strings_in_list
  'Run tests in a Dart or Flutter project.\n'
      '\n'
      'Usage: very_good test [arguments]\n'
      '-h, --help         Print this usage information.\n'
      '-r, --recursive    Run tests recursively for all nested packages.\n'
      '\n'
      'Run "very_good help" to see global options.',
];

void main() {
  group('test', () {
    test(
      'help',
      withRunner((commandRunner, logger, printLogs) async {
        final result = await commandRunner.run(['test', '--help']);
        expect(printLogs, equals(expectedTestUsage));
        expect(result, equals(ExitCode.success.code));

        printLogs.clear();

        final resultAbbr = await commandRunner.run(['test', '-h']);
        expect(printLogs, equals(expectedTestUsage));
        expect(resultAbbr, equals(ExitCode.success.code));
      }),
    );

    test(
      'throws usage exception '
      'when too many arguments are provided',
      withRunner((commandRunner, logger, printLogs) async {
        final result = await commandRunner.run(
          ['test', 'arg1', 'arg2'],
        );
        expect(result, equals(ExitCode.usage.code));
      }),
    );

    test(
      'throws pubspec not found exception '
      'when no pubspec.yaml exists',
      withRunner((commandRunner, logger, printLogs) async {
        final result = await commandRunner.run(['packages', 'get', 'test']);
        expect(result, equals(ExitCode.noInput.code));
        verify(() {
          logger.err(any(that: contains('Could not find a pubspec.yaml in')));
        }).called(1);
      }),
    );

    test(
      'throws pubspec not found exception '
      'when no pubspec.yaml exists (recursive)',
      withRunner((commandRunner, logger, printLogs) async {
        final result = await commandRunner.run(
          ['packages', 'get', '-r', 'test'],
        );
        expect(result, equals(ExitCode.noInput.code));
        verify(() {
          logger.err(any(that: contains('Could not find a pubspec.yaml in')));
        }).called(1);
      }),
    );
    test(
      'throws when installation fails',
      withRunner(
        (commandRunner, logger, printLogs) async {
          final directory = Directory.systemTemp.createTempSync();
          File(path.join(directory.path, 'pubspec.yaml')).writeAsStringSync('');
          final result = await commandRunner.run(
            ['test', directory.path],
          );
          expect(result, equals(ExitCode.unavailable.code));
        },
      ),
    );

    test(
      'completes normally '
      'when pubspec.yaml exists',
      withRunner((commandRunner, logger, printLogs) async {
        final directory = Directory.systemTemp.createTempSync();
        File(path.join(directory.path, 'pubspec.yaml')).writeAsStringSync(
          '''
          name: example
          version: 0.1.0
          
          environment:
            sdk: ">=2.12.0 <3.0.0"
          ''',
        );
        final result = await commandRunner.run(
          ['test', directory.path],
        );
        expect(result, equals(ExitCode.success.code));
        verify(() {
          logger.progress(
            any(that: contains('Running "flutter test" in')),
          );
        }).called(1);
      }),
    );

    test(
      'completes normally '
      'when pubspec.yaml exists (recursive)',
      withRunner((commandRunner, logger, printLogs) async {
        final directory = Directory.systemTemp.createTempSync();
        final pubspecA = File(
          path.join(directory.path, 'example_a', 'pubspec.yaml'),
        );
        final pubspecB = File(
          path.join(directory.path, 'example_b', 'pubspec.yaml'),
        );
        pubspecA
          ..createSync(recursive: true)
          ..writeAsStringSync(
            '''
          name: example_a
          version: 0.1.0
          
          environment:
            sdk: ">=2.12.0 <3.0.0"
          ''',
          );
        pubspecB
          ..createSync(recursive: true)
          ..writeAsStringSync(
            '''
          name: example_b
          version: 0.1.0
          
          environment:
            sdk: ">=2.12.0 <3.0.0"
          ''',
          );

        final result = await commandRunner.run(
          ['test', '--recursive', directory.path],
        );
        expect(result, equals(ExitCode.success.code));
        verify(() {
          logger.progress(
            any(that: contains('Running "flutter test" in')),
          );
        }).called(2);
      }),
    );

    test(
      'completes normally '
      'when pubspec.yaml exists and directory is not ignored (recursive)',
      withRunner((commandRunner, logger, printLogs) async {
        final tempDirectory = Directory.systemTemp.createTempSync();
        final directory = Directory(
          path.join(tempDirectory.path, 'macos_plugin'),
        );
        final pubspecA = File(
          path.join(directory.path, 'example_a', 'pubspec.yaml'),
        );
        final pubspecB = File(
          path.join(directory.path, 'example_b', 'pubspec.yaml'),
        );
        pubspecA
          ..createSync(recursive: true)
          ..writeAsStringSync(
            '''
          name: example_a
          version: 0.1.0
          
          environment:
            sdk: ">=2.12.0 <3.0.0"
          ''',
          );
        pubspecB
          ..createSync(recursive: true)
          ..writeAsStringSync(
            '''
          name: example_b
          version: 0.1.0
          
          environment:
            sdk: ">=2.12.0 <3.0.0"
          ''',
          );

        final result = await commandRunner.run(
          ['test', '--recursive', directory.path],
        );
        expect(result, equals(ExitCode.success.code));
        verify(() {
          logger.progress(
            any(that: contains('Running "flutter test" in')),
          );
        }).called(2);
      }),
    );
  });
}
