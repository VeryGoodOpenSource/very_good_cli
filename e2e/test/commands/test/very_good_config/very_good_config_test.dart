import 'package:mason/mason.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:universal_io/io.dart';

import '../../../../helpers/helpers.dart';

void main() {
  group('very_good.yaml', () {
    test(
      'enforces min-coverage from very_good.yaml when the flag is not passed',
      timeout: const Timeout(Duration(minutes: 2)),
      withRunner((commandRunner, logger, updater, logs, progressLogs) async {
        final tempDirectory = Directory.systemTemp.createTempSync(
          'very_good_config',
        );
        addTearDown(() => tempDirectory.deleteSync(recursive: true));

        final fixture = Directory(
          path.join(
            Directory.current.path,
            'test/commands/test/very_good_config/fixture',
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

        await expectLater(
          commandRunner.run(['test', '--coverage']),
          completion(equals(ExitCode.unavailable.code)),
        );
        verify(
          () => logger.err(any(that: contains('Expected coverage >= 100.00%'))),
        ).called(1);
      }),
    );

    test(
      'CLI --min-coverage takes precedence over very_good.yaml',
      timeout: const Timeout(Duration(minutes: 2)),
      withRunner((commandRunner, logger, updater, logs, progressLogs) async {
        final tempDirectory = Directory.systemTemp.createTempSync(
          'very_good_config_override',
        );
        addTearDown(() => tempDirectory.deleteSync(recursive: true));

        final fixture = Directory(
          path.join(
            Directory.current.path,
            'test/commands/test/very_good_config/fixture',
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

        await expectLater(
          commandRunner.run([
            'test',
            '--coverage',
            '--min-coverage',
            '0',
          ]),
          completion(equals(ExitCode.success.code)),
        );
      }),
    );

    test(
      'fails with config exit code when very_good.yaml is malformed',
      timeout: const Timeout(Duration(minutes: 2)),
      withRunner((commandRunner, logger, updater, logs, progressLogs) async {
        final tempDirectory = Directory.systemTemp.createTempSync(
          'very_good_config_malformed',
        );
        addTearDown(() => tempDirectory.deleteSync(recursive: true));

        final fixture = Directory(
          path.join(
            Directory.current.path,
            'test/commands/test/very_good_config/malformed_fixture',
          ),
        );

        await copyDirectory(fixture, tempDirectory);

        final cwd = Directory.current;
        Directory.current = tempDirectory;
        addTearDown(() => Directory.current = cwd);

        await expectLater(
          commandRunner.run(['test']),
          completion(equals(ExitCode.config.code)),
        );
        verify(
          () => logger.err(
            any(that: contains('Could not read `very_good.yaml`')),
          ),
        ).called(1);
      }),
    );
  });
}
