// ignore_for_file: public_member_api_docs

import 'package:mason/mason.dart';
import 'package:usage/usage.dart';
import 'package:very_good_cli/src/commands/create/create_subcommand.dart';
import 'package:very_good_cli/src/commands/create/templates/templates.dart';

class CreateFlutterApp extends CreateSubCommand with OrgName {
  CreateFlutterApp({
    required Analytics analytics,
    required Logger logger,
    MasonGeneratorFromBundle? generatorFromBundle,
    MasonGeneratorFromBrick? generatorFromBrick,
    this.fakename,
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

  String? fakename;

  @override
  String get name => fakename ?? 'flutter_app';

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
