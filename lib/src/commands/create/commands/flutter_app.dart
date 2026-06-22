import 'package:very_good_cli/src/commands/create/commands/create_subcommand.dart';
import 'package:very_good_cli/src/commands/create/templates/templates.dart';

/// {@template very_good_create_flutter_app_command}
/// A [CreateSubCommand] for creating Flutter apps.
/// {@endtemplate}
class CreateFlutterApp extends CreateSubCommand
    with OrgName, MultiTemplates, Publishable {
  /// {@macro very_good_create_flutter_app_command}
  CreateFlutterApp({
    required super.logger,
    required super.generatorFromBundle,
    required super.generatorFromBrick,
  }) {
    argParser
      ..addOption(
        'application-id',
        help:
            'The bundle identifier on iOS or application id on Android. '
            '(defaults to <org-name>.<project-name>)',
      )
      ..addMultiOption(
        'platforms',
        help:
            'The platforms supported by the app. By default, all platforms '
            'are enabled. Example: --platforms=android,ios',
        defaultsTo: ['android', 'ios', 'macos', 'web', 'windows'],
        allowed: ['android', 'ios', 'macos', 'web', 'windows'],
        allowedHelp: {
          'android': 'The app supports the Android platform.',
          'ios': 'The app supports the iOS platform.',
          'macos': 'The app supports the macOS platform.',
          'web': 'The app supports the Web platform.',
          'windows': 'The app supports the Windows platform.',
        },
      );
  }

  @override
  String get name => 'flutter_app';

  @override
  String get description => 'Generate a Very Good Flutter application.';

  @override
  Map<String, dynamic> getTemplateVars() {
    final vars = super.getTemplateVars();

    final applicationId = argResults['application-id'] as String?;
    if (applicationId != null) {
      vars['application_id'] = applicationId;
    }

    final platforms = argResults['platforms'] as List<String>;
    vars['platforms'] = platforms;

    return vars;
  }

  @override
  final List<Template> templates = [VeryGoodCoreTemplate()];
}
