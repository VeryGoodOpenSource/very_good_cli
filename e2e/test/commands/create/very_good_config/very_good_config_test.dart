import 'package:mason/mason.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:universal_io/io.dart';

import '../../../../helpers/helpers.dart';

void main() {
  group('very_good.yaml', () {
    test(
      'applies create defaults from very_good.yaml when flags are not passed',
      timeout: const Timeout(Duration(minutes: 2)),
      withRunner((commandRunner, logger, updater, logs, progressLogs) async {
        final tempDirectory = Directory.systemTemp.createTempSync(
          'very_good_config_create',
        );
        addTearDown(() => tempDirectory.deleteSync(recursive: true));

        final fixture = Directory(
          path.join(
            Directory.current.path,
            'test/commands/create/very_good_config/fixture',
          ),
        );

        await copyDirectory(fixture, tempDirectory);

        final cwd = Directory.current;
        Directory.current = tempDirectory;
        addTearDown(() => Directory.current = cwd);

        final result = await commandRunner.run([
          'create',
          'dart_package',
          'very_good_dart',
        ]);
        expect(result, equals(ExitCode.success.code));

        final pubspec = File(
          path.join(tempDirectory.path, 'very_good_dart', 'pubspec.yaml'),
        );
        expect(pubspec.existsSync(), isTrue);
        expect(
          pubspec.readAsStringSync(),
          contains('A project configured via very_good.yaml.'),
        );
      }),
    );

    test(
      'fails with config exit code when very_good.yaml is malformed',
      timeout: const Timeout(Duration(minutes: 2)),
      withRunner((commandRunner, logger, updater, logs, progressLogs) async {
        final tempDirectory = Directory.systemTemp.createTempSync(
          'very_good_config_create_malformed',
        );
        addTearDown(() => tempDirectory.deleteSync(recursive: true));

        final fixture = Directory(
          path.join(
            Directory.current.path,
            'test/commands/create/very_good_config/malformed_fixture',
          ),
        );

        await copyDirectory(fixture, tempDirectory);

        final cwd = Directory.current;
        Directory.current = tempDirectory;
        addTearDown(() => Directory.current = cwd);

        await expectLater(
          commandRunner.run(['create', 'dart_package', 'very_good_dart']),
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
