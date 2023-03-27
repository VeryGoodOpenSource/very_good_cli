import 'package:very_good_cli/src/commands/create/commands/create_subcommand.dart';
import 'package:very_good_cli/src/commands/create/templates/templates.dart';

/// {@template very_good_create_flutter_app_command}
/// A [CreateSubCommand] for creating Flutter apps.
/// {@endtemplate}
class CreateFlutterApp extends CreateSubCommand with OrgName, MultiTemplates {
  /// {@macro very_good_create_flutter_app_command}
  CreateFlutterApp({
    required super.analytics,
    required super.logger,
    required super.generatorFromBundle,
    required super.generatorFromBrick,
  }) {
    argParser.addOption(
      'application-id',
      help: 'The bundle identifier on iOS or application id on Android. '
          '(defaults to <org-name>.<project-name>)',
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

    return vars;
  }

  @override
  final List<Template> templates = [
    VeryGoodCoreTemplate(),
    VeryGoodWearAppTemplate(),
  ];
}
