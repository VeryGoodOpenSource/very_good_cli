import 'package:mason/mason.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:universal_io/io.dart';

import '../../../../helpers/helpers.dart';

void main() {
  test(
    'create docs_site',
    timeout: const Timeout(Duration(minutes: 2)),
    withRunner((commandRunner, logger, updater, logs) async {
      final tempDirectory = Directory.systemTemp.createTempSync();
      addTearDown(() => tempDirectory.deleteSync(recursive: true));

      final result = await commandRunner.run(
        [
          'create',
          'docs_site',
          'very_good_docs_site',
          '-o',
          tempDirectory.path,
        ],
      );
      expect(result, equals(ExitCode.success.code));

      final workingDirectory =
          path.join(tempDirectory.path, 'very_good_docs_site');

      await expectSuccessfulProcessResult(
        'npm',
        ['install'],
        workingDirectory: workingDirectory,
        validateStderr: false,
      );

      await expectSuccessfulProcessResult(
        'npm',
        ['run', 'format'],
        workingDirectory: workingDirectory,
      );

      await expectSuccessfulProcessResult(
        'npm',
        ['run', 'lint'],
        workingDirectory: workingDirectory,
      );

      await expectSuccessfulProcessResult(
        'npm',
        ['run', 'build'],
        workingDirectory: workingDirectory,
      );
    }),
  );
}
