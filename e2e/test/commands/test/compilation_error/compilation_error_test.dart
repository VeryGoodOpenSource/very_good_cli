import 'package:mason/mason.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:universal_io/io.dart';

import '../../../../helpers/helpers.dart';

void main() {
  test(
    'fails when there is a compilation error, but does not crash',
    timeout: const Timeout(Duration(minutes: 2)),
    withRunner((commandRunner, logger, updater, logs) async {
      final tempDirectory =
          Directory.systemTemp.createTempSync('compilation_error');
      addTearDown(() => tempDirectory.deleteSync(recursive: true));

      await copyDirectory(
        Directory('test/commands/test/compilation_error/fixture'),
        tempDirectory,
      );

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

      expect(result, equals(ExitCode.unavailable.code));
      verify(
        () => logger.err(any(that: contains('- test/.test_optimizer.dart'))),
      ).called(1);
    }),
  );
}
