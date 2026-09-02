import 'dart:io';
import 'dart:math';

import 'package:hooks/pre_gen.dart' as pre_gen;
import 'package:mason/mason.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

class _MockLogger extends Mock implements Logger {}

class _FakeContext extends Fake implements HookContext {
  @override
  final logger = _MockLogger();

  @override
  Map<String, Object?> vars = {};
}

final notOptimizedTestContent =
    '''
@Tags(['${pre_gen.skipVeryGoodOptimizationTag}'])
void main() {
  test('test', () {
    expect(1, 1);
  });
}
''';

final anotherNotOptimizedTestContent =
    '''
@Tags(['${pre_gen.skipVeryGoodOptimizationTag}', 'another_tag'])
void main() {
  test('another test', () {
    expect(1, 1);
  });
}
''';

void main() {
  late Directory tempDirectory;

  setUp(() {
    tempDirectory = Directory.systemTemp.createTempSync('test_optimizer');
  });

  tearDown(() {
    tempDirectory.deleteSync(recursive: true);
  });

  group('Pre gen hook', () {
    late HookContext context;

    setUp(() {
      context = _FakeContext();
    });

    group('Completes', () {
      test('with test files list', () async {
        File(path.join(tempDirectory.path, 'pubspec.yaml')).createSync();

        final testDir = Directory(path.join(tempDirectory.path, 'test'))
          ..createSync();
        File(path.join(testDir.path, 'test1_test.dart')).createSync();
        File(path.join(testDir.path, 'test2_test.dart')).createSync();
        File(path.join(testDir.path, 'no_test_here.dart')).createSync();

        context.vars['package-root'] = tempDirectory.absolute.path;

        await pre_gen.run(context);

        final tests = context.vars['tests'] as List<Map<String, String>>;
        final testsMap = <String, String>{};
        for (final test in tests) {
          final path = test['path']!;
          final identifier = test['identifier']!;
          testsMap[path] = identifier;
        }

        final paths = testsMap.keys;
        expect(paths, contains('test1_test.dart'));
        expect(paths, contains('test2_test.dart'));
        expect(paths, isNot(contains('no_test_here.dart')));

        expect(
          testsMap.values.toSet().length,
          equals(tests.length),
          reason: 'All tests files should have unique identifiers',
        );

        expect(context.vars['isFlutter'], false);
      });

      test('with proper isFlutter identification', () async {
        File(path.join(tempDirectory.path, 'pubspec.yaml'))
          ..createSync()
          ..writeAsStringSync('''
dependencies:
  flutter:
    sdk: flutter''');

        Directory(path.join(tempDirectory.path, 'test')).createSync();

        context.vars['package-root'] = tempDirectory.absolute.path;

        await pre_gen.run(context);

        expect(context.vars['isFlutter'], true);
      });

      test('with proper not optimized tests identification', () async {
        File(path.join(tempDirectory.path, 'pubspec.yaml')).createSync();

        final testDir = Directory(path.join(tempDirectory.path, 'test'))
          ..createSync();
        File(path.join(testDir.path, 'test1_test.dart')).createSync();
        File(path.join(testDir.path, 'test2_test.dart')).createSync();
        File(path.join(testDir.path, 'no_test_here.dart')).createSync();
        File(
          path.join(testDir.path, 'not_optimized_test.dart'),
        ).writeAsStringSync(notOptimizedTestContent);
        File(
          path.join(testDir.path, 'another_not_optimized_test.dart'),
        ).writeAsStringSync(anotherNotOptimizedTestContent);

        context.vars['package-root'] = tempDirectory.absolute.path;

        await pre_gen.run(context);

        final tests = context.vars['tests'] as List<Map<String, String>>;
        final testsMap = <String, String>{};
        for (final test in tests) {
          final path = test['path']!;
          final identifier = test['identifier']!;
          testsMap[path] = identifier;
        }

        final paths = testsMap.keys;
        expect(paths, contains('test1_test.dart'));
        expect(paths, contains('test2_test.dart'));
        expect(paths, isNot(contains('no_test_here.dart')));
        expect(paths, isNot(contains('not_optimized_test.dart')));
        expect(paths, isNot(contains('another_not_optimized_test.dart')));

        expect(
          testsMap.values.toSet().length,
          equals(tests.length),
          reason: 'All tests files should have unique identifiers',
        );
        final notOptimizedTests =
            context.vars['notOptimizedTests'] as List<String>;
        expect(
          notOptimizedTests,
          contains('not_optimized_test.dart'),
        );
        expect(
          notOptimizedTests,
          contains('another_not_optimized_test.dart'),
        );
      });
    });

    group('Fails', () {
      setUp(() {
        pre_gen.exitFn = (code) {
          throw ProcessException('exit', [code.toString()]);
        };
      });

      tearDown(() {
        pre_gen.exitFn = exit;
      });

      test('when target test dir does not exist', () async {
        File(path.join(tempDirectory.path, 'pubspec.yaml')).createSync();

        final testDir = Directory(path.join(tempDirectory.path, 'test'));

        context.vars['package-root'] = tempDirectory.absolute.path;

        await expectLater(
          () => pre_gen.run(context),
          throwsA(
            isA<ProcessException>().having(
              (ex) => ex.arguments.first,
              'error code',
              equals('1'),
            ),
          ),
        );

        verify(
          () => context.logger.err('Could not find directory ${testDir.path}'),
        ).called(1);

        expect(context.vars['tests'], isNull);
        expect(context.vars['isFlutter'], isNull);
      });

      test('when target dir does not contain a pubspec.yaml', () async {
        final testDir = Directory(path.join(tempDirectory.path, 'test'))
          ..createSync();
        File(path.join(testDir.path, 'test1_test.dart')).createSync();
        File(path.join(testDir.path, 'test2_test.dart')).createSync();
        File(path.join(testDir.path, 'no_test_here.dart')).createSync();

        context.vars['package-root'] = tempDirectory.absolute.path;

        await expectLater(
          () => pre_gen.run(context),
          throwsA(
            isA<ProcessException>().having(
              (ex) => ex.arguments.first,
              'error code',
              equals('1'),
            ),
          ),
        );

        verify(
          () => context.logger.err(
            'Could not find pubspec.yaml at ${testDir.path}',
          ),
        ).called(1);

        expect(context.vars['tests'], isNull);
        expect(context.vars['isFlutter'], isNull);
      });
    });

    group('skipVeryGoodOptimizationRegExp regex', () {
      final regex = pre_gen.skipVeryGoodOptimizationRegExp;
      test('matches single-line tag', () {
        final content = "@Tags(['${pre_gen.skipVeryGoodOptimizationTag}'])";
        expect(regex.hasMatch(content), isTrue);
      });

      test('matches single-line with multiple tags', () {
        final content =
            "@Tags(['${pre_gen.skipVeryGoodOptimizationTag}', 'chrome'])";
        expect(regex.hasMatch(content), isTrue);
      });

      test('matches multi-line tag list', () {
        final content =
            '''
      @Tags([
        '${pre_gen.skipVeryGoodOptimizationTag}',
        'chrome',
        'test',
      ])
      ''';
        expect(regex.hasMatch(content), isTrue);
      });

      test('matches multi-line where tag is not the first', () {
        final content =
            '''
      @Tags([
        'chrome',
        '${pre_gen.skipVeryGoodOptimizationTag}',
        'test',
      ])
      ''';
        expect(regex.hasMatch(content), isTrue);
      });

      test('does not match when tag missing', () {
        const content = "@Tags(['chrome', 'test'])";
        expect(regex.hasMatch(content), isFalse);
      });

      test(
        'does not match substring only (e.g. skip_very_good_optimization,test)',
        () {
          final content =
              '''
      @Tags([
        '${pre_gen.skipVeryGoodOptimizationTag},test',
        'chrome',
      ])
      ''';
          expect(
            regex.hasMatch(content),
            isFalse,
          ); // only exact tag should match
        },
      );
    });
    group('Sharding', () {
      /// Creates a package with [count] optimizable test files, plus any
      /// [notOptimized] files carrying the skip optimization tag.
      Directory createPackage(int count, {int notOptimized = 0}) {
        File(path.join(tempDirectory.path, 'pubspec.yaml')).createSync();
        final testDir = Directory(path.join(tempDirectory.path, 'test'))
          ..createSync();
        for (var i = 0; i < count; i++) {
          File(path.join(testDir.path, 'test${i}_test.dart')).createSync();
        }
        for (var i = 0; i < notOptimized; i++) {
          File(
            path.join(testDir.path, 'skip${i}_test.dart'),
          ).writeAsStringSync(notOptimizedTestContent);
        }
        return testDir;
      }

      List<String> pathsOf(HookContext context) {
        final tests = context.vars['tests'] as List<Map<String, String>>;
        return tests.map((e) => e['path']!).toList();
      }

      Future<List<String>> runShard(int index, int total) async {
        final context = _FakeContext()
          ..vars['package-root'] = tempDirectory.absolute.path
          ..vars['shard-index'] = index
          ..vars['total-shards'] = total;
        await pre_gen.run(context);
        return [
          ...pathsOf(context),
          ...(context.vars['notOptimizedTests']! as List).cast<String>(),
        ];
      }

      test('runs every test exactly once across all shards', () async {
        createPackage(7, notOptimized: 2);

        final shards = [
          for (var i = 1; i <= 3; i++) await runShard(i, 3),
        ];
        final union = shards.expand((shard) => shard).toList();

        expect(
          union..sort(),
          [
            for (var i = 0; i < 7; i++) 'test${i}_test.dart',
            for (var i = 0; i < 2; i++) 'skip${i}_test.dart',
          ]..sort(),
          reason: 'Shards must be a complete and disjoint partition',
        );
      });

      test('shards non optimized tests as well', () async {
        createPackage(0, notOptimized: 4);

        final first = await runShard(1, 2);
        final second = await runShard(2, 2);

        expect(first, ['skip0_test.dart', 'skip2_test.dart']);
        expect(second, ['skip1_test.dart', 'skip3_test.dart']);
      });

      test('deals optimized and non optimized tests out together', () async {
        createPackage(2, notOptimized: 3);

        final sizes = [
          for (var i = 1; i <= 6; i++) (await runShard(i, 6)).length,
        ];

        expect(
          sizes,
          [1, 1, 1, 1, 1, 0],
          reason:
              'Sharding the two lists separately would give the first '
              'shards a file from each while later shards stay empty',
        );
      });

      test('is deterministic across runs', () async {
        createPackage(9);

        expect(await runShard(2, 4), await runShard(2, 4));
      });

      test('balances shards within one file of each other', () async {
        createPackage(10);

        final sizes = [
          for (var i = 1; i <= 4; i++) (await runShard(i, 4)).length,
        ];

        expect(sizes.reduce(max) - sizes.reduce(min), lessThanOrEqualTo(1));
      });

      test(
        'yields an empty shard when there are more shards than tests',
        () async {
          createPackage(2);

          expect(await runShard(3, 3), isEmpty);
        },
      );

      test(
        'excludes nested non optimized tests from the optimized set',
        () async {
          File(path.join(tempDirectory.path, 'pubspec.yaml')).createSync();
          final testDir = Directory(path.join(tempDirectory.path, 'test'))
            ..createSync();
          final nested = Directory(path.join(testDir.path, 'sub'))
            ..createSync();
          File(
            path.join(nested.path, 'skip_test.dart'),
          ).writeAsStringSync(notOptimizedTestContent);

          final context = _FakeContext()
            ..vars['package-root'] = tempDirectory.absolute.path;
          await pre_gen.run(context);

          expect(
            pathsOf(context),
            isEmpty,
            reason:
                'A tagged test in a subdirectory must not be optimized, '
                'otherwise it runs both inlined and standalone',
          );
          expect(
            context.vars['notOptimizedTests'],
            ['sub/skip_test.dart'],
          );
        },
      );

      test('includes every test when sharding is not requested', () async {
        createPackage(3);

        final context = _FakeContext()
          ..vars['package-root'] = tempDirectory.absolute.path;
        await pre_gen.run(context);

        expect(pathsOf(context), hasLength(3));
      });
    });

    group('shardOf', () {
      const paths = ['a.dart', 'b.dart', 'c.dart', 'd.dart', 'e.dart'];

      test('returns paths untouched when shard index is null', () {
        expect(
          pre_gen.shardOf(paths, shardIndex: null, totalShards: 3),
          paths,
        );
      });

      test('returns paths untouched when total shards is null', () {
        expect(
          pre_gen.shardOf(paths, shardIndex: 1, totalShards: null),
          paths,
        );
      });

      test('deals paths out round robin', () {
        expect(
          pre_gen.shardOf(paths, shardIndex: 1, totalShards: 2),
          ['a.dart', 'c.dart', 'e.dart'],
        );
        expect(
          pre_gen.shardOf(paths, shardIndex: 2, totalShards: 2),
          ['b.dart', 'd.dart'],
        );
      });

      test('returns everything for a single shard', () {
        expect(pre_gen.shardOf(paths, shardIndex: 1, totalShards: 1), paths);
      });

      test('returns empty for an out of range shard', () {
        expect(
          pre_gen.shardOf(paths, shardIndex: 9, totalShards: 9),
          isEmpty,
        );
      });
    });
  });
}
