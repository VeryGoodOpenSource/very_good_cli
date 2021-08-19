import 'dart:async';
import 'package:args/args.dart';
import 'package:io/io.dart';
import 'package:mason/mason.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:usage/usage_io.dart';
import 'package:very_good_cli/src/command_runner.dart';
import 'package:very_good_cli/src/commands/create.dart';
import 'package:very_good_cli/src/templates/flutter_plugin_bundle.dart';
import 'package:very_good_cli/src/templates/templates.dart';

const expectedUsage = [
  // ignore: no_adjacent_strings_in_list
  'Creates a new very good project in the specified directory.\n'
      '\n'
      'Usage: very_good create <output directory>\n'
      '-h, --help                    Print this usage information.\n'
      '''    --project-name            The project name for this new project. This must be a valid dart package name.\n'''
      '    --desc                    The description for this new project.\n'
      '''                              (defaults to "A Very Good Project created by Very Good CLI.")\n'''
      '    --org-name                The organization for this new project.\n'
      '                              (defaults to "com.example.verygoodcore")\n'
      '''-t, --template                The template used to generate this new project.\n'''
      '\n'
      '''          [core] (default)    Generate a Very Good Flutter application.\n'''
      '          [dart_pkg]          Generate a reusable Dart package.\n'
      '          [flutter_pkg]       Generate a reusable Flutter package.\n'
      '          [flutter_plugin]    Generate a reusable Flutter plugin.\n'
      '\n'
      'Run "very_good help" to see global options.'
];

class MockArgResults extends Mock implements ArgResults {}

class MockAnalytics extends Mock implements Analytics {}

class MockLogger extends Mock implements Logger {}

class MockMasonGenerator extends Mock implements MasonGenerator {}

class FakeDirectoryGeneratorTarget extends Fake
    implements DirectoryGeneratorTarget {}

void main() {
  group('Create', () {
    late List<String> progressLogs;
    late List<String> printLogs;
    late Analytics analytics;
    late Logger logger;
    late VeryGoodCommandRunner commandRunner;

    void Function() overridePrint(void Function() fn) {
      return () {
        final spec = ZoneSpecification(print: (_, __, ___, String msg) {
          printLogs.add(msg);
        });
        return Zone.current.fork(specification: spec).run<void>(fn);
      };
    }

    setUpAll(() {
      registerFallbackValue(FakeDirectoryGeneratorTarget());
    });

    setUp(() {
      printLogs = [];
      progressLogs = <String>[];
      analytics = MockAnalytics();
      when(() => analytics.firstRun).thenReturn(false);
      when(() => analytics.enabled).thenReturn(false);
      when(
        () => analytics.sendEvent(any(), any(), label: any(named: 'label')),
      ).thenAnswer((_) async {});
      when(
        () => analytics.waitForLastPing(timeout: any(named: 'timeout')),
      ).thenAnswer((_) async {});

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

    test('help', overridePrint(() async {
      final result = await commandRunner.run(['create', '--help']);
      expect(printLogs, equals(expectedUsage));
      expect(result, equals(ExitCode.success.code));

      printLogs.clear();

      final resultAbbr = await commandRunner.run(['create', '-h']);
      expect(printLogs, equals(expectedUsage));
      expect(resultAbbr, equals(ExitCode.success.code));
    }));

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
      when(() => argResults['project-name'] as String?).thenReturn('my_app');
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
          vars: <String, dynamic>{
            'project_name': 'my_app',
            'org_name': [
              {'value': 'com', 'separator': '.'},
              {'value': 'example', 'separator': '.'},
              {'value': 'verygoodcore', 'separator': ''}
            ],
            'description': '',
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

    test('completes successfully w/ custom description', () async {
      final argResults = MockArgResults();
      final generator = MockMasonGenerator();
      final command = CreateCommand(
        analytics: analytics,
        logger: logger,
        generator: (_) async => generator,
      )..argResultOverrides = argResults;
      when(() => argResults['project-name'] as String?).thenReturn('my_app');
      when(
        () => argResults['desc'] as String?,
      ).thenReturn('very good description');
      when(() => argResults.rest).thenReturn(['.tmp']);
      when(() => generator.id).thenReturn('generator_id');
      when(() => generator.description).thenReturn('generator description');
      when(
        () => generator.generate(any(), vars: any(named: 'vars')),
      ).thenAnswer((_) async => 62);
      final result = await command.run();
      expect(result, equals(ExitCode.success.code));
      verify(
        () => generator.generate(
          any(
            that: isA<DirectoryGeneratorTarget>().having(
              (g) => g.dir.path,
              'dir',
              '.tmp',
            ),
          ),
          vars: <String, dynamic>{
            'project_name': 'my_app',
            'org_name': [
              {'value': 'com', 'separator': '.'},
              {'value': 'example', 'separator': '.'},
              {'value': 'verygoodcore', 'separator': ''}
            ],
            'description': 'very good description',
          },
        ),
      ).called(1);
    });

    group('org-name', () {
      group('invalid --org-name', () {
        Future<void> expectInvalidOrgName(String orgName) async {
          final expectedErrorMessage = '"$orgName" is not a valid org name.\n\n'
              'A valid org name has at least 2 parts separated by "."\n'
              'Each part must start with a letter and only include '
              'alphanumeric characters (A-Z, a-z, 0-9), underscores (_), '
              'and hyphens (-)\n'
              '(ex. very.good.org)';
          final result = await commandRunner.run(
            ['create', '.', '--org-name', orgName],
          );
          expect(result, equals(ExitCode.usage.code));
          verify(() => logger.err(expectedErrorMessage)).called(1);
        }

        test('no delimiters', () {
          expectInvalidOrgName('My App');
        });

        test('less than 2 domains', () {
          expectInvalidOrgName('verybadtest');
        });

        test('invalid characters present', () {
          expectInvalidOrgName('very%.bad@.#test');
        });

        test('segment starts with a non-letter', () {
          expectInvalidOrgName('very.bad.1test');
        });

        test('valid prefix but invalid suffix', () {
          expectInvalidOrgName('very.good.prefix.bad@@suffix');
        });
      });

      group('valid --org-name', () {
        Future<void> expectValidOrgName(
          String orgName,
          List<Map<String, String>> expected,
        ) async {
          final argResults = MockArgResults();
          final generator = MockMasonGenerator();
          final command = CreateCommand(
            analytics: analytics,
            logger: logger,
            generator: (_) async => generator,
          )..argResultOverrides = argResults;
          when(
            () => argResults['project-name'] as String?,
          ).thenReturn('my_app');
          when(() => argResults['org-name'] as String?).thenReturn(orgName);
          when(() => argResults.rest).thenReturn(['.tmp']);
          when(() => generator.id).thenReturn('generator_id');
          when(() => generator.description).thenReturn('generator description');
          when(
            () => generator.generate(any(), vars: any(named: 'vars')),
          ).thenAnswer((_) async => 62);
          final result = await command.run();
          expect(result, equals(ExitCode.success.code));
          verify(
            () => generator.generate(
              any(
                that: isA<DirectoryGeneratorTarget>().having(
                  (g) => g.dir.path,
                  'dir',
                  '.tmp',
                ),
              ),
              vars: <String, dynamic>{
                'project_name': 'my_app',
                'description': '',
                'org_name': expected
              },
            ),
          ).called(1);
        }

        test('alphanumeric with three parts', () async {
          await expectValidOrgName('very.good.ventures', [
            {'value': 'very', 'separator': '.'},
            {'value': 'good', 'separator': '.'},
            {'value': 'ventures', 'separator': ''},
          ]);
        });

        test('containing an underscore', () async {
          await expectValidOrgName('very.good.test_case', [
            {'value': 'very', 'separator': '.'},
            {'value': 'good', 'separator': '.'},
            {'value': 'test case', 'separator': ''},
          ]);
        });

        test('containing a hyphen', () async {
          await expectValidOrgName('very.bad.test-case', [
            {'value': 'very', 'separator': '.'},
            {'value': 'bad', 'separator': '.'},
            {'value': 'test case', 'separator': ''},
          ]);
        });

        test('single character parts', () async {
          await expectValidOrgName('v.g.v', [
            {'value': 'v', 'separator': '.'},
            {'value': 'g', 'separator': '.'},
            {'value': 'v', 'separator': ''},
          ]);
        });

        test('more than three parts', () async {
          await expectValidOrgName('very.good.ventures.app.identifier', [
            {'value': 'very', 'separator': '.'},
            {'value': 'good', 'separator': '.'},
            {'value': 'ventures', 'separator': '.'},
            {'value': 'app', 'separator': '.'},
            {'value': 'identifier', 'separator': ''},
          ]);
        });

        test('less than three parts', () async {
          await expectValidOrgName('verygood.ventures', [
            {'value': 'verygood', 'separator': '.'},
            {'value': 'ventures', 'separator': ''},
          ]);
        });
      });
    });

    group('--template', () {
      group('invalid template name', () {
        Future<void> expectInvalidTemplateName(String templateName) async {
          final expectedErrorMessage =
              '"$templateName" is not an allowed value for option "template".';
          final result = await commandRunner.run(
            ['create', '.', '--template', templateName],
          );
          expect(result, equals(ExitCode.usage.code));
          verify(() => logger.err(expectedErrorMessage)).called(1);
        }

        test('invalid template name', () {
          expectInvalidTemplateName('badtemplate');
        });
      });

      group('valid template names', () {
        Future<void> expectValidTemplateName({
          required String getPackagesMsg,
          required String templateName,
          required MasonBundle expectedBundle,
          required String expectedLogSummary,
        }) async {
          final argResults = MockArgResults();
          final generator = MockMasonGenerator();
          final command = CreateCommand(
            analytics: analytics,
            logger: logger,
            generator: (bundle) async {
              expect(bundle, equals(expectedBundle));
              return generator;
            },
          )..argResultOverrides = argResults;
          when(
            () => argResults['project-name'] as String?,
          ).thenReturn('my_app');
          when(
            () => argResults['template'] as String?,
          ).thenReturn(templateName);
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
            () => logger.progress(getPackagesMsg),
          ).called(1);
          verify(() => logger.alert(expectedLogSummary)).called(1);
          verify(
            () => generator.generate(
              any(
                that: isA<DirectoryGeneratorTarget>().having(
                  (g) => g.dir.path,
                  'dir',
                  '.tmp',
                ),
              ),
              vars: <String, dynamic>{
                'project_name': 'my_app',
                'org_name': [
                  {'value': 'com', 'separator': '.'},
                  {'value': 'example', 'separator': '.'},
                  {'value': 'verygoodcore', 'separator': ''}
                ],
                'description': '',
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

        test('core template', () async {
          await expectValidTemplateName(
            getPackagesMsg: 'Running "flutter packages get" in .tmp',
            templateName: 'core',
            expectedBundle: veryGoodCoreBundle,
            expectedLogSummary: 'Created a Very Good App! 🦄',
          );
        });

        test('dart pkg template', () async {
          await expectValidTemplateName(
            getPackagesMsg: 'Running "flutter pub get" in .tmp',
            templateName: 'dart_pkg',
            expectedBundle: dartPackageBundle,
            expectedLogSummary: 'Created a Very Good Dart package! 🦄',
          );
        });

        test('flutter pkg template', () async {
          await expectValidTemplateName(
            getPackagesMsg: 'Running "flutter packages get" in .tmp',
            templateName: 'flutter_pkg',
            expectedBundle: flutterPackageBundle,
            expectedLogSummary: 'Created a Very Good Flutter package! 🦄',
          );
        });

        test('flutter plugin template', () async {
          await expectValidTemplateName(
            getPackagesMsg: 'Running "flutter packages get" in .tmp',
            templateName: 'flutter_plugin',
            expectedBundle: flutterPluginBundle,
            expectedLogSummary: 'Created a Very Good Flutter plugin! 🦄',
          );
        });
      });
    });
  });
}
