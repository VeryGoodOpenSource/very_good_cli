import 'package:mason/mason.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:universal_io/io.dart';

import '../../../../helpers/helpers.dart';

void main() {
  group('suite annotations', () {
    Future<Directory> setUpFixture(String name) async {
      final tempDirectory = Directory.systemTemp.createTempSync(name);
      addTearDown(() => tempDirectory.deleteSync(recursive: true));

      final fixture = Directory(
        path.join(
          Directory.current.path,
          'test/commands/test/suite_annotations/$name',
        ),
      );

      await copyDirectory(fixture, tempDirectory);

      await expectSuccessfulProcessResult('flutter', [
        'pub',
        'get',
      ], workingDirectory: tempDirectory.path);

      final cwd = Directory.current;
      Directory.current = tempDirectory;
      addTearDown(() => Directory.current = cwd);

      return tempDirectory;
    }

    test(
      'honors library-level annotations of optimized test files',
      timeout: const Timeout(Duration(minutes: 2)),
      withRunner((commandRunner, logger, updater, logs, progressLogs) async {
        await setUpFixture('fixture');
        await expectLater(
          commandRunner.run(['test', '-x', 'excluded']),
          completion(equals(ExitCode.success.code)),
        );
      }),
    );

    test(
      'honors a library-level timeout of an optimized test file',
      timeout: const Timeout(Duration(minutes: 2)),
      withRunner((commandRunner, logger, updater, logs, progressLogs) async {
        await setUpFixture('timeout_fixture');
        await expectLater(
          commandRunner.run(['test']),
          completion(equals(ExitCode.unavailable.code)),
        );
      }),
    );
  });
}
