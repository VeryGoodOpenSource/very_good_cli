import 'dart:io';

import 'package:args/args.dart';
import 'package:mason/mason.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:usage/usage.dart';
import 'package:very_good_cli/src/commands/create/commands/flutter_app.dart';

import '../../../../helpers/helpers.dart';

class MockAnalytics extends Mock implements Analytics {}

class MockLogger extends Mock implements Logger {}

class MockMasonGenerator extends Mock implements MasonGenerator {}

class MockGeneratorHooks extends Mock implements GeneratorHooks {}

class MockArgResults extends Mock implements ArgResults {}

class FakeLogger extends Fake implements Logger {}

class FakeDirectoryGeneratorTarget extends Fake
    implements DirectoryGeneratorTarget {}

final expectedUsage = [
  '''
Creates a new very good Flutter app in the specified directory.

Usage: very_good create flutter_app <project-name> [arguments]
-h, --help                Print this usage information.
-o, --output-directory    The desired output directory when creating a new project.
    --description         The description for this new project.
                          (defaults to "A Very Good Project created by Very Good CLI.")
    --org-name            The organization for this new project.
                          (defaults to "com.example.verygoodcore")
    --application-id      The bundle identifier on iOS or application id on Android. (defaults to <org-name>.<project-name>)

Run "very_good help" to see global options.''',
];

const pubspec = '''
name: example
environment:
  sdk: ">=2.13.0 <3.0.0"
''';

void main() {
  late List<String> progressLogs;
  late Analytics analytics;
  late Logger logger;

  setUpAll(() {
    registerFallbackValue(FakeDirectoryGeneratorTarget());
    registerFallbackValue(FakeLogger());
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

    final progress = MockProgress();
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
        analytics: analytics,
        logger: logger,
        generatorFromBundle: null,
        generatorFromBrick: null,
      );
      expect(command.name, equals('flutter_app'));
      expect(
        command.description,
        equals(
          'Creates a new very good Flutter app in the specified directory.',
        ),
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
      final generatedFiles =
          List.filled(10, const GeneratedFile.created(path: ''));

      late GeneratorHooks hooks;
      late MasonGenerator generator;

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
          final target =
              _.positionalArguments.first as DirectoryGeneratorTarget;
          File(path.join(target.dir.path, 'my_app', 'pubspec.yaml'))
            ..createSync(recursive: true)
            ..writeAsStringSync(pubspec);
          return generatedFiles;
        });
      });

      test('create core app', () async {
        final tempDir = Directory.systemTemp.createTempSync();
        addTearDown(() => tempDir.deleteSync(recursive: true));
        final argResults = MockArgResults();
        final command = CreateFlutterApp(
          analytics: analytics,
          logger: logger,
          generatorFromBundle: (_) async => throw Exception('oops'),
          generatorFromBrick: (_) async => generator,
        )..argResultOverrides = argResults;
        when(() => argResults['output-directory'] as String?)
            .thenReturn(tempDir.path);
        when(() => argResults.rest).thenReturn(['my_app']);
        when(() => argResults['application-id'] as String?).thenReturn(
          'xyz.app.my_app',
        );

        final result = await command.run();

        expect(command.template.name, 'core');
        expect(result, equals(ExitCode.success.code));

        verify(() => logger.progress('Bootstrapping')).called(1);
        verify(
          () => hooks.preGen(
            vars: <String, dynamic>{
              'project_name': 'my_app',
              'description': '',
              'org_name': 'com.example.verygoodcore',
              'application_id': 'xyz.app.my_app',
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
              'application_id': 'xyz.app.my_app',
            },
            logger: logger,
          ),
        ).called(1);
        expect(
          progressLogs,
          equals(['Generated ${generatedFiles.length} file(s)']),
        );
        verify(
          () => logger.info('Created a Very Good App! 🦄'),
        ).called(1);
      });
    });
  });
}
