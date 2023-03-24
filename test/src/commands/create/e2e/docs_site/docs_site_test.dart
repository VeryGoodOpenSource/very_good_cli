@Tags(['e2e'])
library docs_site_test;

import 'package:mason/mason.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:universal_io/io.dart';

import '../../../../../helpers/helpers.dart';

void main() {
  test(
    'create docs_site',
    withRunner((commandRunner, logger, updater, logs) async {
      final directory = Directory.systemTemp.createTempSync();
      final result = await commandRunner.run(
        ['create', 'docs_site', 'very_good_docs_site', '-o', directory.path],
      );
      expect(result, equals(ExitCode.success.code));

      final workingDirectory = path.join(directory.path, 'very_good_docs_site');

      await expectSuccessfulProcessResult(
        'npm',
        ['install'],
        workingDirectory: workingDirectory,
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
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
