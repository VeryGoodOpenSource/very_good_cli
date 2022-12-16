@Tags(['e2e'])
import 'package:mason/mason.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:universal_io/io.dart';

import '../../../../helpers/helpers.dart';

void main() {
  stdout.writeln('main() cwd: "${Directory.current.absolute.path}"');
  test('sanity', () {
    stdout.writeln('test() cwd: "${Directory.current.absolute.path}"');
    expect(true, isTrue);
  });

  test(
    'supports async main methods',
    withRunner((commandRunner, logger, updater, logs) async {
      stdout.writeln('cwd: "${Directory.current.absolute.path}"');
      final directory = Directory.systemTemp.createTempSync('async_main');
      final fixture = Directory(
        path.join(Directory.current.path, 'test/fixtures/async_main'),
      );

      stdout
        ..writeln('tempDir: "${directory.absolute.path}"')
        ..writeln('fixture: "${fixture.absolute.path}"');

      await copyDirectory(fixture, directory);

      final pubGetResult = await Process.run(
        'flutter',
        ['pub', 'get'],
        workingDirectory: directory.path,
        runInShell: true,
      );

      expect(pubGetResult.exitCode, equals(ExitCode.success.code));

      final result = await commandRunner.run(['test', directory.path]);
      expect(result, equals(ExitCode.success.code));
    }),
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
