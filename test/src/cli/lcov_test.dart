import 'dart:io';

import 'package:lcov_parser/lcov_parser.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:very_good_cli/src/cli/cli.dart';

import '../../fixtures/fixtures.dart';

/// The layout `package:coverage` writes for `dart test` and `flutter test`.
const _dartLcov = '''
SF:lib/src/a.dart
FN:3,A.new
FN:7,A.call
FNDA:2,A.new
FNF:2
FNH:1
DA:3,2
DA:7,0
DA:8,0
LF:3
LH:1
BRDA:7,0,0,0
BRDA:7,0,1,1
BRF:2
BRH:1
end_of_record
''';

void main() {
  group(LcovRecord, () {
    test('cannot be modified', () {
      final record = LcovRecord(
        'a.dart',
        lines: {1: 1},
        functionLines: {'f': 1},
        functionHits: {'f': 1},
        branches: {(1, 0, 0): 1},
      );

      expect(() => record.lines[1] = 2, throwsUnsupportedError);
      expect(() => record.functionLines['f'] = 2, throwsUnsupportedError);
      expect(() => record.functionHits['f'] = 2, throwsUnsupportedError);
      expect(() => record.branches[(1, 0, 0)] = 2, throwsUnsupportedError);
    });

    test('is not affected by changes to the given maps', () {
      final lines = {1: 1};
      final record = LcovRecord('a.dart', lines: lines);

      lines[1] = 2;

      expect(record.lines, equals({1: 1}));
    });
  });

  group(parseLcov, () {
    test('parses lines, functions and branches', () {
      final [record] = parseLcov(_dartLcov);

      expect(record.file, equals('lib/src/a.dart'));
      expect(record.lines, equals({3: 2, 7: 0, 8: 0}));
      expect(record.functionLines, equals({'A.new': 3, 'A.call': 7}));
      expect(record.functionHits, equals({'A.new': 2}));
      expect(record.branches, equals({(7, 0, 0): 0, (7, 0, 1): 1}));
    });

    test('returns no records for an empty report', () {
      expect(parseLcov(''), isEmpty);
    });

    test('tolerates CRLF line endings and blank lines', () {
      final records = parseLcov(
        'SF:lib/a.dart\r\nDA:1,1\r\nend_of_record\r\n'
        '\r\n'
        'SF:lib/b.dart\r\nDA:1,0\r\nend_of_record\r\n',
      );

      expect(records.map((r) => r.file), equals(['lib/a.dart', 'lib/b.dart']));
      expect(records.last.lines, equals({1: 0}));
    });

    test('keeps colons and commas in source paths', () {
      final [record] = parseLcov(
        r'SF:C:\a,b\c.dart'
        '\nend_of_record\n',
      );

      expect(record.file, equals(r'C:\a,b\c.dart'));
    });

    test('keeps commas in function names', () {
      final [record] = parseLcov(
        'SF:a.dart\nFN:1,f<int,int>\nFNDA:1,f<int,int>\nend_of_record\n',
      );

      expect(record.functionLines, equals({'f<int,int>': 1}));
      expect(record.functionHits, equals({'f<int,int>': 1}));
    });

    test('reads the lcov 2 function layout, ignoring the end line', () {
      final [record] = parseLcov(
        'SF:a.dart\nFN:1,3,main\nFN:5,9,f<int,int>\nFNDA:1,main\n'
        'end_of_record\n',
      );

      expect(record.functionLines, equals({'main': 1, 'f<int,int>': 5}));
      expect(record.functionHits, equals({'main': 1}));
    });

    test('ignores extra branch fields', () {
      final [record] = parseLcov('SF:a.dart\nBRDA:1,0,0,2,9\nend_of_record\n');

      expect(record.branches, equals({(1, 0, 0): 2}));
    });

    test('ignores unknown tags and summaries', () {
      final [record] = parseLcov(
        'TN:\nVER:2\nSF:a.dart\nFNL:0,1,2\nDA:1,1\nLF:9\nLH:9\nend_of_record\n',
      );

      expect(record.lines, equals({1: 1}));
    });

    test('treats untaken "-" branches as not taken', () {
      final [record] = parseLcov('SF:a.dart\nBRDA:1,0,0,-\nend_of_record\n');

      expect(record.branches, equals({(1, 0, 0): 0}));
    });

    test('sums duplicated lines within a record', () {
      final [record] = parseLcov('SF:a.dart\nDA:1,1\nDA:1,2\nend_of_record\n');

      expect(record.lines, equals({1: 3}));
    });

    test('keeps a trailing record without end_of_record', () {
      final [record] = parseLcov('SF:a.dart\nDA:1,1');

      expect(record.lines, equals({1: 1}));
    });

    test('keeps a record without end_of_record before the next SF', () {
      final [a, b] = parseLcov(
        'SF:a.dart\nDA:1,1\nSF:b.dart\nDA:2,0\nend_of_record\n',
      );

      expect(a.file, equals('a.dart'));
      expect(a.lines, equals({1: 1}));
      expect(b.file, equals('b.dart'));
      expect(b.lines, equals({2: 0}));
    });

    group('throws $FormatException', () {
      for (final (description, content) in [
        ('for a line without a tag', 'SF:a.dart\nfoo\n'),
        ('for details before any SF', 'DA:1,1\n'),
        ('for a non numeric value', 'SF:a.dart\nDA:1,x\n'),
        ('for a missing value', 'SF:a.dart\nBRDA:1,0\n'),
        ('for a function without a name', 'SF:a.dart\nFN:1\n'),
        ('for function hits without a name', 'SF:a.dart\nFNDA:1,\n'),
      ]) {
        test(description, () {
          expect(() => parseLcov(content), throwsFormatException);
        });
      }
    });
  });

  group(mergeLcovRecords, () {
    test('sums hits of records for the same file', () {
      final [record] = mergeLcovRecords([
        ...parseLcov(_dartLcov),
        ...parseLcov(
          'SF:lib/src/a.dart\nFN:7,A.call\nFNDA:1,A.call\n'
          'DA:3,1\nDA:7,1\nBRDA:7,0,0,1\nend_of_record\n',
        ),
      ]);

      expect(record.lines, equals({3: 3, 7: 1, 8: 0}));
      expect(record.functionHits, equals({'A.new': 2, 'A.call': 1}));
      expect(record.functionLines, equals({'A.new': 3, 'A.call': 7}));
      expect(record.branches, equals({(7, 0, 0): 1, (7, 0, 1): 1}));
    });

    test('keeps distinct files in first seen order', () {
      final records = mergeLcovRecords([
        ...parseLcov('SF:b.dart\nDA:1,1\nend_of_record\n'),
        ...parseLcov('SF:a.dart\nDA:1,1\nend_of_record\n'),
        ...parseLcov('SF:b.dart\nDA:2,1\nend_of_record\n'),
      ]);

      expect(records.map((r) => r.file), equals(['b.dart', 'a.dart']));
      expect(records.first.lines, equals({1: 1, 2: 1}));
    });

    test('covers a padded 0% record with hits from another report', () {
      final [record] = mergeLcovRecords([
        ...parseLcov('SF:a.dart\nDA:1,0\nDA:2,0\nLF:2\nLH:0\nend_of_record\n'),
        ...parseLcov('SF:a.dart\nDA:1,1\nDA:2,3\nLF:2\nLH:2\nend_of_record\n'),
      ]);

      expect(record.toLcov(), contains('LH:2\n'));
    });

    test('accepts empty reports', () {
      final records = mergeLcovRecords([
        ...parseLcov(''),
        ...parseLcov('SF:a.dart\nDA:1,1\nend_of_record\n'),
      ]);

      expect(records, hasLength(1));
    });

    test('does not modify the given records', () {
      final records = parseLcov('SF:a.dart\nDA:1,1\nend_of_record\n');

      mergeLcovRecords([...records, ...records]);

      expect(records.single.lines, equals({1: 1}));
    });
  });

  group(formatLcovRecords, () {
    test('recomputes summaries from the details', () {
      final record = LcovRecord(
        'a.dart',
        lines: {2: 0, 1: 4},
        functionLines: {'f': 1, 'g': 2},
        functionHits: {'f': 1, 'g': 0},
        branches: {(1, 0, 1): 0, (1, 0, 0): 2},
      );

      expect(
        formatLcovRecords([record]),
        equals('''
SF:a.dart
FN:1,f
FN:2,g
FNDA:1,f
FNF:2
FNH:1
DA:1,4
DA:2,0
LF:2
LH:1
BRDA:1,0,0,2
BRDA:1,0,1,0
BRF:2
BRH:1
end_of_record
'''),
      );
    });

    test('round-trips the package:coverage layout', () {
      expect(formatLcovRecords(parseLcov(_dartLcov)), equals(_dartLcov));
    });

    test('round-trips flutter reports', () {
      for (final lcov in [lcov100, lcov95]) {
        expect(formatLcovRecords(parseLcov(lcov)), equals(lcov));
      }
    });

    test('is readable by package:lcov_parser', () {
      final merged = formatLcovRecords(parseLcov(lcov95));

      final records = Parser.parseLines(merged.split('\n'));
      final expected = Parser.parseLines(lcov95.split('\n'));

      List<(String?, int?, int?)> summaries(List<Record> records) => [
        for (final record in records)
          (record.file, record.lines?.found, record.lines?.hit),
      ];

      expect(summaries(records), equals(summaries(expected)));
    });

    test('sorts branches by line, block and branch', () {
      final record = LcovRecord(
        'a.dart',
        branches: {(2, 0, 0): 1, (1, 1, 0): 1, (1, 0, 1): 1, (1, 0, 0): 1},
      );

      expect(
        RegExp('BRDA:(.*)').allMatches(record.toLcov()).map((m) => m[1]),
        equals(['1,0,0,1', '1,0,1,1', '1,1,0,1', '2,0,0,1']),
      );
    });
  });

  group(expandLcovGlob, () {
    late Directory directory;

    setUp(() {
      directory = Directory.systemTemp.createTempSync();
      addTearDown(() => directory.deleteSync(recursive: true));
    });

    test('returns the matched files, relative and sorted', () {
      for (final shard in ['2', '1']) {
        File(p.join(directory.path, 'shards', shard, 'lcov.info'))
          ..createSync(recursive: true)
          ..writeAsStringSync('');
      }
      Directory(p.join(directory.path, 'shards', 'dir.info')).createSync();

      expect(
        expandLcovGlob('shards/**.info', cwd: directory.path),
        equals([
          p.join('shards', '1', 'lcov.info'),
          p.join('shards', '2', 'lcov.info'),
        ]),
      );
    });

    test('throws $FormatException for an invalid glob', () {
      expect(
        () => expandLcovGlob('[', cwd: directory.path),
        throwsFormatException,
      );
    });
  });

  group(discoverLcovPackages, () {
    late Directory directory;

    setUp(() {
      directory = Directory.systemTemp.createTempSync();
      addTearDown(() => directory.deleteSync(recursive: true));
    });

    void createPackage(String path, {bool withReport = true}) {
      File(p.join(directory.path, path, 'pubspec.yaml'))
        ..createSync(recursive: true)
        ..writeAsStringSync('name: package');
      if (withReport) {
        File(p.join(directory.path, path, 'coverage', 'lcov.info'))
          ..createSync(recursive: true)
          ..writeAsStringSync('');
      }
    }

    test('returns the packages with a report, sorted', () {
      createPackage('.');
      createPackage(p.join('packages', 'b'));
      createPackage(p.join('packages', 'a'));

      expect(
        discoverLcovPackages(directory.path),
        equals(['.', p.join('packages', 'a'), p.join('packages', 'b')]),
      );
    });

    test('skips packages without a report', () {
      createPackage(p.join('packages', 'a'));
      createPackage(p.join('packages', 'b'), withReport: false);

      expect(
        discoverLcovPackages(directory.path),
        equals([p.join('packages', 'a')]),
      );
    });

    test('skips platform, build and tool directories', () {
      createPackage(p.join('packages', 'a'));
      createPackage(p.join('packages', 'a', 'build', 'generated'));
      createPackage(p.join('packages', 'a', 'ios', 'plugin'));
      createPackage(p.join('.dart_tool', 'cache'));

      expect(
        discoverLcovPackages(directory.path),
        equals([p.join('packages', 'a')]),
      );
    });

    test('returns nothing without packages', () {
      expect(discoverLcovPackages(directory.path), isEmpty);
    });
  });

  group(normalizeLcovRecords, () {
    final posix = p.Context(style: p.Style.posix, current: '/repo');
    final windows = p.Context(style: p.Style.windows, current: r'C:\repo');

    List<String> normalize(
      List<String> files, {
      String? packagePath,
      p.Context? context,
      void Function(String)? onExternalPath,
    }) => normalizeLcovRecords(
      files.map(LcovRecord.new),
      packagePath: packagePath,
      context: context ?? posix,
      onExternalPath: onExternalPath,
    ).map((record) => record.file).toList();

    test('keeps relative paths without a package path', () {
      expect(normalize(['lib/a.dart', './lib/b.dart']), [
        'lib/a.dart',
        'lib/b.dart',
      ]);
    });

    test('rebases relative paths onto the package path', () {
      expect(
        normalize(['lib/a.dart'], packagePath: 'packages/foo'),
        equals(['packages/foo/lib/a.dart']),
      );
      expect(normalize(['lib/a.dart'], packagePath: '.'), ['lib/a.dart']);
    });

    test('converts Windows separators', () {
      expect(
        normalize([r'lib\src\a.dart'], packagePath: 'packages/foo'),
        equals(['packages/foo/lib/src/a.dart']),
      );
      expect(
        normalize(
          [r'lib\src\a.dart'],
          packagePath: r'packages\foo',
          context: windows,
        ),
        equals(['packages/foo/lib/src/a.dart']),
      );
    });

    test('makes absolute paths under the current directory relative', () {
      expect(
        normalize([
          '/repo/packages/foo/lib/a.dart',
        ], packagePath: 'packages/foo'),
        equals(['packages/foo/lib/a.dart']),
      );
      expect(
        normalize([r'c:\repo\lib\a.dart'], context: windows),
        equals(['lib/a.dart']),
      );
    });

    test('keeps and reports absolute paths outside the current directory', () {
      final external = <String>[];

      final files = normalize(
        ['/other/lib/a.dart', r'D:\runner\lib\a.dart', 'lib/b.dart'],
        packagePath: 'packages/foo',
        onExternalPath: external.add,
      );

      expect(files, [
        '/other/lib/a.dart',
        'D:/runner/lib/a.dart',
        'packages/foo/lib/b.dart',
      ]);
      expect(external, ['/other/lib/a.dart', 'D:/runner/lib/a.dart']);
    });

    test('does not modify the given records', () {
      final record = LcovRecord('lib/a.dart', lines: {1: 1});

      final [normalized] = normalizeLcovRecords([record], packagePath: 'foo');

      expect(normalized.file, equals('foo/lib/a.dart'));
      expect(normalized.lines, equals({1: 1}));
      expect(record.file, equals('lib/a.dart'));
    });
  });
}
