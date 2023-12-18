import 'package:mason/mason.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:universal_io/io.dart';

import '../../../../helpers/helpers.dart';

const _expectedPackagesGetUsage = [
  // ignore: no_adjacent_strings_in_list
  'Get packages in a Dart or Flutter project.\n'
      '\n'
      'Usage: very_good packages get [arguments]\n'
      '-h, --help         Print this usage information.\n'
      '''-r, --recursive    Install dependencies recursively for all nested packages.\n'''
      '    --ignore       Exclude packages from installing dependencies.\n'
      '\n'
      'Run "very_good help" to see global options.'
];

void main() {
  group('packages get', () {
    test(
      'help',
      withRunner((commandRunner, logger, pubUpdater, printLogs) async {
        final result = await commandRunner.run(['packages', 'get', '--help']);
        expect(printLogs, equals(_expectedPackagesGetUsage));
        expect(result, equals(ExitCode.success.code));

        printLogs.clear();

        final resultAbbr = await commandRunner.run(['packages', 'get', '-h']);
        expect(printLogs, equals(_expectedPackagesGetUsage));
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
        final tempDirectory = Directory.systemTemp.createTempSync();
        addTearDown(() => tempDirectory.deleteSync(recursive: true));

        File(path.join(tempDirectory.path, 'pubspec.yaml'))
            .writeAsStringSync('');
        final result = await commandRunner.run(
          ['packages', 'get', tempDirectory.path],
        );
        expect(result, equals(ExitCode.unavailable.code));
      }),
    );

    test(
      'ignores .fvm directory',
      withRunner((commandRunner, logger, pubUpdater, printLogs) async {
        final tempDirectory = Directory.systemTemp.createTempSync();
        addTearDown(() => tempDirectory.deleteSync(recursive: true));

        final directory = Directory(path.join(tempDirectory.path, '.fvm'))
          ..createSync();
        File(path.join(directory.path, 'pubspec.yaml')).writeAsStringSync(
          '''
          name: example
          version: 0.1.0
          
          environment:
            sdk: ">=3.1.0 <4.0.0"
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
        final tempDirectory = Directory.systemTemp.createTempSync();
        addTearDown(() => tempDirectory.deleteSync(recursive: true));

        File(path.join(tempDirectory.path, 'pubspec.yaml')).writeAsStringSync(
          '''
          name: example
          version: 0.1.0
          
          environment:
            sdk: ">=3.1.0 <4.0.0"
          ''',
        );
        final result = await commandRunner.run(
          ['packages', 'get', tempDirectory.path],
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
        final tempDirectory = Directory.systemTemp.createTempSync();
        addTearDown(() => tempDirectory.deleteSync(recursive: true));

        final pubspecA = File(
          path.join(tempDirectory.path, 'example_a', 'pubspec.yaml'),
        );
        final pubspecB = File(
          path.join(tempDirectory.path, 'example_b', 'pubspec.yaml'),
        );
        pubspecA
          ..createSync(recursive: true)
          ..writeAsStringSync(
            '''
          name: example_a
          version: 0.1.0
          
          environment:
            sdk: ">=3.1.0 <4.0.0"
          ''',
          );
        pubspecB
          ..createSync(recursive: true)
          ..writeAsStringSync(
            '''
          name: example_b
          version: 0.1.0
          
          environment:
            sdk: ">=3.1.0 <4.0.0"
          ''',
          );

        final result = await commandRunner.run(
          ['packages', 'get', '--recursive', tempDirectory.path],
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
        addTearDown(() => tempDirectory.deleteSync(recursive: true));

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
            sdk: ">=3.1.0 <4.0.0"
          ''',
          );
        pubspecB
          ..createSync(recursive: true)
          ..writeAsStringSync(
            '''
          name: example_b
          version: 0.1.0
          
          environment:
            sdk: ">=3.1.0 <4.0.0"
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
      '''when pubspec.yaml exists and directory is not ignored (recursive) with an empty glob''',
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
            sdk: ">=3.1.0 <4.0.0"
          ''',
          );
        pubspecB
          ..createSync(recursive: true)
          ..writeAsStringSync(
            '''
          name: example_b
          version: 0.1.0
          
          environment:
            sdk: ">=3.1.0 <4.0.0"
          ''',
          );

        final result = await commandRunner.run(
          ['packages', 'get', '--recursive', directory.path, '--ignore=""'],
        );
        expect(result, equals(ExitCode.success.code));
        verify(() {
          logger.progress(
            any(that: contains('Running "flutter packages get" in')),
          );
        }).called(2);
        directory.deleteSync(recursive: true);
      }),
    );

    test(
      'completes normally '
      'when pubspec.yaml exists and directory is ignored (recursive)',
      withRunner((commandRunner, logger, pubUpdater, printLogs) async {
        final tempDirectory = Directory.systemTemp.createTempSync();
        addTearDown(() => tempDirectory.deleteSync(recursive: true));

        final directoryA = Directory(
          path.join(tempDirectory.path, 'plugin_a'),
        );
        final directoryB = Directory(
          path.join(tempDirectory.path, 'plugin_b'),
        );
        final pubspecA = File(
          path.join(directoryA.path, 'example_a', 'pubspec.yaml'),
        );
        final pubspecB = File(
          path.join(directoryB.path, 'example_b', 'pubspec.yaml'),
        );
        pubspecA
          ..createSync(recursive: true)
          ..writeAsStringSync(
            '''
          name: example_a
          version: 0.1.0
          
          environment:
            sdk: ">=3.1.0 <4.0.0"
          ''',
          );
        pubspecB
          ..createSync(recursive: true)
          ..writeAsStringSync(
            '''
          name: example_b
          version: 0.1.0
          
          environment:
            sdk: ">=3.1.0 <4.0.0"
          ''',
          );

        final result = await commandRunner.run(
          [
            'packages',
            'get',
            '--recursive',
            '--ignore=plugin_b',
            tempDirectory.path,
          ],
        );

        final relativePathPrefix = '.${path.context.separator}';

        expect(result, equals(ExitCode.success.code));
        verify(() {
          final relativePath = path.relative(
            directoryA.path,
            from: tempDirectory.path,
          );
          logger.progress(
            any(
              that: contains(
                '''Running "flutter packages get" in $relativePathPrefix$relativePath''',
              ),
            ),
          );
        }).called(1);
        verifyNever(() {
          final relativePath = path.relative(
            directoryB.path,
            from: tempDirectory.path,
          );

          logger.progress(
            any(
              that: contains(
                '''Running "flutter packages get" in $relativePathPrefix$relativePath''',
              ),
            ),
          );
        });
      }),
    );
  });
}
