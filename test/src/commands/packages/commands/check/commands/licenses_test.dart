import 'dart:collection';
import 'dart:io';

import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:very_good_cli/src/commands/packages/commands/check/commands/commands.dart';
import 'package:very_good_cli/src/pub_license/pub_license.dart';

import '../../../../../../helpers/helpers.dart';

class _MockProgress extends Mock implements Progress {}

const _expectedPackagesCheckLicensesUsage = [
  // ignore: no_adjacent_strings_in_list
  'Check packages licenses in a Dart or Flutter project.\n'
      '\n'
      'Usage: very_good packages check licenses [arguments]\n'
      '-h, --help    Print this usage information.\n'
      '\n'
      'Run "very_good help" to see global options.'
];

void main() {
  group('packages check licenses', () {
    final commandArguments = UnmodifiableListView(
      ['packages', 'check', 'licenses'],
    );

    late Progress progress;

    setUpAll(() {
      registerFallbackValue('');
    });

    setUp(() {
      progress = _MockProgress();
      // when(() => progress.cancel()).thenReturn(null);
      // when(() => progress.update(any())).thenReturn(null);
      // when(() => progress.fail(any())).thenReturn(null);
      // when(() => progress.complete(any())).thenReturn(null);
    });

    test(
      'help',
      withRunner(
          (commandRunner, logger, pubUpdater, pubLicense, printLogs) async {
        final result = await commandRunner.run(
          [...commandArguments, '--help'],
        );
        expect(printLogs, equals(_expectedPackagesCheckLicensesUsage));
        expect(result, equals(ExitCode.success.code));

        printLogs.clear();

        final resultAbbr = await commandRunner.run([...commandArguments, '-h']);
        expect(printLogs, equals(_expectedPackagesCheckLicensesUsage));
        expect(resultAbbr, equals(ExitCode.success.code));
      }),
    );

    test('is hidden', () {
      final command = PackagesCheckLicensesCommand();
      expect(command.hidden, isTrue);
    });

    group(
      'reports licenses',
      () {
        test(
          '''correctly when there is a single hosted direct dependency and license''',
          withRunner(
              (commandRunner, logger, pubUpdater, pubLicense, printLogs) async {
            final tempDirectory = Directory.systemTemp.createTempSync();
            addTearDown(() => tempDirectory.deleteSync(recursive: true));

            File(path.join(tempDirectory.path, pubspecLockBasename))
                .writeAsStringSync(_validPubspecLockContent);

            when(() => logger.progress(any())).thenReturn(progress);

            final result = await commandRunner.run(
              [...commandArguments, tempDirectory.path],
            );

            const report =
                '''Retrieved 1 license from 1 package of type: MIT.''';
            verify(() => progress.complete(report)).called(1);

            expect(result, equals(ExitCode.success.code));
          }),
        );

        test(
          '''correctly when there are multiple hosted direct dependency and licenses''',
          withRunner(
              (commandRunner, logger, pubUpdater, pubLicense, printLogs) async {
            final tempDirectory = Directory.systemTemp.createTempSync();
            addTearDown(() => tempDirectory.deleteSync(recursive: true));

            File(path.join(tempDirectory.path, pubspecLockBasename))
                .writeAsStringSync(_validMultiplePubspecLockContent);

            when(() => logger.progress(any())).thenReturn(progress);

            when(() => pubLicense.getLicense(any()))
                .thenAnswer((_) => Future.value({'MIT', 'BSD'}));

            final result = await commandRunner.run(
              [...commandArguments, tempDirectory.path],
            );

            const report =
                '''Retrieved 4 licenses from 2 packages of type: MIT and BSD.''';
            verify(() => progress.complete(report)).called(1);

            expect(result, equals(ExitCode.success.code));
          }),
        );
      },
    );

    group('exits with error', () {
      test(
        'when it did not find a pubspec.lock file at the target path',
        withRunner(
            (commandRunner, logger, pubUpdater, pubLicense, printLogs) async {
          final tempDirectory = Directory.systemTemp.createTempSync();
          addTearDown(() => tempDirectory.deleteSync(recursive: true));

          when(() => logger.progress(any())).thenReturn(progress);

          final result = await commandRunner.run(
            [...commandArguments, tempDirectory.path],
          );

          final errorMessage =
              'Could not find a $pubspecLockBasename in ${tempDirectory.path}';
          verify(() => logger.err(errorMessage)).called(1);

          verify(() => progress.cancel()).called(1);

          expect(result, equals(ExitCode.noInput.code));
        }),
      );

      test(
        'when it failed to parse a pubspec.lock file at the target path',
        withRunner(
            (commandRunner, logger, pubUpdater, pubLicense, printLogs) async {
          final tempDirectory = Directory.systemTemp.createTempSync();
          addTearDown(() => tempDirectory.deleteSync(recursive: true));

          File(path.join(tempDirectory.path, pubspecLockBasename))
              .writeAsStringSync('');

          when(() => logger.progress(any())).thenReturn(progress);

          final result = await commandRunner.run(
            [...commandArguments, tempDirectory.path],
          );

          final errorMessage =
              'Could not parse $pubspecLockBasename in ${tempDirectory.path}';
          verify(() => logger.err(errorMessage)).called(1);

          verify(() => progress.cancel()).called(1);

          expect(result, equals(ExitCode.noInput.code));
        }),
      );

      test(
        'when no hosted direct dependencies are found',
        withRunner(
            (commandRunner, logger, pubUpdater, pubLicense, printLogs) async {
          final tempDirectory = Directory.systemTemp.createTempSync();
          addTearDown(() => tempDirectory.deleteSync(recursive: true));

          File(path.join(tempDirectory.path, pubspecLockBasename))
              .writeAsStringSync(_emptyPubspecLockContent);

          when(() => logger.progress(any())).thenReturn(progress);

          final result = await commandRunner.run(
            [...commandArguments, tempDirectory.path],
          );

          final errorMessage =
              'No hosted direct dependencies found in ${tempDirectory.path}';
          verify(() => logger.err(errorMessage)).called(1);

          verify(() => progress.cancel()).called(1);

          expect(result, equals(ExitCode.usage.code));
        }),
      );

      test(
        'when PubLicense throws a PubLicenseException',
        withRunner(
            (commandRunner, logger, pubUpdater, pubLicense, printLogs) async {
          final tempDirectory = Directory.systemTemp.createTempSync();
          addTearDown(() => tempDirectory.deleteSync(recursive: true));

          File(path.join(tempDirectory.path, pubspecLockBasename))
              .writeAsStringSync(_validPubspecLockContent);

          when(() => logger.progress(any())).thenReturn(progress);

          const exception = PubLicenseException('message');
          when(() => pubLicense.getLicense('very_good_test_runner'))
              .thenThrow(exception);

          final result = await commandRunner.run(
            [...commandArguments, tempDirectory.path],
          );

          final packageName = verify(() => pubLicense.getLicense(captureAny()))
              .captured
              .cast<String>()
              .first;

          final errorMessage = '[$packageName] ${exception.message}';
          verify(() => logger.err(errorMessage)).called(1);

          verify(() => progress.cancel()).called(1);

          expect(result, equals(ExitCode.unavailable.code));
        }),
      );

      test(
        'when PubLicense throws an unknown error',
        withRunner(
            (commandRunner, logger, pubUpdater, pubLicense, printLogs) async {
          final tempDirectory = Directory.systemTemp.createTempSync();
          addTearDown(() => tempDirectory.deleteSync(recursive: true));

          File(path.join(tempDirectory.path, pubspecLockBasename))
              .writeAsStringSync(_validPubspecLockContent);

          const error = 'error';
          when(() => pubLicense.getLicense('very_good_test_runner'))
              .thenThrow(error);

          when(() => logger.progress(any())).thenReturn(progress);

          final result = await commandRunner.run(
            [...commandArguments, tempDirectory.path],
          );

          final packageName = verify(() => pubLicense.getLicense(captureAny()))
              .captured
              .cast<String>()
              .first;

          final errorMessage =
              '[$packageName] Unexpected failure with error: $error';
          verify(() => logger.err(errorMessage)).called(1);

          verify(() => progress.cancel()).called(1);

          expect(result, equals(ExitCode.software.code));
        }),
      );
    });
  });
}

/// A valid pubspec lock file.
///
/// It has been artificially crafted to include:
/// - one hosted direct dependency
/// - one hosted direct dev dependency
/// - one hosted transitive dependency
const _validPubspecLockContent = '''
packages:
  very_good_analysis:
    dependency: "direct dev"
    description:
      name: very_good_analysis
      sha256: "9ae7f3a3bd5764fb021b335ca28a34f040cd0ab6eec00a1b213b445dae58a4b8"
      url: "https://pub.dev"
    source: hosted
    version: "5.1.0"
  very_good_test_runner:
    dependency: "direct main"
    description:
      name: very_good_test_runner
      sha256: "4d41e5d7677d259b9a1599c78645ac2d36bc2bd6ff7773507bcb0bab41417fe2"
      url: "https://pub.dev"
    source: hosted
    version: "0.1.2"
  yaml:
    dependency: transitive
    description:
      name: yaml
      sha256: "75769501ea3489fca56601ff33454fe45507ea3bfb014161abc3b43ae25989d5"
      url: "https://pub.dev"
    source: hosted
    version: "3.1.2"
sdks:
  dart: ">=3.1.0 <4.0.0"

''';

/// A valid pubspec lock file.
///
/// It has been artificially crafted to include:
/// - two hosted direct dependency
/// - two hosted direct dev dependency
/// - two hosted transitive dependency
const _validMultiplePubspecLockContent = '''
packages:
  very_good_analysis:
    dependency: "direct dev"
    description:
      name: very_good_analysis
      sha256: "9ae7f3a3bd5764fb021b335ca28a34f040cd0ab6eec00a1b213b445dae58a4b8"
      url: "https://pub.dev"
    source: hosted
    version: "5.1.0"
  build_runner:
    dependency: "direct dev"
    description:
      name: build_runner
      sha256: "10c6bcdbf9d049a0b666702cf1cee4ddfdc38f02a19d35ae392863b47519848b"
      url: "https://pub.dev"
    source: hosted
    version: "2.4.6"
  very_good_test_runner:
    dependency: "direct main"
    description:
      name: very_good_test_runner
      sha256: "4d41e5d7677d259b9a1599c78645ac2d36bc2bd6ff7773507bcb0bab41417fe2"
      url: "https://pub.dev"
    source: hosted
    version: "0.1.2"
  cli_completion:
    dependency: "direct main"
    description:
      name: cli_completion
      sha256: "1e87700c029c77041d836e57f9016b5c90d353151c43c2ca0c36deaadc05aa3a"
      url: "https://pub.dev"
    source: hosted
    version: "0.4.0"
  yaml:
    dependency: transitive
    description:
      name: yaml
      sha256: "75769501ea3489fca56601ff33454fe45507ea3bfb014161abc3b43ae25989d5"
      url: "https://pub.dev"
    source: hosted
    version: "3.1.2"
  archive:
    dependency: transitive
    description:
      name: archive
      sha256: d4dc11707abb32ef756ab95678c0d6df54003d98277f7c9aeda14c48e7a38c2f
      url: "https://pub.dev"
    source: hosted
    version: "3.4.3"
sdks:
  dart: ">=3.1.0 <4.0.0"

''';

/// A valid pubspec lock file with no dependencies.
const _emptyPubspecLockContent = '''
sdks:
  dart: ">=3.1.0 <4.0.0"

''';
