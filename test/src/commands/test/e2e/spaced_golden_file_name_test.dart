@Tags(['e2e'])
library spaced_golden_file_name_test;

import 'package:mason/mason.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:universal_io/io.dart';

import '../../../../helpers/helpers.dart';

void main() {
  test(
    'allows golden files with spaces in the name',
    timeout: const Timeout(Duration(minutes: 2)),
    withRunner((commandRunner, logger, updater, logs) async {
      final tempDirectory = Directory.systemTemp.createTempSync('async_main');
      addTearDown(() => tempDirectory.deleteSync(recursive: true));

      await copyDirectory(
        Directory('test/fixtures/spaced_golden_file_name'),
        tempDirectory,
      );

      await expectSuccessfulProcessResult(
        'flutter',
        ['pub', 'get'],
        workingDirectory: tempDirectory.path,
      );
      await expectSuccessfulProcessResult(
        'flutter',
        ['test', '--update-goldens'],
        workingDirectory: tempDirectory.path,
      );

      Directory.current = tempDirectory;
      final result = await commandRunner.run(['test']);

      verifyNever(() => logger.err(any()));
      expect(result, equals(ExitCode.success.code));
    }),
  );
}
