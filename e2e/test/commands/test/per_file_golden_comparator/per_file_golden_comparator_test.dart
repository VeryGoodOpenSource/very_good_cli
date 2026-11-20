import 'package:mason/mason.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:universal_io/io.dart';

import '../../../../helpers/helpers.dart';

void main() {
  test(
    'resolves the goldens of each optimized test file next to that file',
    timeout: const Timeout(Duration(minutes: 2)),
    withRunner((commandRunner, logger, updater, logs, progressLogs) async {
      final tempDirectory = Directory.systemTemp.createTempSync(
        'per_file_golden_comparator',
      );
      addTearDown(() => tempDirectory.deleteSync(recursive: true));

      await copyDirectory(
        Directory('test/commands/test/per_file_golden_comparator/fixture'),
        tempDirectory,
      );

      await expectSuccessfulProcessResult('flutter', [
        'pub',
        'get',
      ], workingDirectory: tempDirectory.path);

      await expectSuccessfulProcessResult('flutter', [
        'test',
        '--update-goldens',
      ], workingDirectory: tempDirectory.path);

      Directory.current = tempDirectory;
      final result = await commandRunner.run(['test']);

      verifyNever(() => logger.err(any()));
      expect(result, equals(ExitCode.success.code));
    }),
  );
}
