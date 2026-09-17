import 'dart:io';

import 'package:hooks/pre_gen.dart' as pre_gen;
import 'package:hooks/test_metadata.dart';
import 'package:mason/mason.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

class _MockLogger extends Mock implements Logger;

class _FakeContext extends Fake implements HookContext {
  @override
  final logger = _MockLogger();

  @override
  Map<String, Object?> vars = {};
}

const notOptimizedTestContent =
    '''
@Tags(['${pre_gen.skipVeryGoodOptimizationTag}'])
library;

void main() {
  test('test', () {
    expect(1, 1);
  });
}
''';

const anotherNotOptimizedTestContent =
    '''
@Tags(['${pre_gen.skipVeryGoodOptimizationTag}', 'another_tag'])
import 'package:test/test.dart';

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

        expect(
          tests.map((test) => test['groupArguments']),
          everyElement(isEmpty),
          reason: 'Files without annotations forward no group arguments',
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
        File(path.join(testDir.path, 'not_optimized_test.dart'))
            .writeAsStringSync(notOptimizedTestContent);
        File(path.join(testDir.path, 'another_not_optimized_test.dart'))
            .writeAsStringSync(anotherNotOptimizedTestContent);

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
        expect(notOptimizedTests, contains('not_optimized_test.dart'));
        expect(notOptimizedTests, contains('another_not_optimized_test.dart'));
      });

      test(
        'with file level annotations forwarded as group arguments',
        () async {
          File(path.join(tempDirectory.path, 'pubspec.yaml')).createSync();

          final testDir = Directory(path.join(tempDirectory.path, 'test'))
            ..createSync();
          File(path.join(testDir.path, 'annotated_test.dart'))
              .writeAsStringSync('''
@Tags(['slow'])
@Timeout(Duration(minutes: 5))
library;

void main() {}
''');

          context.vars['package-root'] = tempDirectory.absolute.path;

          await pre_gen.run(context);

          final tests = context.vars['tests'] as List<Map<String, String>>;
          expect(tests, hasLength(1));
          expect(
            tests.single['groupArguments'],
            equals(", timeout: Timeout(Duration(minutes: 5)), tags: ['slow']"),
          );
        },
      );

      test(
        'with a skip tag package:test would ignore left optimized',
        () async {
          File(path.join(tempDirectory.path, 'pubspec.yaml')).createSync();

          final testDir = Directory(path.join(tempDirectory.path, 'test'))
            ..createSync();
          File(path.join(testDir.path, 'no_directive_test.dart'))
              .writeAsStringSync('''
@Tags(['${pre_gen.skipVeryGoodOptimizationTag}'])
void main() {}
''');

          context.vars['package-root'] = tempDirectory.absolute.path;

          await pre_gen.run(context);

          final tests = context.vars['tests'] as List<Map<String, String>>;
          expect(
            tests.map((test) => test['path']),
            contains('no_directive_test.dart'),
          );
          expect(context.vars['notOptimizedTests'], isEmpty);

          verify(
            () => context.logger.warn(
              any(
                that: allOf(
                  contains('no_directive_test.dart'),
                  contains(pre_gen.skipVeryGoodOptimizationTag),
                ),
              ),
            ),
          ).called(1);
        },
      );

      test(
        'with an unresolvable annotation left out and warned about',
        () async {
          File(path.join(tempDirectory.path, 'pubspec.yaml')).createSync();

          final testDir = Directory(path.join(tempDirectory.path, 'test'))
            ..createSync();
          File(path.join(testDir.path, 'unresolvable_test.dart'))
              .writeAsStringSync('''
@Timeout(kSlowSuite)
@Retry(2)
library;

void main() {}
''');

          context.vars['package-root'] = tempDirectory.absolute.path;

          await pre_gen.run(context);

          final tests = context.vars['tests'] as List<Map<String, String>>;
          expect(
            tests.single['groupArguments'],
            equals(', retry: 2'),
            reason: 'The resolvable sibling is still forwarded',
          );

          verify(
            () => context.logger.warn(
              any(
                that: allOf(
                  contains('unresolvable_test.dart'),
                  contains('@Timeout(kSlowSuite)'),
                ),
              ),
            ),
          ).called(1);
        },
      );
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
  });

  group('TestMetadataBundle', () {
    group('groupArguments', () {
      test('is empty without annotations', () {
        final metadata = parseTestMetadata('void main() {}');

        expect(metadata.groupArguments, isEmpty);
      });

      test('emits a single annotation', () {
        final metadata = parseTestMetadata("@Skip('not ready')\nlibrary;");

        expect(metadata.groupArguments, equals(", skip: 'not ready'"));
      });

      test('emits a fixed order regardless of source order', () {
        final metadata = parseTestMetadata('''
@Retry(3)
@Tags(['slow'])
@Skip()
@Timeout.none
@TestOn('vm')
library;
''');

        expect(
          metadata.groupArguments,
          equals(
            ", testOn: 'vm', timeout: Timeout.none, skip: true, "
            "tags: ['slow'], retry: 3",
          ),
        );
      });
    });

    group('skipsOptimization', () {
      test('is true for the skip tag on its own', () {
        final metadata = parseTestMetadata(
          "@Tags(['${pre_gen.skipVeryGoodOptimizationTag}'])\nlibrary;",
        );

        expect(metadata.skipsOptimization, isTrue);
      });

      test('is true when the skip tag is not first', () {
        final metadata = parseTestMetadata(
          "@Tags(['other', '${pre_gen.skipVeryGoodOptimizationTag}'])\n"
          'library;',
        );

        expect(metadata.skipsOptimization, isTrue);
      });

      test('is false without the tag', () {
        final metadata = parseTestMetadata("@Tags(['other'])\nlibrary;");

        expect(metadata.skipsOptimization, isFalse);
      });

      test('is false when the tag is only a substring', () {
        final metadata = parseTestMetadata(
          "@Tags(['${pre_gen.skipVeryGoodOptimizationTag},test'])\nlibrary;",
        );

        expect(metadata.skipsOptimization, isFalse);
      });

      test('is false when the annotation is not on the first directive', () {
        final metadata = parseTestMetadata('''
@Tags(['${pre_gen.skipVeryGoodOptimizationTag}'])
void main() {}
''');

        expect(metadata.skipsOptimization, isFalse);
      });
    });
  });
}
