@Tags(['e2e'])
import 'package:mason/mason.dart';
import 'package:test/test.dart';
import 'package:universal_io/io.dart';

import '../../../../helpers/helpers.dart';

void main() {
  test(
    'supports async main methods',
    withRunner((commandRunner, logger, updater, logs) async {
      final directory = Directory.systemTemp.createTempSync('async_main');
      final fixture = Directory('test/fixtures/async_main');
      stdout.writeln(fixture.absolute.path);
      await copyDirectory(fixture, directory);

      final pubGetResult = await Process.run(
        'flutter',
        ['pub', 'get'],
        workingDirectory: directory.path,
        runInShell: true,
      );

      expect(pubGetResult.exitCode, equals(ExitCode.success.code));

      await IOOverrides.runZoned(
        () async {
          final result = await commandRunner.run(['test']);
          expect(result, equals(ExitCode.success.code));
        },
        getCurrentDirectory: () => directory,
      );
    }),
    timeout: const Timeout(Duration(minutes: 1)),
  );
}
