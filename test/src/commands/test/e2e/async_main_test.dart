@Tags(['e2e'])
library async_main_test;

import 'package:mason/mason.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:universal_io/io.dart';

import '../../../../helpers/helpers.dart';

void main() {
  test(
    'supports async main methods',
    timeout: const Timeout(Duration(minutes: 2)),
    withRunner((commandRunner, logger, updater, logs) async {
      final tempDirectory = Directory.systemTemp.createTempSync('async_main');
      addTearDown(() => tempDirectory.deleteSync(recursive: true));

      final fixture = Directory(
        path.join(Directory.current.path, 'test/fixtures/async_main'),
      );

      await copyDirectory(fixture, tempDirectory);

      await expectSuccessfulProcessResult(
        'flutter',
        ['pub', 'get'],
        workingDirectory: tempDirectory.path,
      );

      final cwd = Directory.current;
      Directory.current = tempDirectory;
      addTearDown(() {
        Directory.current = cwd;
      });

      final result = await commandRunner.run(['test']);
      expect(result, equals(ExitCode.success.code));
    }),
  );
}
