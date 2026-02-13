// Expected usage of the game will need to be adjacent strings due to format.
// ignore_for_file: lines_longer_than_80_chars, no_adjacent_strings_in_list

import 'dart:io';

import 'package:args/args.dart';
import 'package:mason/mason.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:very_good_cli/src/commands/commands.dart';
import 'package:very_good_cli/src/commands/create/commands/flame_game.dart';

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
  'Generate a Very Good Flame game.\n'
      '\n'
      'Usage: very_good create flame_game <project-name> [arguments]\n'
      '-h, --help                       Print this usage information.\n'
      '-o, --output-directory           The desired output directory when creating a new project.\n'
      '    --description                The description for this new project.\n'
      '                                 (defaults to "A Very Good Project created by Very Good CLI.")\n'
      '    --org-name                   The organization for this new project.\n'
      '                                 (defaults to "com.example.verygoodcore")\n'
      '    --platforms                  The platforms supported by the game. By default, all platforms are enabled. Example: --platforms=android,ios\n'
      '\n'
      '          [android] (default)    The game supports the Android platform.\n'
      '          [ios] (default)        The game supports the iOS platform.\n'
      '          [web] (default)        The game supports the Web platform.\n'
      '          [macos] (default)      The game supports the macOS platform.\n'
      '          [windows] (default)    The game supports the Windows platform.\n'
      '\n'
      'Run "very_good help" to see global options.',
];

const pubspec = '''
name: example
environment:
  sdk: ^3.11.0
''';

void main() {
  late List<String> progressLogs;
  late Logger logger;

  setUpAll(() {
    registerFallbackValue(_FakeDirectoryGeneratorTarget());
    registerFallbackValue(_FakeLogger());
  });

  setUp(() {
    progressLogs = <String>[];
    logger = _MockLogger();

    final progress = _MockProgress();
    when(() => progress.complete(any())).thenAnswer((invocation) {
      final message = invocation.positionalArguments.first as String?;
      if (message != null) progressLogs.add(message);
    });
    when(() => logger.progress(any())).thenReturn(progress);
  });

  group('can be instantiated', () {
    test('with default options', () {
      final logger = Logger();
      final command = CreateFlameGame(
        logger: logger,
        generatorFromBundle: null,
        generatorFromBrick: null,
      );
      expect(command.name, equals('flame_game'));
      expect(command.description, equals('Generate a Very Good Flame game.'));
      expect(command.logger, equals(logger));
    });
  });

  group('create flame_game', () {
    test(
      'help',
      withRunner((commandRunner, logger, pubUpdater, printLogs) async {
        final result = await commandRunner.run([
          'create',
          'flame_game',
          '--help',
        ]);
        expect(printLogs, equals(expectedUsage));
        expect(result, equals(ExitCode.success.code));

        printLogs.clear();

        final resultAbbr = await commandRunner.run([
          'create',
          'flame_game',
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
        ).thenAnswer((_) async => generatedFiles);

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

      test('create flame game', () async {
        final tempDirectory = Directory.systemTemp.createTempSync();
        addTearDown(() => tempDirectory.deleteSync(recursive: true));

        final argResults = _MockArgResults();
        final command = CreateFlameGame(
          logger: logger,
          generatorFromBundle: (_) async => throw Exception('oops'),
          generatorFromBrick: (_) async => generator,
        )..argResultOverrides = argResults;
        when(
          () => argResults['output-directory'] as String?,
        ).thenReturn(tempDirectory.path);
        when(() => argResults.rest).thenReturn(['my_app']);
        when(
          () => argResults['application-id'] as String?,
        ).thenReturn('xyz.app.my_app');
        when(
          () => argResults['platforms'] as List<String>,
        ).thenReturn(['android', 'ios', 'web', 'macos', 'windows']);

        final result = await command.run();

        expect(command.template.name, 'flame_game');
        expect(result, equals(ExitCode.success.code));

        verify(() => logger.progress('Bootstrapping')).called(1);
        verify(
          () => hooks.preGen(
            vars: <String, dynamic>{
              'project_name': 'my_app',
              'description': '',
              'org_name': 'com.example.verygoodcore',
              'platforms': ['android', 'ios', 'web', 'macos', 'windows'],
            },
            onVarsChanged: any(named: 'onVarsChanged'),
          ),
        );
        verify(
          () => generator.generate(
            any(),
            vars: <String, dynamic>{
              'project_name': 'my_app',
              'description': '',
              'org_name': 'com.example.verygoodcore',
              'platforms': ['android', 'ios', 'web', 'macos', 'windows'],
            },
            logger: logger,
          ),
        ).called(1);
        expect(
          progressLogs,
          equals(['Generated ${generatedFiles.length} file(s)']),
        );
        verify(
          () => logger.info('Created a Very Good Game powered by Flame! 🔥🦄'),
        ).called(1);
      });
    });
  });
}
