import 'dart:io';

import 'package:hooks/pre_gen.dart' as pre_gen;
import 'package:mason/mason.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

class MockProgress extends Mock implements Progress {}

class MockLogger extends Mock implements Logger {}

class FakeContext extends Fake implements HookContext {
  @override
  final logger = MockLogger();

  @override
  Map<String, Object?> vars = {};
}

void main() {
  late HookContext context;

  setUp(() {
    context = FakeContext();
  });

  group('Pre gen hook', () {
    group('Completes', () {
      test('with test files list', () async {
        final packageRoot =
            Directory.systemTemp.createTempSync('test_optimizer');
        File(path.join(packageRoot.path, 'pubspec.yaml')).createSync();

        final testDir = Directory(path.join(packageRoot.path, 'test'))
          ..createSync();
        File(path.join(testDir.path, 'test1_test.dart')).createSync();
        File(path.join(testDir.path, 'test2_test.dart')).createSync();
        File(path.join(testDir.path, 'no_test_here.dart')).createSync();

        context.vars['package-root'] = packageRoot.absolute.path;

        await pre_gen.run(context);

        final tests = context.vars['tests'] as List<String>;

        expect(
          tests,
          containsAll([
            'test2_test.dart',
            'test1_test.dart',
          ]),
        );
        expect(test, isNot(contains('no_test_here.dart')));
        expect(context.vars['isFlutter'], false);
      });

      test('with proper isFlutter identification', () async {
        final packageRoot =
            Directory.systemTemp.createTempSync('test_optimizer');

        File(path.join(packageRoot.path, 'pubspec.yaml'))
          ..createSync()
          ..writeAsStringSync('''
dependencies:
  flutter:
    sdk: flutter''');

        Directory(path.join(packageRoot.path, 'test')).createSync();

        context.vars['package-root'] = packageRoot.absolute.path;

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
        final packageRoot =
            Directory.systemTemp.createTempSync('test_optimizer');
        File(path.join(packageRoot.path, 'pubspec.yaml')).createSync();

        final testDir = Directory(path.join(packageRoot.path, 'test'));

        context.vars['package-root'] = packageRoot.absolute.path;

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
        final packageRoot =
            Directory.systemTemp.createTempSync('test_optimizer');

        final testDir = Directory(path.join(packageRoot.path, 'test'))
          ..createSync();
        File(path.join(testDir.path, 'test1_test.dart')).createSync();
        File(path.join(testDir.path, 'test2_test.dart')).createSync();
        File(path.join(testDir.path, 'no_test_here.dart')).createSync();

        context.vars['package-root'] = packageRoot.absolute.path;

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
