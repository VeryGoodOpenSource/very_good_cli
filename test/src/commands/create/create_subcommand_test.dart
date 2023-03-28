import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:mason/mason.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:usage/usage.dart';
import 'package:very_good_cli/src/commands/create/commands/create_subcommand.dart';
import 'package:very_good_cli/src/commands/create/templates/template.dart';

class MockTemplate extends Mock implements Template {}

class MockAnalytics extends Mock implements Analytics {}

class MockLogger extends Mock implements Logger {}

class MockProgress extends Mock implements Progress {}

class MockMasonGenerator extends Mock implements MasonGenerator {}

class MockBundle extends Mock implements MasonBundle {}

class MockGeneratorHooks extends Mock implements GeneratorHooks {}

class FakeLogger extends Fake implements Logger {}

class FakeDirectoryGeneratorTarget extends Fake
    implements DirectoryGeneratorTarget {}

class FakeDirectory extends Fake implements Directory {}

class _TestCreateSubCommand extends CreateSubCommand {
  _TestCreateSubCommand({
    required this.template,
    required super.analytics,
    required super.logger,
    required super.generatorFromBundle,
    required super.generatorFromBrick,
  });

  @override
  final String name = 'create_subcommand';

  @override
  final String description = 'Create command';

  @override
  final Template template;
}

class _TestCreateSubCommandWithOrgName extends _TestCreateSubCommand
    with OrgName {
  _TestCreateSubCommandWithOrgName({
    required super.template,
    required super.analytics,
    required super.logger,
    required super.generatorFromBundle,
    required super.generatorFromBrick,
  });
}

class _TestCreateSubCommandWithPublishable extends _TestCreateSubCommand
    with Publishable {
  _TestCreateSubCommandWithPublishable({
    required super.template,
    required super.analytics,
    required super.logger,
    required super.generatorFromBundle,
    required super.generatorFromBrick,
  });
}

class _TestCreateSubCommandMultiTemplate extends CreateSubCommand
    with MultiTemplates {
  _TestCreateSubCommandMultiTemplate({
    required this.templates,
    required super.analytics,
    required super.logger,
    required super.generatorFromBundle,
    required super.generatorFromBrick,
  });

  @override
  final String name = 'create_subcommand';

  @override
  final String description = 'Create command';

  @override
  final List<Template> templates;
}

class _TestCommandRunner extends CommandRunner<int> {
  _TestCommandRunner({
    required this.command,
  }) : super('runner', 'Test command runner') {
    addCommand(command);
  }

  final Command<int> command;
}

void main() {
  final generatedFiles = List.filled(10, const GeneratedFile.created(path: ''));

  late List<String> progressLogs;
  late Analytics analytics;
  late Logger logger;
  late Progress progress;

  setUpAll(() {
    registerFallbackValue(FakeDirectoryGeneratorTarget());
    registerFallbackValue(FakeLogger());
    registerFallbackValue(FakeDirectory());
  });

  setUp(() {
    progressLogs = <String>[];

    analytics = MockAnalytics();
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

  group('CreateSubCommand', () {
    const expectedUsage = '''
Usage: very_good create create_subcommand <project-name> [arguments]
-h, --help                Print this usage information.
-o, --output-directory    The desired output directory when creating a new project.
    --description         The description for this new project.
                          (defaults to "A Very Good Project created by Very Good CLI.")

Run "runner help" to see global options.''';

    late Template template;
    late MockBundle bundle;

    setUp(() {
      bundle = MockBundle();
      when(() => bundle.name).thenReturn('test');
      when(() => bundle.description).thenReturn('Test bundle');
      when(() => bundle.version).thenReturn('<bundleversion>');
      template = MockTemplate();
      when(() => template.name).thenReturn('test');
      when(() => template.bundle).thenReturn(bundle);
      when(() => template.onGenerateComplete(any(), any())).thenAnswer(
        (_) async {},
      );
      when(
        () => analytics.sendEvent(any(), any(), label: any(named: 'label')),
      ).thenAnswer((_) async {});
    });

    group('can be instantiated', () {
      test('with default options', () {
        final command = _TestCreateSubCommand(
          template: template,
          analytics: analytics,
          logger: logger,
          generatorFromBundle: null,
          generatorFromBrick: null,
        );
        expect(command.name, isNotNull);
        expect(command.description, isNotNull);
        expect(command.argParser.options, {
          'help': isA<Option>(),
          'output-directory': isA<Option>()
              .having((o) => o.isSingle, 'isSingle', true)
              .having((o) => o.abbr, 'abbr', 'o')
              .having((o) => o.defaultsTo, 'defaultsTo', null)
              .having((o) => o.mandatory, 'mandatory', false),
          'description': isA<Option>()
              .having((o) => o.isSingle, 'isSingle', true)
              .having((o) => o.abbr, 'abbr', null)
              .having(
                (o) => o.defaultsTo,
                'defaultsTo',
                'A Very Good Project created by Very Good CLI.',
              )
              .having((o) => o.mandatory, 'mandatory', false),
        });
        expect(command.argParser.commands, isEmpty);
      });
    });

    group('running command', () {
      late GeneratorHooks hooks;
      late MasonGenerator generator;

      late _TestCommandRunner runner;

      setUp(() {
        hooks = MockGeneratorHooks();
        generator = MockMasonGenerator();

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
          return generatedFiles;
        });

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
          return generatedFiles;
        });

        final command = _TestCreateSubCommand(
          template: template,
          analytics: analytics,
          logger: logger,
          generatorFromBundle: (_) async => throw Exception('oops'),
          generatorFromBrick: (_) async => generator,
        );

        runner = _TestCommandRunner(command: command);
      });

      group('parsing of options', () {
        test('parses description, output dir and project name', () async {
          final result = await runner.run([
            'create_subcommand',
            'test_project',
            '--description',
            'test_desc',
            '--output-directory',
            'test_dir'
          ]);

          expect(result, equals(ExitCode.success.code));
          verify(() => logger.progress('Bootstrapping')).called(1);

          verify(
            () => hooks.preGen(
              vars: <String, dynamic>{
                'project_name': 'test_project',
                'description': 'test_desc',
              },
              onVarsChanged: any(named: 'onVarsChanged'),
            ),
          );
          verify(
            () => generator.generate(
              any(
                that: isA<DirectoryGeneratorTarget>().having(
                  (g) => g.dir.path,
                  'dir',
                  'test_dir',
                ),
              ),
              vars: <String, dynamic>{
                'project_name': 'test_project',
                'description': 'test_desc',
              },
              logger: logger,
            ),
          ).called(1);
          expect(
            progressLogs,
            equals(['Generated ${generatedFiles.length} file(s)']),
          );
          verify(
            () => template.onGenerateComplete(
              logger,
              any(
                that: isA<Directory>().having(
                  (d) => d.path,
                  'path',
                  'test_dir/test_project',
                ),
              ),
            ),
          ).called(1);

          verify(
            () => analytics.sendEvent(
              'create create_subcommand',
              'generator_id',
              label: 'generator description',
            ),
          ).called(1);
        });

        test('uses default values for omitted options', () async {
          final result = await runner.run([
            'create_subcommand',
            'test_project',
          ]);

          expect(result, equals(ExitCode.success.code));
          verify(() => logger.progress('Bootstrapping')).called(1);

          verify(
            () {
              return hooks.preGen(
                vars: <String, dynamic>{
                  'project_name': 'test_project',
                  'description':
                      'A Very Good Project created by Very Good CLI.',
                },
                onVarsChanged: any(named: 'onVarsChanged'),
              );
            },
          );

          verify(
            () => generator.generate(
              any(
                that: isA<DirectoryGeneratorTarget>().having(
                  (g) => g.dir.path,
                  'dir',
                  '.',
                ),
              ),
              vars: <String, dynamic>{
                'project_name': 'test_project',
                'description': 'A Very Good Project created by Very Good CLI.',
              },
              logger: logger,
            ),
          ).called(1);

          verify(
            () => template.onGenerateComplete(
              logger,
              any(
                that: isA<Directory>().having(
                  (d) => d.path,
                  'path',
                  './test_project',
                ),
              ),
            ),
          ).called(1);
        });

        group('validates project name', () {
          test(
            'throws UsageException when project-name is omitted',
            () async {
              await expectLater(
                () async {
                  await runner.run(
                    [
                      'create_subcommand',
                      '--description="some description"',
                    ],
                  );
                },
                throwsA(
                  isA<UsageException>()
                      .having((e) => e.usage, 'usage', expectedUsage)
                      .having(
                        (e) => e.message,
                        'message',
                        'No option specified for the project name.',
                      ),
                ),
              );
            },
          );

          test(
            'throws UsageException when project-name is invalid',
            () async {
              await expectLater(
                () async {
                  await runner.run(['create_subcommand', 'invalid-name']);
                },
                throwsA(
                  isA<UsageException>()
                      .having((e) => e.usage, 'usage', expectedUsage)
                      .having(
                    (e) => e.message,
                    'message',
                    '''
"invalid-name" is not a valid package name.

See https://dart.dev/tools/pub/pubspec#name for more information.''',
                  ),
                ),
              );
            },
          );

          test(
            'throws UsageException when multiple project names are provided',
            () async {
              await expectLater(
                () async {
                  await runner.run(
                    [
                      'create_subcommand',
                      'name',
                      'other_name',
                    ],
                  );
                },
                throwsA(
                  isA<UsageException>()
                      .having((e) => e.usage, 'usage', expectedUsage)
                      .having(
                        (e) => e.message,
                        'message',
                        'Multiple project names specified.',
                      ),
                ),
              );
            },
          );
        });
      });

      group('mason generator selection', () {
        test('uses remote brick when possible', () async {
          final command = _TestCreateSubCommand(
            template: template,
            analytics: analytics,
            logger: logger,
            generatorFromBundle: (_) async {
              throw UnsupportedError('this test should not reach this point');
            },
            generatorFromBrick: (_) async => generator,
          );

          runner = _TestCommandRunner(command: command);

          final result = await runner.run([
            'create_subcommand',
            'test_project',
          ]);

          expect(result, equals(ExitCode.success.code));

          verify(
            () => generator.generate(
              any(
                that: isA<DirectoryGeneratorTarget>().having(
                  (g) => g.dir.path,
                  'dir',
                  '.',
                ),
              ),
              vars: <String, dynamic>{
                'project_name': 'test_project',
                'description': 'A Very Good Project created by Very Good CLI.',
              },
              logger: logger,
            ),
          ).called(1);
        });

        test(
          'uses bundled brick when remote brick is unavailable',
          () async {
            final command = _TestCreateSubCommand(
              template: template,
              analytics: analytics,
              logger: logger,
              generatorFromBundle: (_) async => generator,
              generatorFromBrick: (_) async {
                throw Exception('oh no, cannot retrieve remote brick 👀');
              },
            );

            runner = _TestCommandRunner(command: command);

            final result = await runner.run([
              'create_subcommand',
              'test_project',
            ]);

            expect(result, equals(ExitCode.success.code));

            verify(
              () => generator.generate(
                any(
                  that: isA<DirectoryGeneratorTarget>().having(
                    (g) => g.dir.path,
                    'dir',
                    '.',
                  ),
                ),
                vars: <String, dynamic>{
                  'project_name': 'test_project',
                  'description':
                      'A Very Good Project created by Very Good CLI.',
                },
                logger: logger,
              ),
            ).called(1);
          },
        );
      });
    });
  });
  group('OrgName', () {
    const expectedUsage = '''
Usage: very_good create create_subcommand <project-name> [arguments]
-h, --help                Print this usage information.
-o, --output-directory    The desired output directory when creating a new project.
    --description         The description for this new project.
                          (defaults to "A Very Good Project created by Very Good CLI.")
    --org-name            The organization for this new project.
                          (defaults to "com.example.verygoodcore")

Run "runner help" to see global options.''';

    late Template template;
    late MockBundle bundle;

    setUp(() {
      bundle = MockBundle();
      when(() => bundle.name).thenReturn('test');
      when(() => bundle.description).thenReturn('Test bundle');
      when(() => bundle.version).thenReturn('<bundleversion>');
      template = MockTemplate();
      when(() => template.name).thenReturn('test');
      when(() => template.bundle).thenReturn(bundle);
      when(() => template.onGenerateComplete(any(), any())).thenAnswer(
        (_) async {},
      );
      when(
        () => analytics.sendEvent(any(), any(), label: any(named: 'label')),
      ).thenAnswer((_) async {});
    });

    group('can be instantiated', () {
      test('with default options', () {
        final command = _TestCreateSubCommandWithOrgName(
          template: template,
          analytics: analytics,
          logger: logger,
          generatorFromBundle: null,
          generatorFromBrick: null,
        );

        expect(
          command.argParser.options['org-name'],
          isA<Option>()
              .having((o) => o.isSingle, 'isSingle', true)
              .having((o) => o.abbr, 'abbr', null)
              .having(
                (o) => o.defaultsTo,
                'defaultsTo',
                'com.example.verygoodcore',
              )
              .having(
            (o) => o.aliases,
            'aliases',
            ['org'],
          ),
        );
        expect(command.argParser.commands, isEmpty);
      });
    });

    group('parsing of options', () {
      late GeneratorHooks hooks;
      late MasonGenerator generator;
      late _TestCommandRunner runner;

      setUp(() {
        hooks = MockGeneratorHooks();
        generator = MockMasonGenerator();

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
          return generatedFiles;
        });

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
          return generatedFiles;
        });

        final command = _TestCreateSubCommandWithOrgName(
          template: template,
          analytics: analytics,
          logger: logger,
          generatorFromBundle: (_) async => throw Exception('oops'),
          generatorFromBrick: (_) async => generator,
        );

        runner = _TestCommandRunner(command: command);
      });

      test('parses org name', () async {
        final result = await runner.run([
          'create_subcommand',
          'test_project',
          '--org-name',
          'com.my.org',
        ]);

        expect(result, equals(ExitCode.success.code));

        verify(
          () => hooks.preGen(
            vars: any(
              named: 'vars',
              that: isA<Map<String, dynamic>>().having(
                (description) => description['org_name'],
                'org_name',
                'com.my.org',
              ),
            ),
            onVarsChanged: any(named: 'onVarsChanged'),
          ),
        );

        verify(
          () => generator.generate(
            any(
              that: isA<DirectoryGeneratorTarget>(),
            ),
            vars: any(
              named: 'vars',
              that: isA<Map<String, dynamic>>().having(
                (vars) {
                  return vars['org_name'];
                },
                'org_name',
                'com.my.org',
              ),
            ),
            logger: logger,
          ),
        ).called(1);
      });

      test('parses org name from alias', () async {
        final result = await runner.run([
          'create_subcommand',
          'test_project',
          '--org',
          'com.my.org',
        ]);

        expect(result, equals(ExitCode.success.code));

        verify(
          () => hooks.preGen(
            vars: any(
              named: 'vars',
              that: isA<Map<String, dynamic>>().having(
                (description) => description['org_name'],
                'org_name',
                'com.my.org',
              ),
            ),
            onVarsChanged: any(named: 'onVarsChanged'),
          ),
        );

        verify(
          () => generator.generate(
            any(
              that: isA<DirectoryGeneratorTarget>(),
            ),
            vars: any(
              named: 'vars',
              that: isA<Map<String, dynamic>>().having(
                (vars) {
                  return vars['org_name'];
                },
                'org_name',
                'com.my.org',
              ),
            ),
            logger: logger,
          ),
        ).called(1);
      });

      test('uses default values for omitted options', () async {
        final result = await runner.run([
          'create_subcommand',
          'test_project',
        ]);

        expect(result, equals(ExitCode.success.code));

        verify(
          () => hooks.preGen(
            vars: any(
              named: 'vars',
              that: isA<Map<String, dynamic>>().having(
                (description) => description['org_name'],
                'org_name',
                'com.example.verygoodcore',
              ),
            ),
            onVarsChanged: any(named: 'onVarsChanged'),
          ),
        );

        verify(
          () => generator.generate(
            any(
              that: isA<DirectoryGeneratorTarget>(),
            ),
            vars: any(
              named: 'vars',
              that: isA<Map<String, dynamic>>().having(
                (vars) {
                  return vars['org_name'];
                },
                'org_name',
                'com.example.verygoodcore',
              ),
            ),
            logger: logger,
          ),
        ).called(1);
      });

      group('validates org name', () {
        test(
          'throws UsageException when org-name has no delimiters',
          () async {
            await expectLater(
              () async {
                await runner.run([
                  'create_subcommand',
                  'test_project',
                  '--org-name',
                  'invalid org name',
                ]);
              },
              throwsA(
                isA<UsageException>()
                    .having((e) => e.usage, 'usage', expectedUsage)
                    .having(
                  (e) => e.message,
                  'message',
                  '''
"invalid org name" is not a valid org name.

A valid org name has at least 2 parts separated by "."
Each part must start with a letter and only include alphanumeric characters (A-Z, a-z, 0-9), underscores (_), and hyphens (-)
(ex. very.good.org)''',
                ),
              ),
            );
          },
        );

        test(
          'throws UsageException when org-name has less than two levels',
          () async {
            await expectLater(
              () async {
                await runner.run([
                  'create_subcommand',
                  'test_project',
                  '--org-name',
                  'verybadtest',
                ]);
              },
              throwsA(
                isA<UsageException>()
                    .having((e) => e.usage, 'usage', expectedUsage)
                    .having(
                  (e) => e.message,
                  'message',
                  '''
"verybadtest" is not a valid org name.

A valid org name has at least 2 parts separated by "."
Each part must start with a letter and only include alphanumeric characters (A-Z, a-z, 0-9), underscores (_), and hyphens (-)
(ex. very.good.org)''',
                ),
              ),
            );
          },
        );

        test(
          'throws UsageException when org-name has invalid characters',
          () async {
            await expectLater(
              () async {
                await runner.run([
                  'create_subcommand',
                  'test_project',
                  '--org-name',
                  'very%.bad@.#test',
                ]);
              },
              throwsA(
                isA<UsageException>()
                    .having((e) => e.usage, 'usage', expectedUsage)
                    .having(
                  (e) => e.message,
                  'message',
                  '''
"very%.bad@.#test" is not a valid org name.

A valid org name has at least 2 parts separated by "."
Each part must start with a letter and only include alphanumeric characters (A-Z, a-z, 0-9), underscores (_), and hyphens (-)
(ex. very.good.org)''',
                ),
              ),
            );
          },
        );
      });
    });
  });
  group('MultiTemplates', () {
    const expectedUsage = '''
Usage: very_good create create_subcommand <project-name> [arguments]
-h, --help                         Print this usage information.
-o, --output-directory             The desired output directory when creating a new project.
    --description                  The description for this new project.
                                   (defaults to "A Very Good Project created by Very Good CLI.")
-t, --template                     The template used to generate this new project.

          [template1] (default)    template1 help
          [template2]              template2 help

Run "runner help" to see global options.''';

    late MockBundle bundle;
    late List<Template> templates;

    setUp(() {
      bundle = MockBundle();
      when(() => bundle.name).thenReturn('test');
      when(() => bundle.description).thenReturn('Test bundle');
      when(() => bundle.version).thenReturn('<bundleversion>');
      when(
        () => analytics.sendEvent(
          any(),
          any(),
          label: any(named: 'label'),
        ),
      ).thenAnswer((_) async {});

      final template1 = MockTemplate();
      when(() => template1.name).thenReturn('template1');
      when(() => template1.help).thenReturn('template1 help');
      when(() => template1.bundle).thenReturn(bundle);
      when(() => template1.onGenerateComplete(any(), any())).thenAnswer(
        (_) async {},
      );

      final template2 = MockTemplate();
      when(() => template2.name).thenReturn('template2');
      when(() => template2.help).thenReturn('template2 help');
      when(() => template2.bundle).thenReturn(bundle);
      when(() => template2.onGenerateComplete(any(), any())).thenAnswer(
        (_) async {},
      );

      templates = [template1, template2];
    });

    group('can be instantiated', () {
      test('with default options', () {
        final command = _TestCreateSubCommandMultiTemplate(
          templates: templates,
          analytics: analytics,
          logger: logger,
          generatorFromBundle: null,
          generatorFromBrick: null,
        );
        expect(
          command.argParser.options['template'],
          isA<Option>()
              .having((o) => o.isSingle, 'isSingle', true)
              .having((o) => o.abbr, 'abbr', 't')
              .having(
                (o) => o.defaultsTo,
                'defaultsTo',
                'template1',
              )
              .having(
            (o) => o.allowed,
            'allowed',
            ['template1', 'template2'],
          ).having(
            (o) => o.allowedHelp,
            'allowedHelp',
            {
              'template1': 'template1 help',
              'template2': 'template2 help',
            },
          ),
        );
        expect(command.argParser.commands, isEmpty);
      });
    });

    group('parsing of options', () {
      late GeneratorHooks hooks;
      late MasonGenerator generator;
      late _TestCommandRunner runner;

      setUp(() {
        hooks = MockGeneratorHooks();
        generator = MockMasonGenerator();

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
          return generatedFiles;
        });

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
          return generatedFiles;
        });

        final command = _TestCreateSubCommandMultiTemplate(
          templates: templates,
          analytics: analytics,
          logger: logger,
          generatorFromBundle: (_) async => throw Exception('oops'),
          generatorFromBrick: (_) async => generator,
        );

        runner = _TestCommandRunner(command: command);
      });

      test('selects the correct template', () async {
        final result = await runner.run([
          'create_subcommand',
          'test_project',
          '--template',
          'template2',
        ]);
        expect(result, equals(ExitCode.success.code));
        final template1 = templates[0];
        final template2 = templates[1];
        verifyNever(() => template1.onGenerateComplete(logger, any()));
        verify(() => template2.onGenerateComplete(logger, any())).called(1);
      });

      test('selects the default template when omitted', () async {
        final result = await runner.run([
          'create_subcommand',
          'test_project',
        ]);
        expect(result, equals(ExitCode.success.code));
        final template1 = templates[0];
        final template2 = templates[1];
        verify(() => template1.onGenerateComplete(logger, any())).called(1);
        verifyNever(() => template2.onGenerateComplete(logger, any()));
      });

      group('validates template name', () {
        test('throws UsageException when --template is invalid', () async {
          await expectLater(
            () async {
              await runner.run([
                'create_subcommand',
                'test_project',
                '--template',
                'template3',
              ]);
            },
            throwsA(
              isA<UsageException>()
                  .having((e) => e.usage, 'usage', expectedUsage)
                  .having(
                    (e) => e.message,
                    'message',
                    '"template3" is not an allowed value for option '
                        '"template".',
                  ),
            ),
          );
        });
      });
    });
  });

  group('Publishable', () {
    const expectedUsage = '''
Usage: very_good create create_subcommand <project-name> [arguments]
-h, --help                Print this usage information.
-o, --output-directory    The desired output directory when creating a new project.
    --description         The description for this new project.
                          (defaults to "A Very Good Project created by Very Good CLI.")
    --publishable         Whether the generated project is intended to be published.

Run "runner help" to see global options.''';

    late Template template;
    late MockBundle bundle;

    setUp(() {
      bundle = MockBundle();
      when(() => bundle.name).thenReturn('test');
      when(() => bundle.description).thenReturn('Test bundle');
      when(() => bundle.version).thenReturn('<bundleversion>');
      template = MockTemplate();
      when(() => template.name).thenReturn('test');
      when(() => template.bundle).thenReturn(bundle);
      when(() => template.onGenerateComplete(any(), any())).thenAnswer(
        (_) async {},
      );
      when(
        () => analytics.sendEvent(any(), any(), label: any(named: 'label')),
      ).thenAnswer((_) async {});
    });

    group('can be instantiated', () {
      test('with default options', () {
        final command = _TestCreateSubCommandWithPublishable(
          template: template,
          analytics: analytics,
          logger: logger,
          generatorFromBundle: null,
          generatorFromBrick: null,
        );

        expect(
          command.argParser.options['publishable'],
          isA<Option>()
              .having((o) => o.isFlag, 'isFlag', true)
              .having((o) => o.abbr, 'abbr', null)
              .having((o) => o.defaultsTo, 'defaultsTo', false)
              .having((o) => o.aliases, 'aliases', <String>[]),
        );
        expect(command.argParser.commands, isEmpty);
      });
    });

    group('parsing of options', () {
      late GeneratorHooks hooks;
      late MasonGenerator generator;
      late _TestCommandRunner runner;

      setUp(() {
        hooks = MockGeneratorHooks();
        generator = MockMasonGenerator();

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
          return generatedFiles;
        });

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
          return generatedFiles;
        });

        final command = _TestCreateSubCommandWithPublishable(
          template: template,
          analytics: analytics,
          logger: logger,
          generatorFromBundle: (_) async => throw Exception('oops'),
          generatorFromBrick: (_) async => generator,
        );

        runner = _TestCommandRunner(command: command);
      });

      test('parses publishable', () async {
        final result = await runner.run([
          'create_subcommand',
          'test_project',
          '--publishable',
        ]);

        expect(result, equals(ExitCode.success.code));

        verify(
          () => hooks.preGen(
            vars: any(
              named: 'vars',
              that: isA<Map<String, dynamic>>().having(
                (description) => description['publishable'],
                'publishable',
                true,
              ),
            ),
            onVarsChanged: any(named: 'onVarsChanged'),
          ),
        );

        verify(
          () => generator.generate(
            any(
              that: isA<DirectoryGeneratorTarget>(),
            ),
            vars: any(
              named: 'vars',
              that: isA<Map<String, dynamic>>().having(
                (vars) {
                  return vars['publishable'];
                },
                'publishable',
                true,
              ),
            ),
            logger: logger,
          ),
        ).called(1);
      });

      test('uses default values for omitted options', () async {
        final result = await runner.run([
          'create_subcommand',
          'test_project',
        ]);

        expect(result, equals(ExitCode.success.code));

        verify(
          () => hooks.preGen(
            vars: any(
              named: 'vars',
              that: isA<Map<String, dynamic>>().having(
                (description) => description['publishable'],
                'publishable',
                false,
              ),
            ),
            onVarsChanged: any(named: 'onVarsChanged'),
          ),
        );

        verify(
          () => generator.generate(
            any(
              that: isA<DirectoryGeneratorTarget>(),
            ),
            vars: any(
              named: 'vars',
              that: isA<Map<String, dynamic>>().having(
                (description) => description['publishable'],
                'publishable',
                false,
              ),
            ),
            logger: logger,
          ),
        ).called(1);
      });

      group('validates publishable', () {
        test('throws UsageException when --template is invalid', () async {
          await expectLater(
            () async {
              await runner.run([
                'create_subcommand',
                'test_project',
                '--no-publishable',
              ]);
            },
            throwsA(
              isA<UsageException>()
                  .having((e) => e.usage, 'usage', expectedUsage)
                  .having(
                    (e) => e.message,
                    'message',
                    'Cannot negate option "no-publishable".',
                  ),
            ),
          );
        });
      });
    });
  });
}
