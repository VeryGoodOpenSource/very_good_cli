import 'package:mason/mason.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:universal_io/io.dart';

import '../../../../helpers/helpers.dart';

void main() {
  group('file level annotations', () {
    Future<void> setUpFixture(String name) async {
      final tempDirectory = Directory.systemTemp.createTempSync(name);
      addTearDown(() => tempDirectory.deleteSync(recursive: true));

      final fixture = Directory(
        path.join(
          Directory.current.path,
          'test/commands/test/optimization_annotations/$name',
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
    }

    test(
      'are honored by the optimized bundle',
      timeout: const Timeout(Duration(minutes: 2)),
      withRunner((commandRunner, logger, updater, logs, progressLogs) async {
        await setUpFixture('fixture');
        await expectLater(
          commandRunner.run(['test', '-x', 'integration']),
          completion(equals(ExitCode.success.code)),
        );
      }),
    );

    test(
      'apply a file level timeout to the optimized bundle',
      timeout: const Timeout(Duration(minutes: 2)),
      withRunner((commandRunner, logger, updater, logs, progressLogs) async {
        await setUpFixture('timeout_fixture');

        await expectLater(
          commandRunner.run(['test']),
          completion(equals(ExitCode.software.code)),
        );

        verify(() => logger.err(any(that: contains('Test timed out'))))
            .called(greaterThanOrEqualTo(1));
        verify(
          () => logger.err(
            any(that: contains('outlives its file level timeout')),
          ),
        ).called(greaterThanOrEqualTo(1));
      }),
    );

    test(
      'apply a file level timeout to the optimized Flutter bundle',
      timeout: const Timeout(Duration(minutes: 5)),
      withRunner((commandRunner, logger, updater, logs, progressLogs) async {
        await setUpFixture('flutter_fixture');

        await expectLater(
          commandRunner.run(['test']),
          completion(equals(ExitCode.software.code)),
        );

        verify(() => logger.err(any(that: contains('Test timed out'))))
            .called(greaterThanOrEqualTo(1));
        verify(
          () => logger.err(
            any(that: contains('outlives its file level timeout')),
          ),
        ).called(greaterThanOrEqualTo(1));
      }),
    );
  });
}
