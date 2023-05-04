import 'package:mason/mason.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:universal_io/io.dart';

import '../../../../helpers/helpers.dart';

void main() {
  test(
    'fails if the project does not exist',
    withRunner((commandRunner, logger, updater, logs) async {
      final tempDirectory = Directory.systemTemp.createTempSync('no_project');
      addTearDown(() => tempDirectory.deleteSync(recursive: true));

      await copyDirectory(
        Directory('test/commands/test/no_project/fixture'),
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

      verifyNever(() => logger.err(any()));
      expect(result, equals(ExitCode.success.code));
    }),
  );
}
