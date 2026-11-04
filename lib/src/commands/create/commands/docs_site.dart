import 'package:very_good_cli/src/commands/commands.dart';
import 'package:very_good_cli/src/commands/create/templates/templates.dart';
import 'package:very_good_cli/src/very_good_config/very_good_config.dart';

/// {@template very_good_create_docs_site}
/// A [CreateSubCommand] for creating Dart command line interfaces.
/// {@endtemplate}
class CreateDocsSite({
  required super.logger,
  required super.generatorFromBundle,
}) extends CreateSubCommand with Publishable {
  /// {@macro very_good_create_docs_site}
  this {
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
  TemplateVarResolvers get templateVarResolvers => {
    ...super.templateVarResolvers,
    'org_name': () => argResults.resolve<String>(
      'org-name',
      createConfig.orgName,
      fallbackValue: _defaultOrgName,
    ),
  };

  @override
  Template get template => VeryGoodDocsSiteTemplate();
}
