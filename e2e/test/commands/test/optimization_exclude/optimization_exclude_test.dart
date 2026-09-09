import 'package:mason/mason.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:universal_io/io.dart';

import '../../../../helpers/helpers.dart';

void main() {
  group('optimization exclusions', () {
    Future<Directory> setUpFixture(String prefix) async {
      final tempDirectory = Directory.systemTemp.createTempSync(prefix);
      addTearDown(() => tempDirectory.deleteSync(recursive: true));

      final fixture = Directory(
        path.join(
          Directory.current.path,
          'test/commands/test/optimization_exclude/fixture',
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
      'runs an excluded suite on its own, so its file-level tags are honored',
      timeout: const Timeout(Duration(minutes: 2)),
      withRunner((commandRunner, logger, updater, logs, progressLogs) async {
        await setUpFixture('optimization_exclude');
        await expectLater(
          commandRunner.run(['test', '-x', 'integration']),
          completion(equals(ExitCode.success.code)),
        );
      }),
    );

    test(
      'CLI globs replace the ones from very_good.yaml',
      timeout: const Timeout(Duration(minutes: 2)),
      withRunner((commandRunner, logger, updater, logs, progressLogs) async {
        await setUpFixture('optimization_exclude_override');
        await expectLater(
          commandRunner.run([
            'test',
            '-x',
            'integration',
            '--exclude-optimization',
            'test/nothing_here',
          ]),
          completion(equals(ExitCode.unavailable.code)),
        );
      }),
    );
  });
}
