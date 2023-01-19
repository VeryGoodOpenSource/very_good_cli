import 'package:mason_logger/mason_logger.dart';
import 'package:usage/usage.dart';
import 'package:very_good_cli/src/commands/commands.dart';
import 'package:very_good_cli/src/commands/create/templates/templates.dart';

/// {@template very_good_create_docs_site}
/// A [CreateSubCommand] for creating Dart command line interfaces.
/// {@endtemplate}
class CreateDocsSite extends CreateSubCommand {
  /// {@macro very_good_create_docs_site}
  CreateDocsSite({
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
      'org-name',
      help: 'The organization for this new project.',
      defaultsTo: _defaultOrgName,
      aliases: ['org'],
    );
  }

  static const _defaultOrgName = 'my-org';

  @override
  String get name => 'docs_site';

  @override
  String get description => 'Generate a Very Good documentation site.';

  @override
  Map<String, dynamic> getTemplateVars() {
    return <String, dynamic>{
      ...super.getTemplateVars(),
      'org_name': argResults['org-name'],
    };
  }

  @override
  Template get template => VeryGoodDocsSiteTemplate();
}
