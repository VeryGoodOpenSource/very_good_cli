import 'dart:io';

import 'package:mason/mason.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:very_good_cli/src/commands/commands.dart';
import 'package:very_good_cli/src/commands/create/commands/flutter_app.dart';

import '../../../../helpers/helpers.dart';

class _MockLogger extends Mock implements Logger {}

class _MockProgress extends Mock implements Progress {}

class _MockMasonGenerator extends Mock implements MasonGenerator {}

class _MockGeneratorHooks extends Mock implements GeneratorHooks {}

class _FakeLogger extends Fake implements Logger {}

class _FakeDirectoryGeneratorTarget extends Fake
    implements DirectoryGeneratorTarget {}

final expectedUsage = [
  '''
Generate a Very Good Flutter application.

Usage: very_good create flutter_app <project-name> [arguments]
-h, --help                    Print this usage information.
-o, --output-directory        The desired output directory when creating a new project.
    --description             The description for this new project.
                              (defaults to "A Very Good Project created by Very Good CLI.")
-t, --template                The template used to generate this new project.

          [core] (default)    Generate a Very Good Flutter application.
          [wear]              Generate a Very Good Flutter Wear OS application.

    --org-name                The organization for this new project.
                              (defaults to "com.example.verygoodcore")
    --application-id          The bundle identifier on iOS or application id on Android. (defaults to <org-name>.<project-name>)

Run "very_good help" to see global options.''',
];

const pubspec = '''
name: example
environment:
  sdk: ">=2.13.0 <3.0.0"
''';

void main() {
  late List<String> progressLogs;
  late Logger logger;

  final generatedFiles = List.filled(10, const GeneratedFile.created(path: ''));

  setUpAll(() {
    registerFallbackValue(_FakeDirectoryGeneratorTarget());
    registerFallbackValue(_FakeLogger());
  });

  setUp(() {
    progressLogs = <String>[];

    logger = _MockLogger();

    final progress = _MockProgress();
    when(() => progress.complete(any())).thenAnswer((_) {
      final message = _.positionalArguments.elementAt(0) as String?;
      if (message != null) progressLogs.add(message);
    });
    when(() => logger.progress(any())).thenReturn(progress);
  });

  group('can be instantiated', () {
    test('with default options', () {
      final logger = Logger();
      final command = CreateFlutterApp(
        logger: logger,
        generatorFromBundle: null,
        generatorFromBrick: null,
      );
      expect(command.name, equals('flutter_app'));
      expect(
        command.description,
        equals('Generate a Very Good Flutter application.'),
      );
      expect(command.logger, equals(logger));
      expect(command.argParser.options, contains('application-id'));
    });
  });

  group('create flutter_app', () {
    test(
      'help',
      withRunner((commandRunner, logger, pubUpdater, printLogs) async {
        final result =
            await commandRunner.run(['create', 'flutter_app', '--help']);
        expect(printLogs, equals(expectedUsage));
        expect(result, equals(ExitCode.success.code));

        printLogs.clear();

        final resultAbbr =
            await commandRunner.run(['create', 'flutter_app', '-h']);
        expect(printLogs, equals(expectedUsage));
        expect(resultAbbr, equals(ExitCode.success.code));
      }),
    );

    group('running the command', () {
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
          File(path.join(target.dir.path, 'my_app', 'pubspec.yaml'))
            ..createSync(recursive: true)
            ..writeAsStringSync(pubspec);
          return generatedFiles;
        });
      });

      group('templates', () {
        group('core', () {
          test('generates successfully', () async {
            await testMultiTemplateCommand(
              multiTemplatesCommand: CreateFlutterApp(
                logger: logger,
                generatorFromBundle: (_) async => throw Exception('oops'),
                generatorFromBrick: (_) async => generator,
              ),
              logger: logger,
              hooks: hooks,
              generator: generator,
              templateName: 'core',
              mockArgs: {'application-id': 'xyz.app.my_app'},
              expectedVars: {
                'project_name': 'my_app',
                'description': '',
                'org_name': 'com.example.verygoodcore',
                'application_id': 'xyz.app.my_app',
              },
              expectedLogSummary: 'Created a Very Good App! 🦄',
            );
          });

          test('logs getting started information', () async {
            final tempDirectory = Directory.systemTemp.createTempSync();
            addTearDown(() => tempDirectory.deleteSync(recursive: true));

            await testMultiTemplateCommand(
              outputDirectoryOverride: tempDirectory,
              multiTemplatesCommand: CreateFlutterApp(
                logger: logger,
                generatorFromBundle: (_) async => throw Exception('oops'),
                generatorFromBrick: (_) async => generator,
              ),
              logger: logger,
              hooks: hooks,
              generator: generator,
              templateName: 'core',
              mockArgs: {'application-id': 'xyz.app.my_app'},
              expectedVars: {
                'project_name': 'my_app',
                'description': '',
                'org_name': 'com.example.verygoodcore',
                'application_id': 'xyz.app.my_app',
              },
              expectedLogSummary: 'Created a Very Good App! 🦄',
            );

            final outputPath = path.join(tempDirectory.path, 'my_app');
            final relativePath =
                path.relative(outputPath, from: Directory.current.path);

            final projectPath = relativePath;
            final projectPathLink =
                link(uri: Uri.parse(projectPath), message: projectPath);

            final readmePath = path.join(relativePath, 'README.md');
            final readmePathLink =
                link(uri: Uri.parse(readmePath), message: readmePath);

            final details = '''
  • To get started refer to $readmePathLink
  • Your project code is in $projectPathLink
''';
            verify(() => logger.info(details)).called(1);
          });
        });

        test('wear', () async {
          await testMultiTemplateCommand(
            multiTemplatesCommand: CreateFlutterApp(
              logger: logger,
              generatorFromBundle: (_) async => throw Exception('oops'),
              generatorFromBrick: (_) async => generator,
            ),
            logger: logger,
            hooks: hooks,
            generator: generator,
            templateName: 'wear',
            mockArgs: {
              'application-id': 'xyz.app.my_wear_app',
            },
            expectedVars: {
              'project_name': 'my_app',
              'description': '',
              'org_name': 'com.example.verygoodcore',
              'application_id': 'xyz.app.my_wear_app',
            },
            expectedLogSummary: 'Created a Very Good Wear OS app! ⌚️🦄',
          );
        });
      });
    });
  });
}
