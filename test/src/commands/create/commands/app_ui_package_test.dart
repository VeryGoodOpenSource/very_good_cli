import 'dart:io';

import 'package:args/args.dart';
import 'package:mason/mason.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:very_good_cli/src/commands/commands.dart';

import '../../../../helpers/helpers.dart';

class _MockLogger extends Mock implements Logger {}

class _MockProgress extends Mock implements Progress {}

class _MockMasonGenerator extends Mock implements MasonGenerator {}

class _MockGeneratorHooks extends Mock implements GeneratorHooks {}

class _MockArgResults extends Mock implements ArgResults {}

class _FakeLogger extends Fake implements Logger {}

class _FakeDirectoryGeneratorTarget extends Fake
    implements DirectoryGeneratorTarget {}

final expectedUsage = [
  '''
Generate a Very Good App UI package.

Usage: very_good create app_ui_package <project-name> [arguments]
-h, --help                Print this usage information.
-o, --output-directory    The desired output directory when creating a new project.
    --description         The description for this new project.
                          (defaults to "A Very Good Project created by Very Good CLI.")
    --publishable         Whether the generated project is intended to be published.

Run "very_good help" to see global options.''',
];

const pubspec = '''
name: example
environment:
  sdk: ^3.11.0
''';

void main() {
  late Logger logger;

  setUpAll(() {
    registerFallbackValue(_FakeDirectoryGeneratorTarget());
    registerFallbackValue(_FakeLogger());
  });

  setUp(() {
    logger = _MockLogger();

    final progress = _MockProgress();

    when(() => logger.progress(any())).thenReturn(progress);
  });

  group('can be instantiated', () {
    test('with default options', () {
      final logger = Logger();
      final command = CreateAppUiPackage(
        logger: logger,
        generatorFromBundle: null,
        generatorFromBrick: null,
      );
      expect(command.name, equals('app_ui_package'));
      expect(
        command.description,
        equals('Generate a Very Good App UI package.'),
      );
      expect(command.logger, equals(logger));
      expect(command, isA<Publishable>());
    });
  });

  group('create app_ui_package', () {
    test(
      'help',
      withRunner((commandRunner, logger, pubUpdater, printLogs) async {
        final result = await commandRunner.run([
          'create',
          'app_ui_package',
          '--help',
        ]);
        expect(printLogs, equals(expectedUsage));
        expect(result, equals(ExitCode.success.code));

        printLogs.clear();

        final resultAbbr = await commandRunner.run([
          'create',
          'app_ui_pkg',
          '-h',
        ]);
        expect(printLogs, equals(expectedUsage));
        expect(resultAbbr, equals(ExitCode.success.code));
      }),
    );

    group('running the command', () {
      final generatedFiles = List.filled(
        10,
        const GeneratedFile.created(path: ''),
      );

      late GeneratorHooks hooks;
      late MasonGenerator generator;

      setUp(() {
        hooks = _MockGeneratorHooks();
        generator = _MockMasonGenerator();

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
        ).thenAnswer((invocation) async {
          final target =
              invocation.positionalArguments.first as DirectoryGeneratorTarget;
          File(path.join(target.dir.path, 'pubspec.yaml'))
            ..createSync(recursive: true)
            ..writeAsStringSync(pubspec);
          return generatedFiles;
        });
      });

      test('creates app ui package', () async {
        final tempDirectory = Directory.systemTemp.createTempSync();
        addTearDown(() => tempDirectory.deleteSync(recursive: true));

        final argResults = _MockArgResults();
        final command = CreateAppUiPackage(
          logger: logger,
          generatorFromBundle: (_) async => throw Exception('oops'),
          generatorFromBrick: (_) async => generator,
        )..argResultOverrides = argResults;
        when(
          () => argResults['output-directory'] as String?,
        ).thenReturn(tempDirectory.path);
        when(() => argResults.rest).thenReturn(['my_app_ui']);

        final result = await command.run();

        expect(command.template.name, 'app_ui');
        expect(result, equals(ExitCode.success.code));

        verify(() => logger.progress('Bootstrapping')).called(1);
        verify(
          () => hooks.preGen(
            vars: <String, dynamic>{
              'project_name': 'my_app_ui',
              'description': '',
              'publishable': false,
            },
            onVarsChanged: any(named: 'onVarsChanged'),
          ),
        );
        verify(
          () => generator.generate(
            any(),
            vars: <String, dynamic>{
              'project_name': 'my_app_ui',
              'description': '',
              'publishable': false,
            },
            logger: logger,
          ),
        ).called(1);
        verify(
          () => logger.info('Created a Very Good App UI Package! 🦄'),
        ).called(1);
      });
    });
  });
}
