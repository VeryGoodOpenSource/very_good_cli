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
Generate a Very Good Dart CLI application.

Usage: very_good create dart_cli <project-name> [arguments]
-h, --help                Print this usage information.
-o, --output-directory    The desired output directory when creating a new project.
    --description         The description for this new project.
                          (defaults to "A Very Good Project created by Very Good CLI.")
    --publishable         Whether the generated project is intended to be published.
    --executable-name     The CLI executable name (defaults to the project name)

Run "very_good help" to see global options.''',
];

const pubspec = '''
name: example
environment:
  sdk: ">=2.13.0 <3.0.0"
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
      final command = CreateDartCLI(
        logger: logger,
        generatorFromBundle: null,
        generatorFromBrick: null,
      );
      expect(command.name, equals('dart_cli'));
      expect(
        command.description,
        equals('Generate a Very Good Dart CLI application.'),
      );
      expect(command.logger, equals(logger));
      expect(command, isA<Publishable>());
      expect(command.argParser.options, contains('executable-name'));
    });
  });

  group('create dart_cli', () {
    test(
      'help',
      withRunner((commandRunner, logger, pubUpdater, printLogs) async {
        final result =
            await commandRunner.run(['create', 'dart_cli', '--help']);
        expect(printLogs, equals(expectedUsage));
        expect(result, equals(ExitCode.success.code));

        printLogs.clear();

        final resultAbbr =
            await commandRunner.run(['create', 'dart_cli', '-h']);
        expect(printLogs, equals(expectedUsage));
        expect(resultAbbr, equals(ExitCode.success.code));
      }),
    );

    group('running the command', () {
      final generatedFiles =
          List.filled(10, const GeneratedFile.created(path: ''));

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
        ).thenAnswer((_) async {
          final target =
              _.positionalArguments.first as DirectoryGeneratorTarget;
          File(path.join(target.dir.path, 'my_cli', 'pubspec.yaml'))
            ..createSync(recursive: true)
            ..writeAsStringSync(pubspec);
          return generatedFiles;
        });
      });

      test('creates dart package', () async {
        final tempDirectory = Directory.systemTemp.createTempSync();
        addTearDown(() => tempDirectory.deleteSync(recursive: true));

        final argResults = _MockArgResults();
        final command = CreateDartCLI(
          logger: logger,
          generatorFromBundle: (_) async => throw Exception('oops'),
          generatorFromBrick: (_) async => generator,
        )..argResultOverrides = argResults;
        when(() => argResults['output-directory'] as String?)
            .thenReturn(tempDirectory.path);
        when(() => argResults.rest).thenReturn(['my_cli']);
        when(() => argResults['executable-name'] as String?).thenReturn(
          'my_executable',
        );

        final result = await command.run();

        expect(command.template.name, 'dart_cli');
        expect(result, equals(ExitCode.success.code));

        verify(() => logger.progress('Bootstrapping')).called(1);
        verify(
          () => hooks.preGen(
            vars: <String, dynamic>{
              'project_name': 'my_cli',
              'description': '',
              'publishable': false,
              'executable_name': 'my_executable',
            },
            onVarsChanged: any(named: 'onVarsChanged'),
          ),
        );
        verify(
          () => generator.generate(
            any(),
            vars: <String, dynamic>{
              'project_name': 'my_cli',
              'description': '',
              'publishable': false,
              'executable_name': 'my_executable',
            },
            logger: logger,
          ),
        ).called(1);
        verify(
          () => logger.info('Created a Very Good Dart CLI application! 🦄'),
        ).called(1);
      });
    });
  });
}
