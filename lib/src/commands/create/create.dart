import 'dart:async';

import 'package:mason/mason.dart';
import 'package:usage/usage_io.dart';
import 'package:very_good_cli/src/commands/create/commands/flutter_app.dart';
import 'package:very_good_cli/src/commands/create/create_subcommand.dart';
import 'package:very_good_cli/src/commands/create/templates/templates.dart';

/// A method which returns a [Future<MasonGenerator>] given a [MasonBundle].
typedef MasonGeneratorFromBundle = Future<MasonGenerator> Function(MasonBundle);

/// A method which returns a [Future<MasonGenerator>] given a [Brick].
typedef MasonGeneratorFromBrick = Future<MasonGenerator> Function(Brick);

/// {@template create_command}
/// `very_good create` command creates code from various built-in templates.
/// {@endtemplate}
class CreateCommand extends _CreateCommandLegacy {
  /// {@macro create_command}
  CreateCommand({
    required Analytics analytics,
    required Logger logger,
    MasonGeneratorFromBundle? generatorFromBundle,
    MasonGeneratorFromBrick? generatorFromBrick,
  }) : super(
          analytics: analytics,
          logger: logger,
          generatorFromBundle: generatorFromBundle,
          generatorFromBrick: generatorFromBrick,
        ) {
    addSubcommand(
      CreateFlutterApp(
        analytics: analytics,
        logger: logger,
        generatorFromBundle: generatorFromBundle,
        generatorFromBrick: generatorFromBrick,
      ),
    );
  }

  @override
  String get description =>
      'Creates a new very good project in the specified directory.';

  @override
  String get name => 'create';

  @override
  String get invocation => 'very_good create <subcommand> [arguments]';
}

abstract class _CreateCommandLegacy extends CreateSubCommand with OrgName, MultiTemplates {
  _CreateCommandLegacy({
    required Analytics analytics,
    required Logger logger,
    MasonGeneratorFromBundle? generatorFromBundle,
    MasonGeneratorFromBrick? generatorFromBrick,
  }) : super(
          analytics: analytics,
          logger: logger,
          generatorFromBundle: generatorFromBundle,
          generatorFromBrick: generatorFromBrick,
          hideOptions: true,
        ) {
    argParser
      ..addOption(
        'executable-name',
        help: 'Used by the dart_cli template, the CLI executable name '
            '(defaults to the project name)',
        hide: true,
      )
      ..addOption(
        'android',
        help: 'The plugin supports the Android platform.',
        defaultsTo: 'true',
        hide: true,
      )
      ..addOption(
        'ios',
        help: 'The plugin supports the iOS platform.',
        defaultsTo: 'true',
        hide: true,
      )
      ..addOption(
        'web',
        help: 'The plugin supports the Web platform.',
        defaultsTo: 'true',
        hide: true,
      )
      ..addOption(
        'linux',
        help: 'The plugin supports the Linux platform.',
        defaultsTo: 'true',
        hide: true,
      )
      ..addOption(
        'macos',
        help: 'The plugin supports the macOS platform.',
        defaultsTo: 'true',
        hide: true,
      )
      ..addOption(
        'windows',
        help: 'The plugin supports the Windows platform.',
        defaultsTo: 'true',
        hide: true,
      )
      ..addOption(
        'application-id',
        help: 'The bundle identifier on iOS or application id on Android. '
            '(defaults to <org-name>.<project-name>)',
        hide: true,
      )
      ..addFlag(
        'publishable',
        negatable: false,
        help: 'Whether the generated project is intended to be published '
            '(Does not affect flutter application templates)',
        hide: true,
      );
  }

  @override
  String get defaultTemplateName => 'core';


  @override
  List<Template> get templates => [
    VeryGoodCoreTemplate(),
    DartPkgTemplate(),
    FlutterPkgTemplate(),
    FlutterPluginTemplate(),
    VeryGoodDartCLITemplate(),
    VeryGoodDocsSiteTemplate(),
    VeryGoodFlameGameTemplate(),
  ];

  @override
  Map<String, dynamic> getTemplateVars() {
    final vars = super.getTemplateVars();

    final applicationId = argResults['application-id'] as String?;

    final android = argResults['android'] as String? ?? 'true';
    final ios = argResults['ios'] as String? ?? 'true';
    final web = argResults['web'] as String? ?? 'true';
    final linux = argResults['linux'] as String? ?? 'true';
    final macos = argResults['macos'] as String? ?? 'true';
    final windows = argResults['windows'] as String? ?? 'true';

    final executableName =
        argResults['executable-name'] as String? ?? projectName;

    return <String, dynamic>{
      ...vars,
      'executable_name': executableName,
      if (applicationId != null) 'application_id': applicationId,
      'platforms': <String>[
        if (android.toBool()) 'android',
        if (ios.toBool()) 'ios',
        if (web.toBool()) 'web',
        if (linux.toBool()) 'linux',
        if (macos.toBool()) 'macos',
        if (windows.toBool()) 'windows',
      ],
    };
  }

}

extension on String {
  bool toBool() => toLowerCase() == 'true';
}
