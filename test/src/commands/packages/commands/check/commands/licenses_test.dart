import 'dart:collection';
import 'dart:io';

import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:very_good_cli/src/commands/packages/commands/check/commands/commands.dart';
import 'package:very_good_cli/src/pub_license/pub_license.dart';

import '../../../../../../helpers/helpers.dart';

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

    test(
      'returns exit code 0',
      withRunner(
          (commandRunner, logger, pubUpdater, pubLicense, printLogs) async {
        final result = await commandRunner.run(commandArguments);
        expect(result, equals(ExitCode.success.code));
      }),
    );

    test('is hidden', () {
      final command = PackagesCheckLicensesCommand();
      expect(command.hidden, isTrue);
    });

    group('exits with error', () {
      // TODO(alestiago): Verify process is cancelled.

      test(
        'when it did not find a pubspec.lock file at the target path',
        withRunner(
            (commandRunner, logger, pubUpdater, pubLicense, printLogs) async {
          final tempDirectory = Directory.systemTemp.createTempSync();
          addTearDown(() => tempDirectory.deleteSync(recursive: true));

          final result = await commandRunner.run(
            [...commandArguments, tempDirectory.path],
          );

          final errorMessage =
              'Could not find a $pubspecLockBasename in ${tempDirectory.path}';
          verify(() => logger.err(errorMessage)).called(1);

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

          final result = await commandRunner.run(
            [...commandArguments, tempDirectory.path],
          );

          final errorMessage =
              'Could not parse $pubspecLockBasename in ${tempDirectory.path}';
          verify(() => logger.err(errorMessage)).called(1);

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

          final result = await commandRunner.run(
            [...commandArguments, tempDirectory.path],
          );

          final errorMessage =
              'No hosted direct dependencies found in ${tempDirectory.path}';
          verify(() => logger.err(errorMessage)).called(1);

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

          expect(result, equals(ExitCode.software.code));
        }),
      );
    });
  });
}

/// A valid pubspec lock file.
///
/// It has been artificially crafted to include a single:
/// - hosted direct dependency
/// - hosted direct dev dependency
/// - hosted transitive dependency
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

/// A valid pubspec lock file with no dependencies.
const _emptyPubspecLockContent = '''
sdks:
  dart: ">=3.1.0 <4.0.0"

''';
