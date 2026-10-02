// Expected usage of the plugin will need to be adjacent strings due to format
// and also be longer than 80 chars.
// ignore_for_file: no_adjacent_strings_in_list, lines_longer_than_80_chars

import 'dart:io';

import 'package:mason/mason.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../../../helpers/helpers.dart';

const _expectedMergeUsage = [
  'Merge lcov reports, from sharded or recursive test runs, and check the merged coverage.\n'
      '\n'
      'Usage: very_good coverage merge [lcov files or globs] [arguments]\n'
      '-h, --help                Print this usage information.\n'
      '-o, --output=<path>       The path to write the merged lcov report to.\n'
      '                          (defaults to "coverage/lcov.info")\n'
      '    --min-coverage        Whether to enforce a minimum coverage percentage.\n'
      "    --exclude-coverage    A glob which will be used to exclude files that match from the coverage (e.g. '**/*.g.dart').\n"
      '    --show-uncovered      Whether to show uncovered lines when coverage is below 100%.\n'
      '\n'
      'Run "very_good help" to see global options.',
];

/// The first shard covers line 1 of `a.dart`, the second one line 2, and
/// neither covers `b.dart`.
const _shard1 = '''
SF:lib/a.dart
DA:1,1
DA:2,0
LF:2
LH:1
end_of_record
SF:lib/b.dart
DA:1,0
LF:1
LH:0
end_of_record
''';

const _shard2 = '''
SF:lib/a.dart
DA:1,0
DA:2,2
LF:2
LH:1
end_of_record
''';

const _merged = '''
SF:lib/a.dart
DA:1,1
DA:2,2
LF:2
LH:2
end_of_record
SF:lib/b.dart
DA:1,0
LF:1
LH:0
end_of_record
''';

/// Makes a fresh temporary directory the current one for the test.
Directory _enterTempDirectory() {
  final previous = Directory.current;
  final directory = Directory.systemTemp.createTempSync();
  Directory.current = directory;
  addTearDown(() {
    Directory.current = previous;
    directory.deleteSync(recursive: true);
  });
  return Directory.current;
}

void _writeFile(String path, String content) {
  File(path)
    ..createSync(recursive: true)
    ..writeAsStringSync(content);
}

void _writePackage(String path, String lcov) {
  _writeFile(p.join(path, 'pubspec.yaml'), 'name: ${p.basename(path)}');
  _writeFile(p.join(path, 'coverage', 'lcov.info'), lcov);
}

void _writeShards() {
  _writeFile(p.join('shards', '1', 'lcov.info'), _shard1);
  _writeFile(p.join('shards', '2', 'lcov.info'), _shard2);
}

String _readOutput([String path = 'coverage/lcov.info']) =>
    File(path).readAsStringSync();

void main() {
  group('coverage merge', () {
    test(
      'help',
      withRunner((commandRunner, logger, pubUpdater, printLogs) async {
        final result = await commandRunner.run(['coverage', 'merge', '--help']);

        expect(printLogs, equals(_expectedMergeUsage));
        expect(result, equals(ExitCode.success.code));
      }),
    );

    test(
      'merges the given lcov files into coverage/lcov.info',
      withRunner((commandRunner, logger, pubUpdater, printLogs) async {
        _enterTempDirectory();
        _writeShards();

        final result = await commandRunner.run([
          'coverage',
          'merge',
          'shards/1/lcov.info',
          'shards/2/lcov.info',
        ]);

        expect(result, equals(ExitCode.success.code));
        expect(_readOutput(), equals(_merged));
        verify(
          () => logger.info('Merged 2 lcov report(s) into coverage/lcov.info'),
        ).called(1);
      }),
    );

    test(
      'writes to --output, creating its directory',
      withRunner((commandRunner, logger, pubUpdater, printLogs) async {
        _enterTempDirectory();
        _writeShards();

        final result = await commandRunner.run([
          'coverage',
          'merge',
          'shards/1/lcov.info',
          'shards/2/lcov.info',
          '-o',
          'out/merged.info',
        ]);

        expect(result, equals(ExitCode.success.code));
        expect(_readOutput('out/merged.info'), equals(_merged));
      }),
    );

    test(
      'can overwrite one of its inputs',
      withRunner((commandRunner, logger, pubUpdater, printLogs) async {
        _enterTempDirectory();
        _writeShards();

        final result = await commandRunner.run([
          'coverage',
          'merge',
          'shards/1/lcov.info',
          'shards/2/lcov.info',
          '-o',
          'shards/1/lcov.info',
        ]);

        expect(result, equals(ExitCode.success.code));
        expect(_readOutput('shards/1/lcov.info'), equals(_merged));
      }),
    );

    test(
      'expands globs, merging each matched file once',
      withRunner((commandRunner, logger, pubUpdater, printLogs) async {
        _enterTempDirectory();
        _writeShards();

        final result = await commandRunner.run([
          'coverage',
          'merge',
          'shards/*/lcov.info',
          'shards/1/lcov.info',
        ]);

        expect(result, equals(ExitCode.success.code));
        expect(_readOutput(), equals(_merged));
        verify(
          () => logger.info('Merged 2 lcov report(s) into coverage/lcov.info'),
        ).called(1);
      }),
    );

    test(
      'merges a file once when given as an absolute path and by a glob',
      withRunner((commandRunner, logger, pubUpdater, printLogs) async {
        final cwd = _enterTempDirectory();
        _writeShards();

        final result = await commandRunner.run([
          'coverage',
          'merge',
          p.join(cwd.path, 'shards', '1', 'lcov.info'),
          'shards/*/lcov.info',
        ]);

        expect(result, equals(ExitCode.success.code));
        expect(_readOutput(), equals(_merged));
        verify(
          () => logger.info('Merged 2 lcov report(s) into coverage/lcov.info'),
        ).called(1);
      }),
    );

    test(
      'skips the --output report when matched by a glob',
      withRunner((commandRunner, logger, pubUpdater, printLogs) async {
        _enterTempDirectory();
        _writeShards();
        _writeFile(p.join('coverage', 'lcov.info'), _merged);

        final result = await commandRunner.run([
          'coverage',
          'merge',
          '**/lcov.info',
        ]);

        expect(result, equals(ExitCode.success.code));
        expect(_readOutput(), equals(_merged));
        verify(
          () => logger.warn(
            'Skipping ${p.join('coverage', 'lcov.info')}, since it is the '
            '--output report. Pass a different --output to merge it too.',
          ),
        ).called(1);
        verify(
          () => logger.info('Merged 2 lcov report(s) into coverage/lcov.info'),
        ).called(1);
      }),
    );

    test(
      'makes absolute source paths under the current directory relative',
      withRunner((commandRunner, logger, pubUpdater, printLogs) async {
        final cwd = _enterTempDirectory();
        _writeFile(
          'shard.info',
          'SF:${p.join(cwd.path, 'lib', 'a.dart')}\nDA:1,1\nend_of_record\n',
        );

        final result = await commandRunner.run([
          'coverage',
          'merge',
          'shard.info',
        ]);

        expect(result, equals(ExitCode.success.code));
        expect(_readOutput(), startsWith('SF:lib/a.dart\n'));
        verifyNever(() => logger.warn(any()));
      }),
    );

    test(
      'warns about absolute source paths outside the current directory',
      withRunner((commandRunner, logger, pubUpdater, printLogs) async {
        final cwd = _enterTempDirectory();
        _writeFile(
          'shard.info',
          'SF:/elsewhere/a.dart\nDA:1,1\nend_of_record\n',
        );

        final result = await commandRunner.run([
          'coverage',
          'merge',
          'shard.info',
        ]);

        expect(result, equals(ExitCode.success.code));
        verify(
          () => logger.warn(
            'These source paths are outside of ${cwd.path} and were kept as '
            'is, so they will not match the same files from other reports:\n'
            '  - /elsewhere/a.dart',
          ),
        ).called(1);
      }),
    );

    group('with package reports', () {
      test(
        'rebases the given reports onto their package',
        withRunner((commandRunner, logger, pubUpdater, printLogs) async {
          _enterTempDirectory();
          _writePackage(p.join('packages', 'foo'), _shard1);
          _writePackage(p.join('packages', 'bar'), _shard2);

          final result = await commandRunner.run([
            'coverage',
            'merge',
            'packages/foo/coverage/lcov.info',
            'packages/bar/coverage/lcov.info',
          ]);

          expect(result, equals(ExitCode.success.code));
          expect(
            _readOutput(),
            allOf(
              contains('SF:packages/foo/lib/a.dart\n'),
              contains('SF:packages/foo/lib/b.dart\n'),
              contains('SF:packages/bar/lib/a.dart\n'),
              isNot(contains('SF:lib/')),
            ),
          );
        }),
      );

      test(
        'does not rebase a coverage/lcov.info report outside of a package',
        withRunner((commandRunner, logger, pubUpdater, printLogs) async {
          _enterTempDirectory();
          _writeFile(p.join('shard', 'coverage', 'lcov.info'), _shard2);

          final result = await commandRunner.run([
            'coverage',
            'merge',
            'shard/coverage/lcov.info',
          ]);

          expect(result, equals(ExitCode.success.code));
          expect(_readOutput(), startsWith('SF:lib/a.dart\n'));
        }),
      );

      test(
        'skips glob matches in platform, build and tool directories',
        withRunner((commandRunner, logger, pubUpdater, printLogs) async {
          _enterTempDirectory();
          _writePackage(p.join('packages', 'foo'), _shard1);
          _writePackage(p.join('packages', 'foo', 'build', 'pkg'), _shard2);

          final result = await commandRunner.run([
            'coverage',
            'merge',
            'packages/**/lcov.info',
          ]);

          expect(result, equals(ExitCode.success.code));
          expect(_readOutput(), isNot(contains('build')));
          verify(
            () => logger.warn(
              'Skipping these reports matched by "packages/**/lcov.info", '
              'since they are in platform, build or tool directories. Pass '
              'their paths to merge them too:\n'
              '  - ${p.join('packages', 'foo', 'build', 'pkg', 'coverage', 'lcov.info')}',
            ),
          ).called(1);
          verify(
            () =>
                logger.info('Merged 1 lcov report(s) into coverage/lcov.info'),
          ).called(1);
        }),
      );
    });

    group('without lcov files', () {
      test(
        'merges the report of every package, keeping their files distinct',
        withRunner((commandRunner, logger, pubUpdater, printLogs) async {
          _enterTempDirectory();
          _writePackage(p.join('packages', 'foo'), _shard1);
          _writePackage(p.join('packages', 'bar'), _shard2);
          for (final ignored in ['build', '.dart_tool', '.fvm', 'ios']) {
            _writePackage(p.join('packages', 'foo', ignored, 'pkg'), _shard1);
          }
          // A package without tests leaves no report behind.
          _writeFile(p.join('packages', 'baz', 'pubspec.yaml'), 'name: baz');

          final result = await commandRunner.run(['coverage', 'merge']);

          expect(result, equals(ExitCode.success.code));
          expect(
            _readOutput(),
            equals('''
SF:packages/bar/lib/a.dart
DA:1,0
DA:2,2
LF:2
LH:1
end_of_record
SF:packages/foo/lib/a.dart
DA:1,1
DA:2,0
LF:2
LH:1
end_of_record
SF:packages/foo/lib/b.dart
DA:1,0
LF:1
LH:0
end_of_record
'''),
          );
          verify(
            () =>
                logger.info('Merged 2 lcov report(s) into coverage/lcov.info'),
          ).called(1);
        }),
      );

      test(
        'skips the --output report',
        withRunner((commandRunner, logger, pubUpdater, printLogs) async {
          _enterTempDirectory();
          _writePackage('.', 'SF:stale.dart\nDA:1,1\nend_of_record\n');
          _writePackage('foo', _shard2);

          final result = await commandRunner.run(['coverage', 'merge']);

          expect(result, equals(ExitCode.success.code));
          expect(_readOutput(), startsWith('SF:foo/lib/a.dart\n'));
          expect(_readOutput(), isNot(contains('stale.dart')));
          verify(
            () => logger.warn(
              'Skipping ${p.join('coverage', 'lcov.info')}, since it is the '
              '--output report. Pass a different --output to merge it too.',
            ),
          ).called(1);
        }),
      );

      test(
        'merges the root report into a different --output',
        withRunner((commandRunner, logger, pubUpdater, printLogs) async {
          _enterTempDirectory();
          _writePackage('.', _shard1);
          _writePackage('foo', _shard2);

          final result = await commandRunner.run([
            'coverage',
            'merge',
            '-o',
            'merged.info',
          ]);

          expect(result, equals(ExitCode.success.code));
          expect(
            _readOutput('merged.info'),
            allOf(contains('SF:lib/a.dart\n'), contains('SF:foo/lib/a.dart\n')),
          );
        }),
      );
    });

    group('fails', () {
      test(
        'when no lcov file is given and none is found',
        withRunner((commandRunner, logger, pubUpdater, printLogs) async {
          final cwd = _enterTempDirectory();
          // A package without a report.
          _writeFile('pubspec.yaml', 'name: root');

          final result = await commandRunner.run(['coverage', 'merge']);

          expect(result, equals(ExitCode.noInput.code));
          verify(
            () => logger.err(
              'No lcov reports found in ${cwd.path}. Run '
              '"very_good test --recursive --coverage" first, or pass the lcov '
              'files or globs to merge.',
            ),
          ).called(1);
        }),
      );

      test(
        'when a file or glob matches nothing',
        withRunner((commandRunner, logger, pubUpdater, printLogs) async {
          _enterTempDirectory();
          _writeShards();

          final result = await commandRunner.run([
            'coverage',
            'merge',
            'shards/1/lcov.info',
            'missing/*.info',
          ]);

          expect(result, equals(ExitCode.noInput.code));
          verify(() => logger.err('No lcov report found at "missing/*.info".'))
              .called(1);
          expect(File('coverage/lcov.info').existsSync(), isFalse);
        }),
      );

      test(
        'when a glob is invalid',
        withRunner((commandRunner, logger, pubUpdater, printLogs) async {
          _enterTempDirectory();

          final result = await commandRunner.run(['coverage', 'merge', '[']);

          expect(result, equals(ExitCode.usage.code));
          verify(() => logger.err(any(that: startsWith('Invalid glob "[": '))))
              .called(1);
        }),
      );

      test(
        'when an lcov file cannot be parsed',
        withRunner((commandRunner, logger, pubUpdater, printLogs) async {
          _enterTempDirectory();
          _writeFile('shard.info', 'not lcov\n');

          final result = await commandRunner.run([
            'coverage',
            'merge',
            'shard.info',
          ]);

          expect(result, equals(ExitCode.data.code));
          verify(
            () => logger.err(
              'Could not parse the lcov report "shard.info": '
              'Invalid lcov line "not lcov".',
            ),
          ).called(1);
        }),
      );

      test(
        'when a glob only matches reports in ignored directories',
        withRunner((commandRunner, logger, pubUpdater, printLogs) async {
          _enterTempDirectory();
          _writeFile(p.join('build', 'coverage', 'lcov.info'), _shard1);

          final result = await commandRunner.run([
            'coverage',
            'merge',
            'build/**.info',
          ]);

          expect(result, equals(ExitCode.noInput.code));
          verify(
            () => logger.warn(
              any(that: contains(p.join('build', 'coverage', 'lcov.info'))),
            ),
          ).called(1);
          verify(() => logger.err('No lcov report found at "build/**.info".'))
              .called(1);
        }),
      );

      test(
        'when an lcov file cannot be read',
        withRunner((commandRunner, logger, pubUpdater, printLogs) async {
          _enterTempDirectory();
          File('shard.info').writeAsBytesSync([0xff, 0xfe, 0xfd]);

          final result = await commandRunner.run([
            'coverage',
            'merge',
            'shard.info',
          ]);

          expect(result, equals(ExitCode.ioError.code));
          verify(() => logger.err(any(that: contains('FileSystemException'))))
              .called(1);
        }),
      );

      test(
        'when the --output cannot be written',
        withRunner((commandRunner, logger, pubUpdater, printLogs) async {
          _enterTempDirectory();
          _writeShards();
          Directory('out').createSync();

          final result = await commandRunner.run([
            'coverage',
            'merge',
            'shards/1/lcov.info',
            '-o',
            'out',
          ]);

          expect(result, equals(ExitCode.ioError.code));
          verify(() => logger.err(any(that: contains('FileSystemException'))))
              .called(1);
        }),
      );

      test(
        'when a glob only matches the --output report',
        withRunner((commandRunner, logger, pubUpdater, printLogs) async {
          _enterTempDirectory();
          _writeFile(p.join('coverage', 'lcov.info'), _merged);

          final result = await commandRunner.run([
            'coverage',
            'merge',
            'coverage/*.info',
          ]);

          expect(result, equals(ExitCode.noInput.code));
          verify(() => logger.err('No lcov report found at "coverage/*.info".'))
              .called(1);
        }),
      );

      test(
        'when --min-coverage is not a number',
        withRunner((commandRunner, logger, pubUpdater, printLogs) async {
          _enterTempDirectory();
          _writeShards();

          final result = await commandRunner.run([
            'coverage',
            'merge',
            'shards/1/lcov.info',
            '--min-coverage',
            'abc',
          ]);

          expect(result, equals(ExitCode.usage.code));
          verify(
            () => logger.err('--min-coverage must be a number, but got "abc".'),
          ).called(1);
        }),
      );

      test(
        'when very_good.yaml is invalid',
        withRunner((commandRunner, logger, pubUpdater, printLogs) async {
          _enterTempDirectory();
          _writeFile('very_good.yaml', 'test:\n  min_coverage: abc\n');

          final result = await commandRunner.run(['coverage', 'merge']);

          expect(result, equals(ExitCode.config.code));
        }),
      );
    });

    group('--min-coverage', () {
      test(
        'succeeds when the merged coverage meets it',
        withRunner((commandRunner, logger, pubUpdater, printLogs) async {
          _enterTempDirectory();
          _writeShards();

          final result = await commandRunner.run([
            'coverage',
            'merge',
            'shards/*/lcov.info',
            '--min-coverage',
            '66',
          ]);

          expect(result, equals(ExitCode.success.code));
          verifyNever(() => logger.err(any()));
        }),
      );

      test(
        'fails like very_good test when the merged coverage is below it',
        withRunner((commandRunner, logger, pubUpdater, printLogs) async {
          _enterTempDirectory();
          _writeShards();

          final result = await commandRunner.run([
            'coverage',
            'merge',
            'shards/*/lcov.info',
            '--min-coverage',
            '100',
            '--show-uncovered',
          ]);

          expect(result, equals(ExitCode.software.code));
          verify(
            () => logger.err(
              'Expected coverage >= 100.00% but actual is 66.67%.',
            ),
          ).called(1);
          verify(() => logger.err('Lines not covered:\n\t- lib/b.dart: 1'))
              .called(1);
          expect(_readOutput(), equals(_merged));
        }),
      );

      test(
        'ignores files matching --exclude-coverage',
        withRunner((commandRunner, logger, pubUpdater, printLogs) async {
          _enterTempDirectory();
          _writeShards();

          final result = await commandRunner.run([
            'coverage',
            'merge',
            'shards/*/lcov.info',
            '--min-coverage',
            '100',
            '--exclude-coverage',
            'lib/b.dart',
          ]);

          expect(result, equals(ExitCode.success.code));
        }),
      );

      for (final glob in ['lib/src/gen/**', '**/*.g.dart']) {
        test(
          'ignores package files matching the --exclude-coverage $glob',
          withRunner((commandRunner, logger, pubUpdater, printLogs) async {
            _enterTempDirectory();
            _writePackage(
              p.join('packages', 'foo'),
              'SF:lib/a.dart\nDA:1,1\nend_of_record\n'
              'SF:lib/src/gen/b.g.dart\nDA:1,0\nend_of_record\n',
            );

            final result = await commandRunner.run([
              'coverage',
              'merge',
              '--min-coverage',
              '100',
              '--exclude-coverage',
              glob,
            ]);

            expect(result, equals(ExitCode.success.code));
            expect(
              _readOutput(),
              contains('SF:packages/foo/lib/src/gen/b.g.dart\n'),
            );
          }),
        );
      }

      test(
        'ignores external Windows source paths matching --exclude-coverage',
        withRunner((commandRunner, logger, pubUpdater, printLogs) async {
          _enterTempDirectory();
          _writeFile(
            'shard.info',
            'SF:lib/a.dart\nDA:1,1\nend_of_record\n'
                'SF:C:\\runner\\lib\\a.g.dart\nDA:1,0\nend_of_record\n',
          );

          final result = await commandRunner.run([
            'coverage',
            'merge',
            'shard.info',
            '--min-coverage',
            '100',
            '--exclude-coverage',
            '**/*.g.dart',
          ]);

          expect(result, equals(ExitCode.success.code));
          expect(_readOutput(), contains('SF:C:/runner/lib/a.g.dart\n'));
        }),
      );
    });

    test(
      '--show-uncovered logs uncovered lines when there is no threshold',
      withRunner((commandRunner, logger, pubUpdater, printLogs) async {
        _enterTempDirectory();
        _writeShards();

        final result = await commandRunner.run([
          'coverage',
          'merge',
          'shards/*/lcov.info',
          '--show-uncovered',
        ]);

        expect(result, equals(ExitCode.success.code));
        verify(() => logger.write('Lines not covered:\n\t- lib/b.dart: 1\n'))
            .called(1);
      }),
    );

    group('very_good.yaml', () {
      test(
        'uses the test section',
        withRunner((commandRunner, logger, pubUpdater, printLogs) async {
          _enterTempDirectory();
          _writeShards();
          _writeFile(
            'very_good.yaml',
            'test:\n  min_coverage: 100\n  show_uncovered: true\n'
                'dart:\n  test:\n    min_coverage: 50\n',
          );

          final result = await commandRunner.run([
            'coverage',
            'merge',
            'shards/*/lcov.info',
          ]);

          expect(result, equals(ExitCode.software.code));
          verify(() => logger.err('Lines not covered:\n\t- lib/b.dart: 1'))
              .called(1);
        }),
      );

      test(
        'falls back to the dart test section',
        withRunner((commandRunner, logger, pubUpdater, printLogs) async {
          _enterTempDirectory();
          _writeShards();
          _writeFile(
            'very_good.yaml',
            'dart:\n  test:\n    min_coverage: 100\n'
                '    exclude_coverage: lib/b.dart\n',
          );

          final result = await commandRunner.run([
            'coverage',
            'merge',
            'shards/*/lcov.info',
          ]);

          expect(result, equals(ExitCode.success.code));
        }),
      );

      test(
        'is overridden by command line arguments',
        withRunner((commandRunner, logger, pubUpdater, printLogs) async {
          _enterTempDirectory();
          _writeShards();
          _writeFile('very_good.yaml', 'test:\n  min_coverage: 100\n');

          final result = await commandRunner.run([
            'coverage',
            'merge',
            'shards/*/lcov.info',
            '--min-coverage',
            '50',
          ]);

          expect(result, equals(ExitCode.success.code));
        }),
      );
    });
  });
}
