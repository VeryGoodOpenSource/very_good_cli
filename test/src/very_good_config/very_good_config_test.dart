// Ensures we don't have to use const constructors
// and instances are created at runtime.
// ignore_for_file: prefer_const_constructors

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:very_good_cli/src/very_good_config/very_good_config.dart';

void main() {
  group(VeryGoodConfig, () {
    group('fromString', () {
      test('returns empty config when content is empty', () {
        expect(VeryGoodConfig.fromString(''), equals(VeryGoodConfig.empty));
      });

      test('returns empty config when content is null-only', () {
        expect(VeryGoodConfig.fromString('~'), equals(VeryGoodConfig.empty));
      });

      test('throws $VeryGoodConfigParseException when root is not a map', () {
        expect(
          () => VeryGoodConfig.fromString('- foo\n- bar'),
          throwsA(isA<VeryGoodConfigParseException>()),
        );
      });

      test('throws $VeryGoodConfigParseException when yaml is malformed', () {
        expect(
          () => VeryGoodConfig.fromString(':\n:'),
          throwsA(isA<VeryGoodConfigParseException>()),
        );
      });

      test('parses all supported test options', () {
        final config = VeryGoodConfig.fromString('''
test:
  coverage: true
  optimization: false
  concurrency: 8
  tags: my-tag
  exclude_coverage: "**/*.g.dart"
  exclude_tags: skip
  min_coverage: 95
  show_uncovered: true
  collect_coverage_from: all
  update_goldens: true
  fail_fast: true
  dart_define:
    - FOO=bar
    - X=42
  dart_define_from_file: defines.env
  platform: chrome
  report_on:
    - lib/
    - packages/foo/lib/
  run_skipped: true
  flavor: staging
  timeout: 30
''');

        expect(config.test.coverage, isTrue);
        expect(config.test.optimization, isFalse);
        expect(config.test.concurrency, equals('8'));
        expect(config.test.tags, equals('my-tag'));
        expect(config.test.excludeCoverage, equals('**/*.g.dart'));
        expect(config.test.excludeTags, equals('skip'));
        expect(config.test.minCoverage, equals('95'));
        expect(config.test.showUncovered, isTrue);
        expect(config.test.collectCoverageFrom, equals('all'));
        expect(config.test.updateGoldens, isTrue);
        expect(config.test.failFast, isTrue);
        expect(config.test.dartDefine, equals(['FOO=bar', 'X=42']));
        expect(config.test.dartDefineFromFile, equals(['defines.env']));
        expect(config.test.platform, equals('chrome'));
        expect(config.test.reportOn, equals(['lib/', 'packages/foo/lib/']));
        expect(config.test.runSkipped, isTrue);
        expect(config.test.flavor, equals('staging'));
        expect(config.test.timeout, equals('30'));
      });

      test('parses min-coverage as decimal string', () {
        final config = VeryGoodConfig.fromString('''
test:
  min_coverage: 95.5
''');
        expect(config.test.minCoverage, equals('95.5'));
      });

      test('parses integer options provided as quoted strings', () {
        final config = VeryGoodConfig.fromString('''
test:
  concurrency: "8"
  timeout: "60"
''');
        expect(config.test.concurrency, equals('8'));
        expect(config.test.timeout, equals('60'));
      });

      test('parses min-coverage provided as a quoted string', () {
        final config = VeryGoodConfig.fromString('''
test:
  min_coverage: "95"
''');
        expect(config.test.minCoverage, equals('95'));
      });

      test('parses collect-coverage-from with value `imports`', () {
        final config = VeryGoodConfig.fromString('''
test:
  collect_coverage_from: imports
''');
        expect(config.test.collectCoverageFrom, equals('imports'));
      });

      test('throws when test section is not a map', () {
        expect(
          () => VeryGoodConfig.fromString('test: foo'),
          throwsA(isA<VeryGoodConfigParseException>()),
        );
      });

      test('throws when bool option has wrong type', () {
        expect(
          () => VeryGoodConfig.fromString('test:\n  coverage: yes-please'),
          throwsA(isA<VeryGoodConfigParseException>()),
        );
      });

      test('throws when string option has wrong type', () {
        expect(
          () => VeryGoodConfig.fromString('test:\n  tags: [a, b]'),
          throwsA(isA<VeryGoodConfigParseException>()),
        );
      });

      test('throws when integer option has wrong type', () {
        expect(
          () => VeryGoodConfig.fromString('test:\n  concurrency: [1]'),
          throwsA(isA<VeryGoodConfigParseException>()),
        );
      });

      test('throws when number option has wrong type', () {
        expect(
          () => VeryGoodConfig.fromString('test:\n  min_coverage: [95]'),
          throwsA(isA<VeryGoodConfigParseException>()),
        );
      });

      test('throws when collect-coverage-from has invalid value', () {
        expect(
          () => VeryGoodConfig.fromString(
            'test:\n  collect_coverage_from: bad',
          ),
          throwsA(isA<VeryGoodConfigParseException>()),
        );
      });

      test('throws when string list has non-string entries', () {
        expect(
          () => VeryGoodConfig.fromString('test:\n  dart_define:\n    - 42'),
          throwsA(isA<VeryGoodConfigParseException>()),
        );
      });

      test('throws when string list has wrong type', () {
        expect(
          () => VeryGoodConfig.fromString('test:\n  report_on: 42'),
          throwsA(isA<VeryGoodConfigParseException>()),
        );
      });

      test('throws when an unrecognized root key is present', () {
        expect(
          () => VeryGoodConfig.fromString('unknown: true'),
          throwsA(isA<VeryGoodConfigParseException>()),
        );
      });

      test('throws when an unrecognized test key is present', () {
        expect(
          () => VeryGoodConfig.fromString('test:\n  min_coverag: 80'),
          throwsA(isA<VeryGoodConfigParseException>()),
        );
      });

      test('throws when min-coverage is below 0', () {
        expect(
          () => VeryGoodConfig.fromString('test:\n  min_coverage: -1'),
          throwsA(isA<VeryGoodConfigParseException>()),
        );
      });

      test('throws when min-coverage is above 100', () {
        expect(
          () => VeryGoodConfig.fromString('test:\n  min_coverage: 101'),
          throwsA(isA<VeryGoodConfigParseException>()),
        );
      });

      test('parses min-coverage at the boundaries', () {
        expect(
          VeryGoodConfig.fromString(
            'test:\n  min_coverage: 0',
          ).test.minCoverage,
          equals('0'),
        );
        expect(
          VeryGoodConfig.fromString(
            'test:\n  min_coverage: 100',
          ).test.minCoverage,
          equals('100'),
        );
      });

      test('throws when concurrency is not a positive integer', () {
        expect(
          () => VeryGoodConfig.fromString('test:\n  concurrency: 0'),
          throwsA(isA<VeryGoodConfigParseException>()),
        );
        expect(
          () => VeryGoodConfig.fromString('test:\n  concurrency: -3'),
          throwsA(isA<VeryGoodConfigParseException>()),
        );
        expect(
          () => VeryGoodConfig.fromString('test:\n  concurrency: 1.5'),
          throwsA(isA<VeryGoodConfigParseException>()),
        );
      });

      test('throws when timeout is not a positive integer', () {
        expect(
          () => VeryGoodConfig.fromString('test:\n  timeout: 0'),
          throwsA(isA<VeryGoodConfigParseException>()),
        );
        expect(
          () => VeryGoodConfig.fromString('test:\n  timeout: -30'),
          throwsA(isA<VeryGoodConfigParseException>()),
        );
      });
    });

    group('loadFromClosestAncestor', () {
      late Directory tempDir;
      late Directory nestedDir;

      setUp(() {
        tempDir = Directory.systemTemp.createTempSync('very_good_config_');
        nestedDir = Directory(
          p.join(tempDir.path, 'packages', 'foo'),
        )..createSync(recursive: true);
      });

      tearDown(() {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      });

      test('reads config from the starting directory', () {
        File(p.join(nestedDir.path, veryGoodConfigFileName)).writeAsStringSync(
          '''
test:
  min_coverage: 80
''',
        );
        final config = VeryGoodConfig.loadFromClosestAncestor(nestedDir);
        expect(config.test.minCoverage, equals('80'));
      });

      test('reads config from an ancestor directory', () {
        File(p.join(tempDir.path, veryGoodConfigFileName)).writeAsStringSync('''
test:
  min_coverage: 90
''');
        final config = VeryGoodConfig.loadFromClosestAncestor(nestedDir);
        expect(config.test.minCoverage, equals('90'));
      });

      test('prefers the closest config over an ancestor', () {
        File(p.join(tempDir.path, veryGoodConfigFileName)).writeAsStringSync('''
test:
  min_coverage: 90
''');
        File(p.join(nestedDir.path, veryGoodConfigFileName)).writeAsStringSync(
          '''
test:
  min_coverage: 80
''',
        );
        final config = VeryGoodConfig.loadFromClosestAncestor(nestedDir);
        expect(config.test.minCoverage, equals('80'));
      });

      test('returns empty config when no file is found in any ancestor', () {
        expect(
          VeryGoodConfig.loadFromClosestAncestor(nestedDir),
          equals(VeryGoodConfig.empty),
        );
      });

      test('rethrows parse exception when the closest file is malformed', () {
        File(
          p.join(nestedDir.path, veryGoodConfigFileName),
        ).writeAsStringSync('- not\n- a\n- map');
        expect(
          () => VeryGoodConfig.loadFromClosestAncestor(nestedDir),
          throwsA(isA<VeryGoodConfigParseException>()),
        );
      });
    });

    test('supports value equality', () {
      expect(VeryGoodConfig(), equals(VeryGoodConfig()));
      expect(
        VeryGoodConfig(test: VeryGoodTestConfig(coverage: true)),
        equals(VeryGoodConfig(test: VeryGoodTestConfig(coverage: true))),
      );
      expect(
        VeryGoodConfig(test: VeryGoodTestConfig(coverage: true)),
        isNot(
          equals(VeryGoodConfig(test: VeryGoodTestConfig(coverage: false))),
        ),
      );
    });
  });

  group(VeryGoodTestConfig, () {
    test('supports value equality', () {
      expect(
        VeryGoodTestConfig(coverage: true, minCoverage: '95'),
        equals(VeryGoodTestConfig(coverage: true, minCoverage: '95')),
      );
      expect(
        VeryGoodTestConfig(coverage: true),
        isNot(equals(VeryGoodTestConfig(coverage: false))),
      );
    });
  });

  group(VeryGoodConfigParseException, () {
    test('provides message via toString', () {
      const exception = VeryGoodConfigParseException('bad thing');
      expect(exception.toString(), contains('bad thing'));
    });
  });
}
