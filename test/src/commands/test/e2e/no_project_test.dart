@Tags(['e2e'])
library no_project_test;

import 'package:mason/mason.dart';
import 'package:test/test.dart';
import 'package:universal_io/io.dart';

import '../../../../helpers/helpers.dart';

void main() {
  test(
    'fails if the project does not exist',
    withRunner((commandRunner, logger, updater, logs) async {
      final directory = Directory.systemTemp.createTempSync('async_main');
      await copyDirectory(Directory('test/fixtures/async_main'), directory);

      await expectSuccessfulProcessResult(
        'flutter',
        ['pub', 'get'],
        workingDirectory: directory.path,
      );

      final result = await commandRunner.run(['test', directory.path]);
      expect(result, equals(ExitCode.success.code));
    }),
  );
}
