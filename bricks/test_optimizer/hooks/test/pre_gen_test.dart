import 'dart:io';

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
}
