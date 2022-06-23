import 'dart:async';

import 'package:args/args.dart';
import 'package:mason/mason.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;
import 'package:pub_updater/pub_updater.dart';
import 'package:test/test.dart';
import 'package:universal_io/io.dart';
import 'package:usage/usage_io.dart';
import 'package:very_good_cli/src/command_runner.dart';
import 'package:very_good_cli/src/commands/create/create.dart';
import 'package:very_good_cli/src/commands/create/templates/templates.dart';

import '../../../helpers/helpers.dart';

const expectedUsage = [
  // ignore: no_adjacent_strings_in_list
  'Creates a new very good project in the specified directory.\n'
      '\n'
      'Usage: very_good create <output directory>\n'
      '-h, --help                    Print this usage information.\n'
      '''    --project-name            The project name for this new project. This must be a valid dart package name.\n'''
      '    --desc                    The description for this new project.\n'
      '''                              (defaults to "A Very Good Project created by Very Good CLI.")\n'''
      '''    --executable-name         Used by the dart_cli template, the CLI executable name (defaults to the project name)\n'''
      '    --org-name                The organization for this new project.\n'
      '                              (defaults to "com.example.verygoodcore")\n'
      '''-t, --template                The template used to generate this new project.\n'''
      '\n'
      '''          [core] (default)    Generate a Very Good Flutter application.\n'''
      '''          [dart_cli]          Generate a Very Good Dart CLI application.\n'''
      '          [dart_pkg]          Generate a reusable Dart package.\n'
      '          [flutter_pkg]       Generate a reusable Flutter package.\n'
      '          [flutter_plugin]    Generate a reusable Flutter plugin.\n'
      '\n'
      '''    --android                 The plugin supports the Android platform.\n'''
      '                              (defaults to "true")\n'
      '    --ios                     The plugin supports the iOS platform.\n'
      '                              (defaults to "true")\n'
      '    --web                     The plugin supports the Web platform.\n'
      '                              (defaults to "true")\n'
      '    --linux                   The plugin supports the Linux platform.\n'
      '                              (defaults to "true")\n'
      '    --macos                   The plugin supports the macOS platform.\n'
      '                              (defaults to "true")\n'
      '''    --windows                 The plugin supports the Windows platform.\n'''
      '                              (defaults to "true")\n'
      '\n'
      'Run "very_good help" to see global options.'
];

const pubspec = '''
name: example
environment:
  sdk: ">=2.13.0 <3.0.0"
''';

class MockArgResults extends Mock implements ArgResults {}

class MockAnalytics extends Mock implements Analytics {}

class MockLogger extends Mock implements Logger {}

class MockProgress extends Mock implements Progress {}

class MockPubUpdater extends Mock implements PubUpdater {}

class MockMasonGenerator extends Mock implements MasonGenerator {}

class MockGeneratorHooks extends Mock implements GeneratorHooks {}

class FakeDirectoryGeneratorTarget extends Fake
    implements DirectoryGeneratorTarget {}

class FakeLogger extends Fake implements Logger {}

void main() {
  group('create', () {
    late List<String> progressLogs;
    late Analytics analytics;
    late Logger logger;
    late Progress progress;

    final generatedFiles = List.filled(
      62,
      const GeneratedFile.created(path: ''),
    );

    setUpAll(() {
      registerFallbackValue(FakeDirectoryGeneratorTarget());
      registerFallbackValue(FakeLogger());
    });

    setUp(() {
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
      progress = MockProgress();
      when(() => progress.complete(any())).thenAnswer((_) {
        final message = _.positionalArguments.elementAt(0) as String?;
        if (message != null) progressLogs.add(message);
      });
      when(() => logger.progress(any())).thenReturn(progress);
    });

    test(
      'help',
      withRunner((commandRunner, logger, pubUpdater, printLogs) async {
        final result = await commandRunner.run(['create', '--help']);
        expect(printLogs, equals(expectedUsage));
        expect(result, equals(ExitCode.success.code));

        printLogs.clear();

        final resultAbbr = await commandRunner.run(['create', '-h']);
        expect(printLogs, equals(expectedUsage));
        expect(resultAbbr, equals(ExitCode.success.code));
      }),
    );

    test('can be instantiated without explicit logger', () {
      final command = CreateCommand(analytics: analytics);
      expect(command, isNotNull);
    });

    test(
      'throws UsageException when --project-name is missing '
      'and directory base is not a valid package name',
      withRunner((commandRunner, logger, pubUpdater, printLogs) async {
        const expectedErrorMessage = '".tmp" is not a valid package name.\n\n'
            'See https://dart.dev/tools/pub/pubspec#name for more information.';
        final result = await commandRunner.run(['create', '.tmp']);
        expect(result, equals(ExitCode.usage.code));
        verify(() => logger.err(expectedErrorMessage)).called(1);
      }),
    );

    test(
      'throws UsageException when --project-name is invalid',
      withRunner((commandRunner, logger, pubUpdater, printLogs) async {
        const expectedErrorMessage = '"My App" is not a valid package name.\n\n'
            'See https://dart.dev/tools/pub/pubspec#name for more information.';
        final result = await commandRunner.run(
          ['create', '.', '--project-name', 'My App'],
        );
        expect(result, equals(ExitCode.usage.code));
        verify(() => logger.err(expectedErrorMessage)).called(1);
      }),
    );

    test(
      'throws UsageException when output directory is missing',
      withRunner((commandRunner, logger, pubUpdater, printLogs) async {
        const expectedErrorMessage =
            'No option specified for the output directory.';
        final result = await commandRunner.run(['create']);
        expect(result, equals(ExitCode.usage.code));
        verify(() => logger.err(expectedErrorMessage)).called(1);
      }),
    );

    test(
      'throws UsageException when multiple output directories are provided',
      withRunner((commandRunner, logger, pubUpdater, printLogs) async {
        const expectedErrorMessage = 'Multiple output directories specified.';
        final result = await commandRunner.run(['create', './a', './b']);
        expect(result, equals(ExitCode.usage.code));
        verify(() => logger.err(expectedErrorMessage)).called(1);
      }),
    );

    test('completes successfully with correct output', () async {
      final argResults = MockArgResults();
      final hooks = MockGeneratorHooks();
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
      when(() => generator.hooks).thenReturn(hooks);
      when(
        () => hooks.preGen(
          vars: any(named: 'vars'),
          onVarsChanged: any(named: 'onVarsChanged'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => generator.generate(
          any(),
          vars: any(named: 'vars'),
          logger: any(named: 'logger'),
        ),
      ).thenAnswer((_) async {
        File(p.join('.tmp', 'pubspec.yaml')).writeAsStringSync(pubspec);
        return generatedFiles;
      });
      final result = await command.run();
      expect(result, equals(ExitCode.success.code));
      verify(() => logger.progress('Bootstrapping')).called(1);
      expect(
        progressLogs,
        equals(['Generated ${generatedFiles.length} file(s)']),
      );
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
            'org_name': 'com.example.verygoodcore',
            'description': '',
            'executable_name': 'my_app',
            'android': true,
            'ios': true,
            'web': true,
            'linux': true,
            'macos': true,
            'windows': true,
          },
          logger: logger,
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
      final hooks = MockGeneratorHooks();
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
      when(() => generator.hooks).thenReturn(hooks);
      when(
        () => hooks.preGen(
          vars: any(named: 'vars'),
          onVarsChanged: any(named: 'onVarsChanged'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => generator.generate(
          any(),
          vars: any(named: 'vars'),
          logger: any(named: 'logger'),
        ),
      ).thenAnswer((_) async {
        File(p.join('.tmp', 'pubspec.yaml')).writeAsStringSync(pubspec);
        return generatedFiles;
      });
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
            'org_name': 'com.example.verygoodcore',
            'description': 'very good description',
            'executable_name': 'my_app',
            'android': true,
            'ios': true,
            'web': true,
            'linux': true,
            'macos': true,
            'windows': true,
          },
          logger: logger,
        ),
      ).called(1);
    });

    group('org-name', () {
      group('--org', () {
        test(
          'is a valid alias',
          withRunner(
            (commandRunner, logger, pubUpdater, printLogs) async {
              const orgName = 'com.my.org';
              final tempDir = Directory.systemTemp.createTempSync();
              final result = await commandRunner.run(
                ['create', p.join(tempDir.path, 'example'), '--org', orgName],
              );
              expect(result, equals(ExitCode.success.code));
              tempDir.deleteSync(recursive: true);
            },
          ),
          timeout: const Timeout(Duration(seconds: 60)),
        );
      });

      group('invalid --org-name', () {
        String expectedErrorMessage(String orgName) =>
            '"$orgName" is not a valid org name.\n\n'
            'A valid org name has at least 2 parts separated by "."\n'
            'Each part must start with a letter and only include '
            'alphanumeric characters (A-Z, a-z, 0-9), underscores (_), '
            'and hyphens (-)\n'
            '(ex. very.good.org)';

        test(
          'no delimiters',
          withRunner((commandRunner, logger, pubUpdater, printLogs) async {
            const orgName = 'My App';
            final result = await commandRunner.run(
              ['create', '.', '--org-name', orgName],
            );
            expect(result, equals(ExitCode.usage.code));
            verify(() => logger.err(expectedErrorMessage(orgName))).called(1);
          }),
        );

        test(
          'less than 2 domains',
          withRunner((commandRunner, logger, pubUpdater, printLogs) async {
            const orgName = 'verybadtest';
            final result = await commandRunner.run(
              ['create', '.', '--org-name', orgName],
            );
            expect(result, equals(ExitCode.usage.code));
            verify(() => logger.err(expectedErrorMessage(orgName))).called(1);
          }),
        );

        test(
          'invalid characters present',
          withRunner((commandRunner, logger, pubUpdater, printLogs) async {
            const orgName = 'very%.bad@.#test';
            final result = await commandRunner.run(
              ['create', '.', '--org-name', orgName],
            );
            expect(result, equals(ExitCode.usage.code));
            verify(() => logger.err(expectedErrorMessage(orgName))).called(1);
          }),
        );

        test(
          'segment starts with a non-letter',
          withRunner((commandRunner, logger, pubUpdater, printLogs) async {
            const orgName = 'very.bad.1test';
            final result = await commandRunner.run(
              ['create', '.', '--org-name', orgName],
            );
            expect(result, equals(ExitCode.usage.code));
            verify(() => logger.err(expectedErrorMessage(orgName))).called(1);
          }),
        );

        test(
          'valid prefix but invalid suffix',
          withRunner((commandRunner, logger, pubUpdater, printLogs) async {
            const orgName = 'very.good.prefix.bad@@suffix';
            final result = await commandRunner.run(
              ['create', '.', '--org-name', orgName],
            );
            expect(result, equals(ExitCode.usage.code));
            verify(() => logger.err(expectedErrorMessage(orgName))).called(1);
          }),
        );
      });

      group('valid --org-name', () {
        Future<void> expectValidOrgName(String orgName) async {
          final argResults = MockArgResults();
          final hooks = MockGeneratorHooks();
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
          when(() => generator.hooks).thenReturn(hooks);
          when(
            () => hooks.preGen(
              vars: any(named: 'vars'),
              onVarsChanged: any(named: 'onVarsChanged'),
            ),
          ).thenAnswer((_) async {});
          when(
            () => generator.generate(
              any(),
              vars: any(named: 'vars'),
              logger: any(named: 'logger'),
            ),
          ).thenAnswer((_) async {
            File(p.join('.tmp', 'pubspec.yaml')).writeAsStringSync(pubspec);
            return generatedFiles;
          });
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
                'executable_name': 'my_app',
                'org_name': orgName,
                'android': true,
                'ios': true,
                'web': true,
                'linux': true,
                'macos': true,
                'windows': true,
              },
              logger: logger,
            ),
          ).called(1);
        }

        test('alphanumeric with three parts', () async {
          await expectValidOrgName('very.good.ventures');
        });

        test('containing an underscore', () async {
          await expectValidOrgName('very.good.test_case');
        });

        test('containing a hyphen', () async {
          await expectValidOrgName('very.bad.test-case');
        });

        test('single character parts', () async {
          await expectValidOrgName('v.g.v');
        });

        test('more than three parts', () async {
          await expectValidOrgName('very.good.ventures.app.identifier');
        });

        test('less than three parts', () async {
          await expectValidOrgName('verygood.ventures');
        });
      });
    });

    group('--template', () {
      group('invalid template name', () {
        test(
          'invalid template name',
          withRunner((commandRunner, logger, pubUpdater, printLogs) async {
            const templateName = 'badtemplate';
            const expectedErrorMessage =
                '''"$templateName" is not an allowed value for option "template".''';
            final result = await commandRunner.run(
              ['create', '.', '--template', templateName],
            );
            expect(result, equals(ExitCode.usage.code));
            verify(() => logger.err(expectedErrorMessage)).called(1);
          }),
        );
      });

      group('valid template names', () {
        Future<void> expectValidTemplateName({
          required String getPackagesMsg,
          required String templateName,
          required MasonBundle expectedBundle,
          required String expectedLogSummary,
        }) async {
          final argResults = MockArgResults();
          final hooks = MockGeneratorHooks();
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
          when(() => generator.hooks).thenReturn(hooks);
          when(
            () => hooks.preGen(
              vars: any(named: 'vars'),
              onVarsChanged: any(named: 'onVarsChanged'),
            ),
          ).thenAnswer((_) async {});
          when(
            () => generator.generate(
              any(),
              vars: any(named: 'vars'),
              logger: any(named: 'logger'),
            ),
          ).thenAnswer((_) async {
            File(p.join('.tmp', 'pubspec.yaml')).writeAsStringSync(pubspec);
            return generatedFiles;
          });
          final result = await command.run();
          expect(result, equals(ExitCode.success.code));
          verify(() => logger.progress('Bootstrapping')).called(1);
          expect(
            progressLogs,
            equals(['Generated ${generatedFiles.length} file(s)']),
          );
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
                'org_name': 'com.example.verygoodcore',
                'executable_name': 'my_app',
                'description': '',
                'android': true,
                'ios': true,
                'web': true,
                'linux': true,
                'macos': true,
                'windows': true,
              },
              logger: logger,
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
              timeout: VeryGoodCommandRunner.timeout,
            ),
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
            expectedLogSummary: 'Created a Very Good Dart Package! 🦄',
          );
        });

        test('flutter pkg template', () async {
          await expectValidTemplateName(
            getPackagesMsg: 'Running "flutter packages get" in .tmp',
            templateName: 'flutter_pkg',
            expectedBundle: flutterPackageBundle,
            expectedLogSummary: 'Created a Very Good Flutter Package! 🦄',
          );
        });

        test('flutter plugin template', () async {
          await expectValidTemplateName(
            getPackagesMsg: 'Running "flutter packages get" in .tmp',
            templateName: 'flutter_plugin',
            expectedBundle: flutterPluginBundle,
            expectedLogSummary: 'Created a Very Good Flutter Plugin! 🦄',
          );
        });

        test('dart CLI template', () async {
          await expectValidTemplateName(
            getPackagesMsg: 'Running "flutter pub get" in .tmp',
            templateName: 'dart_cli',
            expectedBundle: veryGoodDartCliBundle,
            expectedLogSummary: 'Created a Very Good Dart CLI application! 🦄',
          );
        });
      });
    });
  });
}
