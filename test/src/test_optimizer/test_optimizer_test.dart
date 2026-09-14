import 'dart:io';

import 'package:mason/mason.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:very_good_cli/src/test_optimizer/test_optimizer.dart';

class _MockMasonGenerator extends Mock implements MasonGenerator;

class _MockGeneratorHooks extends Mock implements GeneratorHooks;

class _MockProgress extends Mock implements Progress;

class _MockLogger extends Mock implements Logger;

class _FakeGeneratorTarget extends Fake implements GeneratorTarget;

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeGeneratorTarget());
    registerFallbackValue(FileConflictResolution.prompt);
  });

  group(TestOptimizer, () {
    late Logger logger;
    late Progress progress;
    late GeneratorHooks hooks;
    late MasonGenerator generator;
    late Directory tempDirectory;

    /// The vars the brick's pre-gen hook reports back for a package.
    late Map<String, dynamic> preGenVars;

    tearDown(() => tempDirectory.deleteSync(recursive: true));

    setUp(() {
      tempDirectory = Directory.systemTemp.createTempSync();
      Directory(p.join(tempDirectory.path, 'test')).createSync();
      logger = _MockLogger();
      progress = _MockProgress();
      hooks = _MockGeneratorHooks();
      generator = _MockMasonGenerator();
      preGenVars = <String, dynamic>{
        'tests': <dynamic>[
          {'path': 'app/view/app_test.dart', 'identifier': '_a'},
        ],
        'notOptimizedTests': <dynamic>[],
      };

      when(() => logger.progress(any())).thenReturn(progress);
      when(() => generator.hooks).thenReturn(hooks);
      when(
        () => hooks.preGen(
          vars: any(named: 'vars'),
          onVarsChanged: any(named: 'onVarsChanged'),
          workingDirectory: any(named: 'workingDirectory'),
        ),
      ).thenAnswer((invocation) async {
        (invocation.namedArguments[#onVarsChanged]
                as void Function(Map<String, dynamic> vars))
            .call(preGenVars);
      });
      when(
        () => generator.generate(
          any(),
          vars: any(named: 'vars'),
          fileConflictResolution: any(named: 'fileConflictResolution'),
        ),
      ).thenAnswer((_) async => []);
    });

    TestOptimizer buildOptimizer({List<String>? exclude}) {
      return TestOptimizer(
        enabled: true,
        exclude: exclude,
        buildGenerator: (_) async => generator,
      );
    }

    group('exclusion globs', () {
      test('names the offending glob when it cannot be parsed', () {
        expect(
          () => TestOptimizer(enabled: true, exclude: const ['test/{']),
          throwsA(
            isA<InvalidOptimizationGlob>().having(
              (e) => e.message,
              'message',
              contains('Invalid exclude-optimization glob `test/{`'),
            ),
          ),
        );
      });

      test('rejects a blank glob', () {
        expect(
          () => TestOptimizer(enabled: true, exclude: const ['  ']),
          throwsA(
            isA<InvalidOptimizationGlob>().having(
              (e) => e.message,
              'message',
              'Expected every exclude-optimization glob to be non-empty.',
            ),
          ),
        );
      });

      test('are compiled before any work happens', () {
        expect(
          () => TestOptimizer(enabled: false, exclude: const ['']),
          throwsA(isA<InvalidOptimizationGlob>()),
        );
      });
    });

    group('.apply', () {
      test('generates nothing and is silent when disabled', () async {
        final optimization = await const TestOptimizer.disabled().apply(
          packageRoot: tempDirectory.path,
          logger: logger,
        );

        expect(optimization, same(TestOptimization.none));
        verifyZeroInteractions(logger);
        verifyZeroInteractions(generator);
      });

      test('reports progress and overwrites the bundle', () async {
        await buildOptimizer().apply(
          packageRoot: tempDirectory.path,
          logger: logger,
        );

        verify(() => logger.progress('Optimizing tests')).called(1);
        verify(() => progress.complete()).called(1);
        verify(
          () => hooks.preGen(
            vars: <String, dynamic>{'package-root': tempDirectory.path},
            onVarsChanged: any(named: 'onVarsChanged'),
            workingDirectory: tempDirectory.path,
          ),
        ).called(1);
        verify(
          () => generator.generate(
            any(),
            vars: preGenVars,
            fileConflictResolution: FileConflictResolution.overwrite,
          ),
        ).called(1);
      });

      test('completes the progress when generation throws', () async {
        when(
          () => generator.generate(
            any(),
            vars: any(named: 'vars'),
            fileConflictResolution: any(named: 'fileConflictResolution'),
          ),
        ).thenThrow(Exception('oops'));

        await expectLater(
          buildOptimizer().apply(
            packageRoot: tempDirectory.path,
            logger: logger,
          ),
          throwsException,
        );
        verify(() => progress.complete()).called(1);
      });

      test('carries the tests the hook kept out of the bundle', () async {
        preGenVars['notOptimizedTests'] = <dynamic>['tagged_test.dart'];

        final optimization = await buildOptimizer().apply(
          packageRoot: tempDirectory.path,
          logger: logger,
        );

        expect(optimization.packageRoot, equals(tempDirectory.path));
        expect(optimization.serialTests, equals(['tagged_test.dart']));
      });

      test('moves tests matching a glob out of the bundle', () async {
        preGenVars['tests'] = <dynamic>[
          {'path': 'app/view/app_test.dart', 'identifier': '_a'},
          {'path': 'integration/login_test.dart', 'identifier': '_b'},
        ];

        final optimization = await buildOptimizer(
          exclude: const ['test/integration'],
        ).apply(packageRoot: tempDirectory.path, logger: logger);

        expect(
          optimization.serialTests,
          equals(['integration/login_test.dart']),
        );
        verify(
          () => generator.generate(
            any(),
            vars: <String, dynamic>{
              'tests': [
                {'path': 'app/view/app_test.dart', 'identifier': '_a'},
              ],
              'notOptimizedTests': ['integration/login_test.dart'],
            },
            fileConflictResolution: FileConflictResolution.overwrite,
          ),
        ).called(1);
      });

      test('keeps tests the globs do not match in the bundle', () async {
        final optimization = await buildOptimizer(
          exclude: const ['test/integration'],
        ).apply(packageRoot: tempDirectory.path, logger: logger);

        expect(optimization.serialTests, isEmpty);
        expect(
          optimization.testTargets,
          equals([p.join('test', testOptimizerFileName)]),
        );
      });

      test('`**` matches nested tests only', () async {
        preGenVars['tests'] = <dynamic>[
          {'path': 'root_test.dart', 'identifier': '_a'},
          {'path': 'nested/deep_test.dart', 'identifier': '_b'},
        ];

        final optimization = await buildOptimizer(exclude: const ['test/*/**'])
            .apply(packageRoot: tempDirectory.path, logger: logger);

        expect(optimization.serialTests, equals(['nested/deep_test.dart']));
      });

      test('leaves the hook vars alone when there are no globs', () async {
        await buildOptimizer().apply(
          packageRoot: tempDirectory.path,
          logger: logger,
        );

        verify(
          () => generator.generate(
            any(),
            vars: preGenVars,
            fileConflictResolution: FileConflictResolution.overwrite,
          ),
        ).called(1);
      });

      test('leaves the hook vars alone when it reported no tests', () async {
        preGenVars.remove('tests');

        await buildOptimizer(exclude: const ['test/integration'])
            .apply(packageRoot: tempDirectory.path, logger: logger);

        verify(
          () => generator.generate(
            any(),
            vars: preGenVars,
            fileConflictResolution: FileConflictResolution.overwrite,
          ),
        ).called(1);
      });
    });

    group('.testTargets', () {
      Future<TestOptimization> optimize({List<String>? exclude}) {
        return buildOptimizer(exclude: exclude)
            .apply(packageRoot: tempDirectory.path, logger: logger);
      }

      test('is empty when nothing was optimized', () {
        expect(TestOptimization.none.testTargets, isEmpty);
      });

      test('runs the bundle alone', () async {
        expect(
          (await optimize()).testTargets,
          equals([p.join('test', testOptimizerFileName)]),
        );
      });

      test('runs the bundle before the tests kept out of it', () async {
        preGenVars['notOptimizedTests'] = <dynamic>['tagged_test.dart'];

        expect(
          (await optimize()).testTargets,
          equals([
            p.join('test', testOptimizerFileName),
            p.join('test', 'tagged_test.dart'),
          ]),
        );
      });

      test('skips the bundle once every test has been excluded', () async {
        preGenVars['tests'] = <dynamic>[
          {'path': 'integration/login_test.dart', 'identifier': '_a'},
        ];

        expect(
          (await optimize(exclude: const ['test/integration'])).testTargets,
          equals([p.join('test', 'integration/login_test.dart')]),
        );
      });

      test('runs the bundle when the package has no tests at all', () async {
        preGenVars['tests'] = <dynamic>[];

        expect(
          (await optimize()).testTargets,
          equals([p.join('test', testOptimizerFileName)]),
        );
      });

      test('runs the bundle when the hook reported no tests key', () async {
        preGenVars.remove('tests');

        expect(
          (await optimize()).testTargets,
          equals([p.join('test', testOptimizerFileName)]),
        );
      });
    });

    group('.resolveReport', () {
      late TestOptimization optimization;

      setUp(() async {
        optimization = await buildOptimizer().apply(
          packageRoot: tempDirectory.path,
          logger: logger,
        );
      });

      test('restores the file a bundled test was written in', () {
        expect(
          optimization.resolveReport(
            suitePath: 'test/$testOptimizerFileName',
            testName: 'app/view/app_test.dart renders App',
            groupName: 'app/view/app_test.dart',
          ),
          equals((path: 'test/app/view/app_test.dart', name: 'renders App')),
        );
      });

      test('leaves a suite that is not the bundle alone', () {
        expect(
          optimization.resolveReport(
            suitePath: 'test/integration/login_test.dart',
            testName: 'logs in',
            groupName: 'logs in',
          ),
          equals((path: 'test/integration/login_test.dart', name: 'logs in')),
        );
      });

      test('reports the bundle as-is when it failed to compile', () {
        expect(
          optimization.resolveReport(
            suitePath: 'test/$testOptimizerFileName',
            testName: 'loading test/$testOptimizerFileName',
            groupName: null,
          ),
          equals((
            path: 'test/$testOptimizerFileName',
            name: 'loading test/$testOptimizerFileName',
          )),
        );
      });

      test('reports the bundle as-is for an empty group name', () {
        expect(
          optimization.resolveReport(
            suitePath: 'test/$testOptimizerFileName',
            testName: 'loading',
            groupName: '',
          ),
          equals((path: 'test/$testOptimizerFileName', name: 'loading')),
        );
      });

      test('leaves everything alone when nothing was optimized', () {
        expect(
          TestOptimization.none.resolveReport(
            suitePath: 'test/app_test.dart',
            testName: 'renders App',
            groupName: 'app_test.dart',
          ),
          equals((path: 'test/app_test.dart', name: 'renders App')),
        );
      });
    });

    group('.cleanUp', () {
      test('deletes the generated bundle', () async {
        final bundle = File(
          p.join(tempDirectory.path, 'test', testOptimizerFileName),
        )..createSync();

        final optimization = await buildOptimizer().apply(
          packageRoot: tempDirectory.path,
          logger: logger,
        );
        await optimization.cleanUp();

        expect(bundle.existsSync(), isFalse);
      });

      test('does nothing when nothing was optimized', () async {
        await expectLater(TestOptimization.none.cleanUp(), completes);
      });

      test('is safe to call when the bundle is already gone', () async {
        final optimization = await buildOptimizer().apply(
          packageRoot: tempDirectory.path,
          logger: logger,
        );

        await optimization.cleanUp();
        await expectLater(optimization.cleanUp(), completes);
      });
    });
  });
}
