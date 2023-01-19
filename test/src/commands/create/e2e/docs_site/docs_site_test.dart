@Tags(['e2e'])
import 'package:mason/mason.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:universal_io/io.dart';

import '../../../../../helpers/helpers.dart';

void main() {
  test(
    'create docs_site',
    withRunner((commandRunner, logger, updater, logs) async {
      final directory = Directory.systemTemp.createTempSync();
      final result = await commandRunner.run(
        ['create', 'docs_site', 'very_good_docs_site', '-o', directory.path],
      );
      expect(result, equals(ExitCode.success.code));

      final installResult = await Process.run(
        'npm',
        ['install'],
        workingDirectory: path.join(directory.path, 'very_good_docs_site'),
        runInShell: true,
      );
      expect(installResult.exitCode, equals(ExitCode.success.code));

      final formatResult = await Process.run(
        'npm',
        ['run', 'format'],
        workingDirectory: path.join(directory.path, 'very_good_docs_site'),
        runInShell: true,
      );
      expect(formatResult.exitCode, equals(ExitCode.success.code));
      expect(formatResult.stderr, isEmpty);

      final lintResult = await Process.run(
        'npm',
        ['run', 'lint'],
        workingDirectory: path.join(directory.path, 'very_good_docs_site'),
        runInShell: true,
      );
      expect(lintResult.exitCode, equals(ExitCode.success.code));
      expect(lintResult.stderr, isEmpty);

      final buildResult = await Process.run(
        'npm',
        ['run', 'build'],
        workingDirectory: path.join(directory.path, 'very_good_docs_site'),
        runInShell: true,
      );
      expect(buildResult.exitCode, equals(ExitCode.success.code));
      expect(buildResult.stderr, isEmpty);
    }),
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
