import 'dart:io';

import 'package:mason/mason.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import '../../helpers/helpers.dart';

const testContent = '''
import 'package:test/test.dart';
void main() {
  test('example', () {
    expect(true, isTrue);
  });
}''';

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

String pubspecContent([String name = 'example']) {
  return '''
name: $name
version: 0.1.0

environment:
  sdk: ">=2.12.0 <3.0.0"

dev_dependencies:
  test: any''';
}

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
        final directory = Directory.systemTemp.createTempSync();
        final result = await commandRunner.run(['test', directory.path]);
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
        final directory = Directory.systemTemp.createTempSync();
        final result = await commandRunner.run(['test', '-r', directory.path]);
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
          final result = await commandRunner.run(['test', directory.path]);
          expect(result, equals(ExitCode.unavailable.code));
        },
      ),
    );

    test(
      'completes normally '
      'when pubspec.yaml and tests exist',
      withRunner((commandRunner, logger, printLogs) async {
        final directory = Directory.systemTemp.createTempSync();
        final testDirectory = Directory(path.join(directory.path, 'test'))
          ..createSync();
        File(
          path.join(directory.path, 'pubspec.yaml'),
        ).writeAsStringSync(pubspecContent());
        File(
          path.join(testDirectory.path, 'example_test.dart'),
        ).writeAsStringSync(testContent);
        final result = await commandRunner.run(['test', directory.path]);
        expect(result, equals(ExitCode.success.code));
        verify(() {
          logger.write(
            any(that: contains('Running "flutter test" in')),
          );
        }).called(1);
        verify(() {
          logger.write(any(that: contains('All tests passed')));
        }).called(1);
      }),
    );

    test(
      'completes normally '
      'when pubspec.yaml and tests exist (recursive)',
      withRunner((commandRunner, logger, printLogs) async {
        final directory = Directory.systemTemp.createTempSync();
        final testDirectoryA = Directory(
          path.join(directory.path, 'example_a', 'test'),
        )..createSync(recursive: true);
        final testDirectoryB = Directory(
          path.join(directory.path, 'example_b', 'test'),
        )..createSync(recursive: true);
        File(
          path.join(testDirectoryA.path, 'example_a_test.dart'),
        ).writeAsStringSync(testContent);
        File(
          path.join(testDirectoryB.path, 'example_b_test.dart'),
        ).writeAsStringSync(testContent);
        File(
          path.join(directory.path, 'example_a', 'pubspec.yaml'),
        ).writeAsStringSync(pubspecContent('example_a'));
        File(
          path.join(directory.path, 'example_b', 'pubspec.yaml'),
        ).writeAsStringSync(pubspecContent('example_b'));

        final result = await commandRunner.run(
          ['test', '--recursive', directory.path],
        );
        expect(result, equals(ExitCode.success.code));
        verify(() {
          logger.write(
            any(that: contains('Running "flutter test" in')),
          );
        }).called(2);
        verify(() {
          logger.write(any(that: contains('All tests passed')));
        }).called(2);
      }),
    );
  });
}
