import 'package:mason/mason.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:universal_io/io.dart';
import 'package:very_good_cli/src/cli/cli.dart';

import '../../../../helpers/helpers.dart';

/// The records of the lcov report at [filePath], merged and serialized per
/// source file, so reports listing the same files in a different order compare
/// equal while lines moved between files do not.
Map<String, String> _recordsByFile(String filePath) => {
  for (final record in mergeLcovRecords(
    parseLcov(File(filePath).readAsStringSync()),
  ))
    record.file: record.toLcov(),
};

void main() {
  test(
    'merges sharded coverage into the coverage of an unsharded run',
    timeout: const Timeout(Duration(minutes: 5)),
    withRunner((commandRunner, logger, updater, logs, progressLogs) async {
      final tempDirectory = Directory.systemTemp.createTempSync('merge');
      addTearDown(() => tempDirectory.deleteSync(recursive: true));

      await copyDirectory(
        Directory(
          path.join(
            Directory.current.path,
            'test/commands/coverage/merge/fixture',
          ),
        ),
        tempDirectory,
      );
      await expectSuccessfulProcessResult('flutter', [
        'pub',
        'get',
      ], workingDirectory: tempDirectory.path);

      final cwd = Directory.current;
      Directory.current = tempDirectory;
      addTearDown(() => Directory.current = cwd);

      final lcovPath = path.join('coverage', 'lcov.info');

      await expectLater(
        commandRunner.run(['test', '--coverage']),
        completion(equals(ExitCode.success.code)),
      );
      final unshardedPath = File(lcovPath).copySync('unsharded.info').path;

      for (final shard in ['1', '2']) {
        await expectLater(
          commandRunner.run([
            'test',
            '--coverage',
            '--shard-index',
            shard,
            '--total-shards',
            '2',
          ]),
          completion(equals(ExitCode.success.code)),
        );
        final shardPath = path.join('shards', shard, 'lcov.info');
        Directory(path.dirname(shardPath)).createSync(recursive: true);
        File(lcovPath).copySync(shardPath);
      }

      await expectLater(
        commandRunner.run([
          'coverage',
          'merge',
          'shards/*/lcov.info',
          '--output',
          'merged.info',
        ]),
        completion(equals(ExitCode.success.code)),
      );
      expect(
        _recordsByFile('merged.info'),
        equals(_recordsByFile(unshardedPath)),
      );

      await expectLater(
        commandRunner.run([
          'coverage',
          'merge',
          'shards/*/lcov.info',
          '--output',
          'merged.info',
          '--min-coverage',
          '100',
        ]),
        completion(equals(ExitCode.software.code)),
      );
      verify(
        () => logger.err(
          any(that: startsWith('Expected coverage >= 100.00% but actual is ')),
        ),
      ).called(1);
    }),
  );
}
