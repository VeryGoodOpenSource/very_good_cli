import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:universal_io/io.dart';

import '../../../helpers/helpers.dart';

final expectedUsage = [
  '''
Creates a new very good project in the specified directory.

Usage: very_good create <subcommand> [arguments]
-h, --help    Print this usage information.

Available subcommands:
  flutter_app   Creates a new very good Flutter app in the specified directory.

Run "very_good help" to see global options.'''
];

void main() {
  group('create', () {
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

    group('route legacy syntax to "create legacy"', () {
      test(
        'Allows the creation of projects in the legacy syntax',
        withRunner((commandRunner, logger, pubUpdater, printLogs) async {
          final tempDir = Directory.systemTemp.createTempSync();
          addTearDown(() => tempDir.deleteSync(recursive: true));

          final result = await commandRunner.run([
            'create',
            'legacy_project',
            '-o',
            tempDir.path,
            '--template',
            'dart_pkg',
          ]);

          expect(result, equals(ExitCode.success.code));

          verify(
            () => logger.info('Created a Very Good Dart Package! 🦄'),
          ).called(1);
        }),
      );
      test(
        'Shows legacy usage when invalid legacy options is passed',
        withRunner((commandRunner, logger, pubUpdater, printLogs) async {
          final tempDir = Directory.systemTemp.createTempSync();
          addTearDown(() => tempDir.deleteSync(recursive: true));

          final result = await commandRunner.run([
            'create',
            'legacy_project',
            '-o',
            tempDir.path,
            '--template',
            'wrong_template',
          ]);

          expect(result, equals(ExitCode.usage.code));

          verify(
            () => logger.err(
              '"wrong_template" is not an allowed value for '
              'option "template".',
            ),
          ).called(1);

          verify(
            () => logger.info(
              '''
Usage: Deprecated usage of the create command: run 'very_good create --help' to see the available options.
-h, --help                    Print this usage information.
-o, --output-directory        The desired output directory when creating a new project.
    --desc                    The description for this new project.
                              (defaults to "A Very Good Project created by Very Good CLI.")
-t, --template                The template used to generate this new project.

          [core] (default)    Generate a Very Good Flutter application.
          [dart_cli]          Generate a Very Good Dart CLI application.
          [dart_pkg]          Generate a reusable Dart package.
          [docs_site]         Generate a Very Good documentation site.
          [flame_game]        Generate a Very Good Flame game.
          [flutter_pkg]       Generate a reusable Flutter package.
          [flutter_plugin]    Generate a reusable Flutter plugin.

    --org-name                The organization for this new project.
                              (defaults to "com.example.verygoodcore")
    --executable-name         Used by the dart_cli template, the CLI executable name (defaults to the project name)
    --android                 The plugin supports the Android platform.
                              (defaults to "true")
    --ios                     The plugin supports the iOS platform.
                              (defaults to "true")
    --web                     The plugin supports the Web platform.
                              (defaults to "true")
    --linux                   The plugin supports the Linux platform.
                              (defaults to "true")
    --macos                   The plugin supports the macOS platform.
                              (defaults to "true")
    --windows                 The plugin supports the Windows platform.
                              (defaults to "true")
    --application-id          The bundle identifier on iOS or application id on Android. (defaults to <org-name>.<project-name>)
    --publishable             Whether the generated project is intended to be published (Does not affect flutter application templates)

Run "very_good help" to see global options.''',
            ),
          ).called(1);
        }),
      );
    });
  });
}
