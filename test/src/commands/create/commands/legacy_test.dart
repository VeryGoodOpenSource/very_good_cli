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
import 'package:very_good_cli/src/commands/create/commands/legacy.dart';
import 'package:very_good_cli/src/commands/create/templates/templates.dart';
import 'package:very_good_cli/src/logger_extension.dart';

import '../../../../helpers/helpers.dart';

const expectedUsage = [
  '''
Creates a new very good project in the specified directory.

Usage: very_good create <subcommand> <project-name> [arguments]
-h, --help    Print this usage information.

Available subcommands:
  dart_cli          Generate a Very Good Dart CLI application.
  dart_package      Generate a Very Good Dart package.
  docs_site         Generate a Very Good documentation site.
  flame_game        Generate a Very Good Flame game.
  flutter_app       Generate a Very Good Flutter application.
  flutter_package   Generate a Very Good Flutter package.
  flutter_plugin    Generate a Very Good Flutter plugin.

Run "very_good help" to see global options.'''
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
  group('create legacy', () {
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
        final result = await commandRunner.run(['create', 'legacy', '--help']);
        expect(printLogs, equals(expectedUsage));
        expect(result, equals(ExitCode.success.code));

        printLogs.clear();

        final resultAbbr = await commandRunner.run(['create', 'legacy', '-h']);
        expect(printLogs, equals(expectedUsage));
        expect(resultAbbr, equals(ExitCode.success.code));
      }),
    );

    test('can be instantiated without explicit generators', () {
      final command = LegacyCreateCommand(analytics: analytics, logger: logger);
      expect(command, isNotNull);
    });

    test(
      'throws UsageException when --project-name is missing '
      'and directory base is not a valid package name',
      withRunner((commandRunner, logger, pubUpdater, printLogs) async {
        const expectedErrorMessage = '".tmp" is not a valid package name.\n\n'
            'See https://dart.dev/tools/pub/pubspec#name for more information.';
        final result = await commandRunner.run(['create', 'legacy', '.tmp']);
        expect(result, equals(ExitCode.usage.code));
        verify(() => logger.err(expectedErrorMessage)).called(1);
      }),
    );

    test(
      'throws UsageException when project-name is invalid',
      withRunner((commandRunner, logger, pubUpdater, printLogs) async {
        const expectedErrorMessage = '"My App" is not a valid package name.\n\n'
            'See https://dart.dev/tools/pub/pubspec#name for more information.';
        final result = await commandRunner.run(['create', 'legacy', 'My App']);
        expect(result, equals(ExitCode.usage.code));
        verify(() => logger.err(expectedErrorMessage)).called(1);
      }),
    );

    test(
      'throws UsageException when multiple project names are provided',
      withRunner((commandRunner, logger, pubUpdater, printLogs) async {
        const expectedErrorMessage = 'Multiple project names specified.';
        final result = await commandRunner.run(['create', 'legacy', 'a', 'b']);
        expect(result, equals(ExitCode.usage.code));
        verify(() => logger.err(expectedErrorMessage)).called(1);
      }),
    );

    test('uses application_id when one is provided', () async {
      final argResults = MockArgResults();
      final hooks = MockGeneratorHooks();
      final generator = MockMasonGenerator();
      final command = LegacyCreateCommand(
        analytics: analytics,
        logger: logger,
        generatorFromBundle: (_) async => throw Exception('oops'),
        generatorFromBrick: (_) async => generator,
      )..argResultOverrides = argResults;
      when(() => argResults['output-directory'] as String?).thenReturn('.tmp');
      when(() => argResults['application-id'] as String?).thenReturn(
        'xyz.app.my_app',
      );
      when(() => argResults.rest).thenReturn(['my_app']);
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
        File(p.join('.tmp', 'my_app', 'pubspec.yaml'))
          ..createSync(recursive: true)
          ..writeAsStringSync(pubspec);
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
            'description': '',
            'executable_name': 'my_app',
            'application_id': 'xyz.app.my_app',
            'platforms': [
              'android',
              'ios',
              'web',
              'linux',
              'macos',
              'windows',
            ],
          },
          logger: logger,
        ),
      ).called(1);
    });

    test('uses remote brick when possible', () async {
      final argResults = MockArgResults();
      final hooks = MockGeneratorHooks();
      final generator = MockMasonGenerator();
      final command = LegacyCreateCommand(
        analytics: analytics,
        logger: logger,
        generatorFromBundle: (_) async => throw Exception('oops'),
        generatorFromBrick: (_) async => generator,
      )..argResultOverrides = argResults;
      when(() => argResults['output-directory'] as String?).thenReturn('.tmp');
      when(() => argResults.rest).thenReturn(['my_app']);
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
        File(p.join('.tmp', 'my_app', 'pubspec.yaml'))
          ..createSync(recursive: true)
          ..writeAsStringSync(pubspec);
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
            'description': '',
            'executable_name': 'my_app',
            'platforms': [
              'android',
              'ios',
              'web',
              'linux',
              'macos',
              'windows',
            ],
          },
          logger: logger,
        ),
      ).called(1);
    });

    test('uses bundled brick when remote brick is unavailable', () async {
      final argResults = MockArgResults();
      final hooks = MockGeneratorHooks();
      final generator = MockMasonGenerator();
      final command = LegacyCreateCommand(
        analytics: analytics,
        logger: logger,
        generatorFromBundle: (_) async => generator,
        generatorFromBrick: (_) async => throw Exception('oops'),
      )..argResultOverrides = argResults;
      when(() => argResults['output-directory'] as String?).thenReturn('.tmp');
      when(() => argResults.rest).thenReturn(['my_app']);
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
        File(p.join('.tmp', 'my_app', 'pubspec.yaml'))
          ..createSync(recursive: true)
          ..writeAsStringSync(pubspec);
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
            'description': '',
            'executable_name': 'my_app',
            'platforms': [
              'android',
              'ios',
              'web',
              'linux',
              'macos',
              'windows',
            ],
          },
          logger: logger,
        ),
      ).called(1);
    });

    test('throws when remote and bundled brick generator fails', () async {
      final argResults = MockArgResults();
      final command = LegacyCreateCommand(
        analytics: analytics,
        logger: logger,
        generatorFromBundle: (_) async => throw Exception('oops'),
        generatorFromBrick: (_) async => throw Exception('oops'),
      )..argResultOverrides = argResults;
      when(() => argResults['output-directory'] as String?).thenReturn('.tmp');
      when(() => argResults.rest).thenReturn(['my_app']);
      expect(command.run, throwsException);
    });

    test('adds publishable when provided', () async {
      final argResults = MockArgResults();
      final hooks = MockGeneratorHooks();
      final generator = MockMasonGenerator();
      final command = LegacyCreateCommand(
        analytics: analytics,
        logger: logger,
        generatorFromBundle: (_) async => throw Exception('oops'),
        generatorFromBrick: (_) async => generator,
      )..argResultOverrides = argResults;
      when(() => argResults['output-directory'] as String?).thenReturn('.tmp');
      when(() => argResults['publishable'] as bool?).thenReturn(
        true,
      );
      when(() => argResults.rest).thenReturn(['my_app']);
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
        File(p.join('.tmp', 'my_app', 'pubspec.yaml'))
          ..createSync(recursive: true)
          ..writeAsStringSync(pubspec);
        return generatedFiles;
      });
      final result = await command.run();
      expect(result, equals(ExitCode.success.code));
      final values = verify(
        () => generator.generate(
          any(
            that: isA<DirectoryGeneratorTarget>().having(
              (g) => g.dir.path,
              'dir',
              '.tmp',
            ),
          ),
          vars: captureAny(named: 'vars'),
          logger: logger,
        ),
      ).captured;

      final vars = values.first as Map<String, dynamic>;
      expect(vars['publishable'], isTrue);
    });

    test('completes successfully with correct output', () async {
      final argResults = MockArgResults();
      final hooks = MockGeneratorHooks();
      final generator = MockMasonGenerator();
      final command = LegacyCreateCommand(
        analytics: analytics,
        logger: logger,
        generatorFromBundle: (_) async => generator,
        generatorFromBrick: (_) async => generator,
      )..argResultOverrides = argResults;
      when(() => argResults['output-directory'] as String?).thenReturn('.tmp');
      when(() => argResults.rest).thenReturn(['my_app']);
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
        File(p.join('.tmp', 'my_app', 'pubspec.yaml'))
          ..createSync(recursive: true)
          ..writeAsStringSync(pubspec);
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
        () => logger.progress('Running "flutter packages get" in .tmp/my_app'),
      ).called(1);
      verify(() => logger.created('Created a Very Good App! 🦄')).called(1);
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
            'platforms': [
              'android',
              'ios',
              'web',
              'linux',
              'macos',
              'windows',
            ],
          },
          logger: logger,
        ),
      ).called(1);
      verify(
        () => analytics.sendEvent(
          'create legacy',
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
      final command = LegacyCreateCommand(
        analytics: analytics,
        logger: logger,
        generatorFromBundle: (_) async => generator,
        generatorFromBrick: (_) async => generator,
      )..argResultOverrides = argResults;
      when(() => argResults.rest).thenReturn(['my_app']);
      when(
        () => argResults['description'] as String?,
      ).thenReturn('very good description');
      when(() => argResults['output-directory'] as String?).thenReturn('.tmp');
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
        File(p.join('.tmp', 'my_app', 'pubspec.yaml'))
          ..createSync(recursive: true)
          ..writeAsStringSync(pubspec);
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
            'platforms': [
              'android',
              'ios',
              'web',
              'linux',
              'macos',
              'windows',
            ],
          },
          logger: logger,
        ),
      ).called(1);
    });

    group('org-name', () {
      group('--org', () {
        test(
          'is a valid alias',
          timeout: const Timeout(Duration(seconds: 60)),
          withRunner(
            (commandRunner, logger, pubUpdater, printLogs) async {
              const orgName = 'com.my.org';
              final tempDirectory = Directory.systemTemp.createTempSync();
              addTearDown(() => tempDirectory.deleteSync(recursive: true));

              final result = await commandRunner.run(
                [
                  'create',
                  'example',
                  '-o',
                  tempDirectory.path,
                  '--org',
                  orgName
                ],
              );
              expect(result, equals(ExitCode.success.code));
            },
          ),
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
              ['create', 'my_app', '--org-name', orgName],
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
              ['create', 'my_app', '--org-name', orgName],
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
              ['create', 'my_app', '--org-name', orgName],
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
              ['create', 'my_app', '--org-name', orgName],
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
              ['create', 'my_app', '--org-name', orgName],
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
          final command = LegacyCreateCommand(
            analytics: analytics,
            logger: logger,
            generatorFromBundle: (_) async => generator,
            generatorFromBrick: (_) async => generator,
          )..argResultOverrides = argResults;
          when(() => argResults.rest).thenReturn(['my_app']);
          when(() => argResults['org-name'] as String?).thenReturn(orgName);
          when(() => argResults['output-directory'] as String?)
              .thenReturn('.tmp');
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
            File(p.join('.tmp', 'my_app', 'pubspec.yaml'))
              ..createSync(recursive: true)
              ..writeAsStringSync(pubspec);
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
                'platforms': [
                  'android',
                  'ios',
                  'web',
                  'linux',
                  'macos',
                  'windows',
                ],
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
              ['create', 'my_app', '--template', templateName],
            );
            expect(result, equals(ExitCode.usage.code));
            verify(() => logger.err(expectedErrorMessage)).called(1);
          }),
        );
      });

      group('valid template names', () {
        Future<void> expectValidTemplateName({
          required String templateName,
          required MasonBundle expectedBundle,
          required String expectedLogSummary,
          String? progressLog,
        }) async {
          final argResults = MockArgResults();
          final hooks = MockGeneratorHooks();
          final generator = MockMasonGenerator();
          final command = LegacyCreateCommand(
            analytics: analytics,
            logger: logger,
            generatorFromBundle: (bundle) async {
              expect(bundle, equals(expectedBundle));
              return generator;
            },
            generatorFromBrick: (_) async => generator,
          )..argResultOverrides = argResults;
          when(() => argResults.rest).thenReturn(['my_app']);
          when(
            () => argResults['template'] as String?,
          ).thenReturn(templateName);
          when(
            () => argResults['output-directory'] as String?,
          ).thenReturn('.tmp');
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
            File(p.join('.tmp', 'my_app', 'pubspec.yaml'))
              ..createSync(recursive: true)
              ..writeAsStringSync(pubspec);
            return generatedFiles;
          });

          final result = await command.run();

          expect(result, equals(ExitCode.success.code));
          verify(
            () => logger.warn(
              'Deprecated usage of the create command: '
              "run 'very_good create --help' to see the available options.",
            ),
          ).called(1);
          verify(() => logger.progress('Bootstrapping')).called(1);
          expect(
            progressLogs,
            equals(['Generated ${generatedFiles.length} file(s)']),
          );
          if (progressLog != null) {
            verify(() => logger.progress(progressLog)).called(1);
          }
          verify(() => logger.created(expectedLogSummary)).called(1);
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
                'platforms': [
                  'android',
                  'ios',
                  'web',
                  'linux',
                  'macos',
                  'windows',
                ],
              },
              logger: logger,
            ),
          ).called(1);
          verify(
            () => analytics.sendEvent(
              'create legacy',
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
            progressLog: 'Running "flutter packages get" in .tmp/my_app',
            templateName: 'core',
            expectedBundle: veryGoodCoreBundle,
            expectedLogSummary: 'Created a Very Good App! 🦄',
          );
        });

        test('dart pkg template', () async {
          await expectValidTemplateName(
            progressLog: 'Running "flutter pub get" in .tmp/my_app',
            templateName: 'dart_pkg',
            expectedBundle: veryGoodDartPackageBundle,
            expectedLogSummary: 'Created a Very Good Dart Package! 🦄',
          );
        });

        test('flutter pkg template', () async {
          await expectValidTemplateName(
            progressLog: 'Running "flutter packages get" in .tmp/my_app',
            templateName: 'flutter_pkg',
            expectedBundle: veryGoodFlutterPackageBundle,
            expectedLogSummary: 'Created a Very Good Flutter Package! 🦄',
          );
        });

        test('flutter plugin template', () async {
          await expectValidTemplateName(
            progressLog: 'Running "flutter packages get" in .tmp/my_app',
            templateName: 'flutter_plugin',
            expectedBundle: veryGoodFlutterPluginBundle,
            expectedLogSummary: 'Created a Very Good Flutter Plugin! 🦄',
          );
        });

        test('dart cli template', () async {
          await expectValidTemplateName(
            progressLog: 'Running "flutter pub get" in .tmp/my_app',
            templateName: 'dart_cli',
            expectedBundle: veryGoodDartCliBundle,
            expectedLogSummary: 'Created a Very Good Dart CLI application! 🦄',
          );
        });

        test('docs site template', () async {
          await expectValidTemplateName(
            templateName: 'docs_site',
            expectedBundle: veryGoodDartCliBundle,
            expectedLogSummary: 'Created a Very Good documentation site! 🦄',
          );
        });

        test('flame game template', () async {
          await expectValidTemplateName(
            templateName: 'flame_game',
            expectedBundle: veryGoodFlameGameBundle,
            expectedLogSummary:
                'Created a Very Good Game powered by Flame! 🔥🦄',
          );
        });
      });
    });
  });
}
