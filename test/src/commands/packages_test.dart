import 'package:mason/mason.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as path;
import 'package:pub_updater/pub_updater.dart';
import 'package:test/test.dart';
import 'package:universal_io/io.dart';
import 'package:usage/usage.dart';

import '../../helpers/helpers.dart';

class MockAnalytics extends Mock implements Analytics {}

class MockLogger extends Mock implements Logger {}

class MockPubUpdater extends Mock implements PubUpdater {}

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
      '-h, --help         Print this usage information.\n'
      '''-r, --recursive    Install dependencies recursively for all nested packages.\n'''
      '\n'
      'Run "very_good help" to see global options.'
];

void main() {
  group('packages', () {
    test(
      'help',
      withRunner((commandRunner, logger, pubUpdater, printLogs) async {
        final result = await commandRunner.run(['packages', '--help']);
        expect(printLogs, equals(expectedPackagesUsage));
        expect(result, equals(ExitCode.success.code));

        printLogs.clear();

        final resultAbbr = await commandRunner.run(['packages', '-h']);
        expect(printLogs, equals(expectedPackagesUsage));
        expect(resultAbbr, equals(ExitCode.success.code));
      }),
    );

    group('get', () {
      test(
        'help',
        withRunner((commandRunner, logger, pubUpdater, printLogs) async {
          final result = await commandRunner.run(['packages', 'get', '--help']);
          expect(printLogs, equals(expectedPackagesGetUsage));
          expect(result, equals(ExitCode.success.code));

          printLogs.clear();

          final resultAbbr = await commandRunner.run(['packages', 'get', '-h']);
          expect(printLogs, equals(expectedPackagesGetUsage));
          expect(resultAbbr, equals(ExitCode.success.code));
        }),
      );

      test(
        'throws usage exception '
        'when too many arguments are provided',
        withRunner((commandRunner, logger, pubUpdater, printLogs) async {
          final result = await commandRunner.run(
            ['packages', 'get', 'arg1', 'arg2'],
          );
          expect(result, equals(ExitCode.usage.code));
        }),
      );

      test(
        'throws pubspec not found exception '
        'when no pubspec.yaml exists',
        withRunner((commandRunner, logger, pubUpdater, printLogs) async {
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
        withRunner((commandRunner, logger, pubUpdater, printLogs) async {
          final result = await commandRunner.run(
            ['packages', 'get', '-r', 'site'],
          );
          expect(result, equals(ExitCode.noInput.code));
          verify(() {
            logger.err(any(that: contains('Could not find a pubspec.yaml in')));
          }).called(1);
        }),
      );

      test(
        'throws when installation fails',
        withRunner((commandRunner, logger, pubUpdater, printLogs) async {
          final directory = Directory.systemTemp.createTempSync();
          File(path.join(directory.path, 'pubspec.yaml')).writeAsStringSync('');
          final result = await commandRunner.run(
            ['packages', 'get', directory.path],
          );
          expect(result, equals(ExitCode.unavailable.code));
        }),
      );

      test(
        'ignores .fvm directory',
        withRunner((commandRunner, logger, pubUpdater, printLogs) async {
          final tempDirectory = Directory.systemTemp.createTempSync();
          final directory = Directory(path.join(tempDirectory.path, '.fvm'))
            ..createSync();
          File(path.join(directory.path, 'pubspec.yaml')).writeAsStringSync(
            '''
          name: example
          version: 0.1.0
          
          environment:
            sdk: ">=2.12.0 <3.0.0"
          ''',
          );
          final result = await commandRunner.run(
            ['packages', 'get', '-r', tempDirectory.path],
          );
          expect(result, equals(ExitCode.noInput.code));
          verify(() {
            logger.err(any(that: contains('Could not find a pubspec.yaml in')));
          }).called(1);
        }),
      );

      test(
        'completes normally '
        'when pubspec.yaml exists',
        withRunner((commandRunner, logger, pubUpdater, printLogs) async {
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
            ['packages', 'get', directory.path],
          );
          expect(result, equals(ExitCode.success.code));
          verify(() {
            logger.progress(
              any(that: contains('Running "flutter packages get" in')),
            );
          }).called(1);
        }),
      );

      test(
        'completes normally '
        'when pubspec.yaml exists (recursive)',
        withRunner((commandRunner, logger, pubUpdater, printLogs) async {
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
            ['packages', 'get', '--recursive', directory.path],
          );
          expect(result, equals(ExitCode.success.code));
          verify(() {
            logger.progress(
              any(that: contains('Running "flutter packages get" in')),
            );
          }).called(2);
        }),
      );

      test(
        'completes normally '
        'when pubspec.yaml exists and directory is not ignored (recursive)',
        withRunner((commandRunner, logger, pubUpdater, printLogs) async {
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
            ['packages', 'get', '--recursive', directory.path],
          );
          expect(result, equals(ExitCode.success.code));
          verify(() {
            logger.progress(
              any(that: contains('Running "flutter packages get" in')),
            );
          }).called(2);
        }),
      );
    });
  });
}
