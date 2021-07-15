import 'package:args/args.dart';
import 'package:io/io.dart';
import 'package:mason/mason.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:usage/usage_io.dart';
import 'package:very_good_cli/src/command_runner.dart';
import 'package:very_good_cli/src/commands/create.dart';

class MockArgResults extends Mock implements ArgResults {}

class MockAnalytics extends Mock implements Analytics {}

class MockLogger extends Mock implements Logger {}

class MockMasonGenerator extends Mock implements MasonGenerator {}

class FakeDirectoryGeneratorTarget extends Fake
    implements DirectoryGeneratorTarget {}

void main() {
  group('Create', () {
    late List<String> progressLogs;
    late Analytics analytics;
    late Logger logger;
    late VeryGoodCommandRunner commandRunner;

    setUpAll(() {
      registerFallbackValue(FakeDirectoryGeneratorTarget());
    });

    setUp(() {
      progressLogs = <String>[];
      analytics = MockAnalytics();
      when(() => analytics.firstRun).thenReturn(false);
      when(() => analytics.enabled).thenReturn(false);
      when(
        () => analytics.sendEvent(any(), any(), label: any(named: 'label')),
      ).thenAnswer((_) => Future.value());
      when(
        () => analytics.waitForLastPing(timeout: any(named: 'timeout')),
      ).thenAnswer((_) => Future.value());

      logger = MockLogger();
      when(() => logger.progress(any())).thenReturn(
        ([_]) {
          if (_ != null) progressLogs.add(_);
        },
      );
      commandRunner = VeryGoodCommandRunner(
        analytics: analytics,
        logger: logger,
      );
    });

    test('can be instantiated without explicit logger', () {
      final command = CreateCommand(analytics: analytics);
      expect(command, isNotNull);
    });

    test(
        'throws UsageException when --project-name is missing '
        'and directory base is not a valid package name', () async {
      const expectedErrorMessage = '".tmp" is not a valid package name.\n\n'
          'See https://dart.dev/tools/pub/pubspec#name for more information.';
      final result = await commandRunner.run(['create', '.tmp']);
      expect(result, equals(ExitCode.usage.code));
      verify(() => logger.err(expectedErrorMessage)).called(1);
    });

    test('throws UsageException when --project-name is invalid', () async {
      const expectedErrorMessage = '"My App" is not a valid package name.\n\n'
          'See https://dart.dev/tools/pub/pubspec#name for more information.';
      final result = await commandRunner.run(
        ['create', '.', '--project-name', 'My App'],
      );
      expect(result, equals(ExitCode.usage.code));
      verify(() => logger.err(expectedErrorMessage)).called(1);
    });

    test('throws UsageException when output directory is missing', () async {
      const expectedErrorMessage =
          'No option specified for the output directory.';
      final result = await commandRunner.run(['create']);
      expect(result, equals(ExitCode.usage.code));
      verify(() => logger.err(expectedErrorMessage)).called(1);
    });

    test('throws UsageException when multiple output directories are provided',
        () async {
      const expectedErrorMessage = 'Multiple output directories specified.';
      final result = await commandRunner.run(['create', './a', './b']);
      expect(result, equals(ExitCode.usage.code));
      verify(() => logger.err(expectedErrorMessage)).called(1);
    });

    test('completes successfully with correct output', () async {
      final argResults = MockArgResults();
      final generator = MockMasonGenerator();
      final command = CreateCommand(
        analytics: analytics,
        logger: logger,
        generator: (_) async => generator,
      )..argResultOverrides = argResults;
      when(() => argResults['project-name']).thenReturn('my_app');
      when(() => argResults.rest).thenReturn(['.tmp']);
      when(() => generator.id).thenReturn('generator_id');
      when(() => generator.description).thenReturn('generator description');
      when(
        () => generator.generate(any(), vars: any(named: 'vars')),
      ).thenAnswer((_) async => 62);
      final result = await command.run();
      expect(result, equals(ExitCode.success.code));
      verify(() => logger.progress('Bootstrapping')).called(1);
      expect(progressLogs, equals(['Generated 62 file(s)']));
      verify(
        () => logger.progress('Running "flutter packages get" in .tmp'),
      ).called(1);
      verify(() => logger.alert('Created a Very Good App! 🦄')).called(1);
      verify(
        () => generator.generate(
          any(
            that: isA<DirectoryGeneratorTarget>().having(
              (g) => g.dir.path,
              'dir',
              '.tmp',
            ),
          ),
          vars: {
            'project_name': 'my_app',
            'org_name': ['com', 'example', 'verygoodcore'],
          },
        ),
      ).called(1);
      verify(
        () => analytics.sendEvent(
          'create',
          'generator_id',
          label: 'generator description',
        ),
      ).called(1);
      verify(
        () => analytics.waitForLastPing(timeout: VeryGoodCommandRunner.timeout),
      ).called(1);
    });

    group('org-name', () {
      group('invalid --org-name', () {
        void expectInvalidOrgName(String orgName) async {
          final expectedErrorMessage = '"$orgName" is not a valid org name.\n\n'
              'A valid org name has at least 2 parts separated by "."\n'
              'Each part must start with a letter and only include alphanumeric characters (A-Z, a-z, 0-9), underscores (_), and hyphens (-)\n'
              '(ex. very.good.org)';
          final result = await commandRunner.run(
            ['create', '.', '--org-name', orgName],
          );
          expect(result, equals(ExitCode.usage.code));
          verify(() => logger.err(expectedErrorMessage)).called(1);
        }

        test('no delimiters', () async {
          expectInvalidOrgName('My App');
        });

        test('less than 2 domains', () async {
          expectInvalidOrgName('verybadtest');
        });

        test('invalid characters present', () async {
          expectInvalidOrgName('very%.bad@.#test');
        });

        test('segment starts with a non-letter', () async {
          expectInvalidOrgName('very.bad.1test');
        });

        test('valid prefix but invalid suffix', () async {
          expectInvalidOrgName('very.good.prefix.bad@@suffix');
        });
      });

      group('valid --org-name', () {
        void expectValidOrgName(String orgName) async {
          final argResults = MockArgResults();
          final generator = MockMasonGenerator();
          final command = CreateCommand(
            analytics: analytics,
            logger: logger,
            generator: (_) async => generator,
          )..argResultOverrides = argResults;
          when(() => argResults['project-name']).thenReturn('my_app');
          when(() => argResults['org-name']).thenReturn(orgName);
          when(() => argResults.rest).thenReturn(['.tmp']);
          when(() => generator.id).thenReturn('generator_id');
          when(() => generator.description).thenReturn('generator description');
          when(
            () => generator.generate(any(), vars: any(named: 'vars')),
          ).thenAnswer((_) async => 62);
          final result = await command.run();
          expect(result, equals(ExitCode.success.code));
          verify(() => logger.progress('Bootstrapping')).called(1);
          expect(progressLogs, equals(['Generated 62 file(s)']));
          verify(
            () => logger.progress('Running "flutter packages get" in .tmp'),
          ).called(1);
          verify(() => logger.alert('Created a Very Good App! 🦄')).called(1);
          verify(
            () => generator.generate(
              any(
                that: isA<DirectoryGeneratorTarget>().having(
                  (g) => g.dir.path,
                  'dir',
                  '.tmp',
                ),
              ),
              vars: {
                'project_name': 'my_app',
                'org_name': orgName.split('.'),
              },
            ),
          ).called(1);
          verify(
            () => analytics.sendEvent(
              'create',
              'generator_id',
              label: 'generator description',
            ),
          ).called(1);
          verify(
            () => analytics.waitForLastPing(
                timeout: VeryGoodCommandRunner.timeout),
          ).called(1);
        }

        test('alphanumeric with three parts', () async {
          expectValidOrgName('very.good.ventures');
        });

        test('containing an underscore', () async {
          expectValidOrgName('very.good.test_case');
        });

        test('containing a hyphen', () async {
          expectValidOrgName('very.bad.test-case');
        });

        test('single character parts', () async {
          expectValidOrgName('v.g.v');
        });

        test('more than three parts', () async {
          expectValidOrgName('very.good.ventures.app.identifier');
        });

        test('less than three parts', () async {
          expectValidOrgName('verygood.ventures');
        });
      });
    });
  });
}
