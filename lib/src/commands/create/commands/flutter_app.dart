import 'package:mason/mason.dart';
import 'package:usage/usage.dart';
import 'package:very_good_cli/src/commands/create/commands/create_subcommand.dart';
import 'package:very_good_cli/src/commands/create/templates/templates.dart';

/// {@template very_good_create_flutter_app_command}
/// A [CreateSubCommand] for creating Flutter apps.
/// {@endtemplate}
class CreateFlutterApp extends CreateSubCommand with OrgName {
  /// {@macro very_good_create_flutter_app_command}
  CreateFlutterApp({
    required Analytics analytics,
    required Logger logger,
    required MasonGeneratorFromBundle? generatorFromBundle,
    required MasonGeneratorFromBrick? generatorFromBrick,
  }) : super(
          analytics: analytics,
          logger: logger,
          generatorFromBundle: generatorFromBundle,
          generatorFromBrick: generatorFromBrick,
        ) {
    argParser.addOption(
      'application-id',
      help: 'The bundle identifier on iOS or application id on Android. '
          '(defaults to <org-name>.<project-name>)',
    );
  }

  @override
  String get name => 'flutter_app';

  @override
  String get description =>
      'Creates a new very good Flutter app in the specified directory.';

  @override
  Template get template => VeryGoodCoreTemplate();

  @override
  Map<String, dynamic> getTemplateVars() {
    final vars = super.getTemplateVars();

    final applicationId = argResults['application-id'] as String?;
    if (applicationId != null) {
      vars['application_id'] = applicationId;
    }

    return vars;
  }
}
