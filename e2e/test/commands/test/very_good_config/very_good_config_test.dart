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

        final result = await commandRunner.run(['test', '--coverage']);

        expect(result, equals(ExitCode.unavailable.code));
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

        final result = await commandRunner.run([
          'test',
          '--coverage',
          '--min-coverage',
          '0',
        ]);

        expect(result, equals(ExitCode.success.code));
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

        File(path.join(tempDirectory.path, 'pubspec.yaml')).writeAsStringSync(
          '''
name: malformed_fixture
description: Fixture for testing malformed very_good.yaml.
version: 0.1.0+1
publish_to: none

environment:
  sdk: ^3.12.0

dev_dependencies:
  test: ^1.24.3
''',
        );
        File(
          path.join(tempDirectory.path, 'very_good.yaml'),
        ).writeAsStringSync('- not\n- a\n- map');

        final cwd = Directory.current;
        Directory.current = tempDirectory;
        addTearDown(() => Directory.current = cwd);

        final result = await commandRunner.run(['test']);

        expect(result, equals(ExitCode.config.code));
        verify(
          () => logger.err(
            any(that: contains('Could not read `very_good.yaml`')),
          ),
        ).called(1);
      }),
    );
  });
}
