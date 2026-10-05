import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:universal_io/io.dart';
import 'package:very_good_cli/src/coverage/coverage.dart';

void main() {
  group(CoverageReport, () {
    late Directory packageRoot;
    late File lcovFile;
    late List<String> stdoutLogs;

    setUp(() {
      packageRoot = Directory.systemTemp.createTempSync('coverage_report_');
      addTearDown(() => packageRoot.deleteSync(recursive: true));
      lcovFile = File(p.join(packageRoot.path, 'coverage', 'lcov.info'));
      stdoutLogs = [];
    });

    void writeLcov(String content) => lcovFile
      ..createSync(recursive: true)
      ..writeAsStringSync(content);

    void writeSource(String path, String content) =>
        File(p.join(packageRoot.path, path))
          ..createSync(recursive: true)
          ..writeAsStringSync(content);

    FlutterCoverageReport flutterReport(CoverageOptions options) =>
        FlutterCoverageReport(packageRoot: packageRoot.path, options: options);

    test('keeps its lcov file under coverage/lcov.info', () {
      final report = flutterReport(const CoverageOptions());

      expect(report.lcovFile.path, equals(lcovFile.path));
    });

    group('collectArguments', () {
      test('are empty when coverage is not collected', () {
        expect(
          flutterReport(const CoverageOptions()).collectArguments,
          isEmpty,
        );
        expect(
          DartCoverageReport(
            packageRoot: packageRoot.path,
            options: const CoverageOptions(),
          ).collectArguments,
          isEmpty,
        );
      });

      test('make flutter test collect coverage', () {
        expect(
          flutterReport(const CoverageOptions(collect: true)).collectArguments,
          equals(['--coverage']),
        );
      });

      test('make dart test collect coverage into the coverage folder', () {
        expect(
          DartCoverageReport(
            packageRoot: packageRoot.path,
            options: const CoverageOptions(collect: true),
          ).collectArguments,
          equals(['--coverage=coverage']),
        );
      });
    });

    group('clean', () {
      test('deletes the report of a previous run', () async {
        writeLcov('SF:lib/a.dart\nend_of_record\n');

        await flutterReport(const CoverageOptions(collect: true)).clean();

        expect(lcovFile.existsSync(), isFalse);
      });

      test('completes when there is no previous report', () async {
        await flutterReport(const CoverageOptions(collect: true)).clean();

        expect(lcovFile.existsSync(), isFalse);
      });

      test('keeps the report when coverage is not collected', () async {
        writeLcov('SF:lib/a.dart\nend_of_record\n');

        await flutterReport(const CoverageOptions()).clean();

        expect(lcovFile.existsSync(), isTrue);
      });
    });

    group('writeEmpty', () {
      test('leaves an empty report behind', () async {
        await flutterReport(const CoverageOptions(collect: true)).writeEmpty();

        expect(lcovFile.readAsStringSync(), isEmpty);
      });

      test('writes nothing when coverage is not collected', () async {
        await flutterReport(const CoverageOptions()).writeEmpty();

        expect(lcovFile.existsSync(), isFalse);
      });
    });

    group('finalize', () {
      const coveredLcov =
          'SF:lib/a.dart\n'
          'DA:1,1\n'
          'DA:2,0\n'
          'LF:2\n'
          'LH:1\n'
          'end_of_record\n';

      test('keeps the lcov file flutter test wrote', () async {
        writeLcov(coveredLcov);

        await flutterReport(const CoverageOptions(collect: true))
            .finalize(stdout: stdoutLogs.add);

        expect(lcovFile.readAsStringSync(), equals(coveredLcov));
        expect(stdoutLogs, isEmpty);
      });

      test('adds the untested files when collecting from all files', () async {
        writeLcov(coveredLcov);
        writeSource('lib/a.dart', 'void a() {}\n');
        writeSource(
          'lib/b.dart',
          "import 'a.dart';\n"
              '\n'
              '// A comment.\n'
              'void b() {}\n',
        );
        writeSource('lib/b.g.dart', 'void generated() {}\n');

        await flutterReport(
          const CoverageOptions(
            collect: true,
            collectFrom: CoverageCollectionMode.all,
            excludeFromCoverage: '**/*.g.dart',
          ),
        ).finalize();

        expect(
          lcovFile.readAsStringSync(),
          equals(
            '${coveredLcov}SF:lib/b.dart\n'
            'DA:4,0\n'
            'LF:1\n'
            'LH:0\n'
            'end_of_record\n',
          ),
        );
      });

      test('matches the exclude globs relative to the package root', () async {
        writeLcov(coveredLcov);
        writeSource('lib/generated/c.dart', 'void c() {}\n');

        await flutterReport(
          const CoverageOptions(
            collect: true,
            collectFrom: CoverageCollectionMode.all,
            excludeFromCoverage: 'lib/generated/**',
          ),
        ).finalize();

        expect(lcovFile.readAsStringSync(), equals(coveredLcov));
      });

      test('marks every line but directives as untested', () async {
        writeLcov(coveredLcov);
        writeSource(
          'lib/b.dart',
          "export 'a.dart';\n"
              "part 'b.part.dart';\n"
              'void b() {}\n',
        );

        await flutterReport(
          const CoverageOptions(
            collect: true,
            collectFrom: CoverageCollectionMode.all,
          ),
        ).finalize();

        expect(
          lcovFile.readAsStringSync(),
          equals(
            '${coveredLcov}SF:lib/b.dart\n'
            'DA:3,0\n'
            'LF:1\n'
            'LH:0\n'
            'end_of_record\n',
          ),
        );
      });

      test('adds nothing for a report-on directory that is missing', () async {
        writeLcov(coveredLcov);

        await flutterReport(
          const CoverageOptions(
            collect: true,
            collectFrom: CoverageCollectionMode.all,
            reportOn: ['missing'],
          ),
        ).finalize();

        expect(lcovFile.readAsStringSync(), equals(coveredLcov));
      });

      test('throws $MinCoverageNotMet when below the threshold', () async {
        writeLcov(coveredLcov);

        await expectLater(
          flutterReport(
            const CoverageOptions(
              collect: true,
              minCoverage: 100,
              showUncovered: true,
            ),
          ).finalize(stdout: stdoutLogs.add),
          throwsA(
            isA<MinCoverageNotMet>()
                .having((error) => error.coverage, 'coverage', equals(50))
                .having(
                  (error) => error.minCoverage,
                  'minCoverage',
                  equals(100),
                )
                .having(
                  (error) => error.uncoveredLines,
                  'uncoveredLines',
                  equals({
                    'lib/a.dart': [2],
                  }),
                ),
          ),
        );
        expect(stdoutLogs, isEmpty);
      });

      test('leaves the uncovered lines out unless asked to', () async {
        writeLcov(coveredLcov);

        await expectLater(
          flutterReport(const CoverageOptions(minCoverage: 100)).finalize(),
          throwsA(
            isA<MinCoverageNotMet>().having(
              (error) => error.uncoveredLines,
              'uncoveredLines',
              isNull,
            ),
          ),
        );
      });

      test('lists the uncovered lines when the threshold is met', () async {
        writeLcov(coveredLcov);

        await flutterReport(
          const CoverageOptions(minCoverage: 50, showUncovered: true),
        ).finalize(stdout: stdoutLogs.add);

        expect(stdoutLogs, equals(['Lines not covered:\n\t- lib/a.dart: 2\n']));
      });

      test('lists nothing when every line is covered', () async {
        writeLcov('SF:lib/a.dart\nDA:1,1\nLF:1\nLH:1\nend_of_record\n');

        await flutterReport(const CoverageOptions(showUncovered: true))
            .finalize(stdout: stdoutLogs.add);

        expect(stdoutLogs, isEmpty);
      });

      test('converts the json coverage of dart test into lcov', () async {
        final source = File(p.join(packageRoot.path, 'lib', 'a.dart'))
          ..createSync(recursive: true)
          ..writeAsStringSync('void a() {}\nvoid b() {}\n');
        File(p.join(packageRoot.path, 'coverage', 'test', 'a_test.json'))
          ..createSync(recursive: true)
          ..writeAsStringSync(
            jsonEncode({
              'type': 'CodeCoverage',
              'coverage': [
                {
                  'source': source.uri.toString(),
                  'script': {
                    'type': '@Script',
                    'fixedId': true,
                    'id': 'libraries/1/scripts/a',
                    'uri': source.uri.toString(),
                    '_kind': 'library',
                  },
                  'hits': [1, 1, 2, 0],
                },
              ],
            }),
          );

        await DartCoverageReport(
          packageRoot: packageRoot.path,
          options: const CoverageOptions(collect: true),
        ).finalize();

        expect(
          lcovFile.readAsStringSync(),
          equals(
            // The coverage package writes the paths with the separator of the
            // platform.
            'SF:${p.join('lib', 'a.dart')}\n'
            'DA:1,1\n'
            'DA:2,0\n'
            'LF:2\n'
            'LH:1\n'
            'end_of_record\n',
          ),
        );
      });
    });
  });
}
