import 'package:very_good_cli/src/commands/commands.dart';
import 'package:very_good_cli/src/commands/create/templates/templates.dart';

/// {@template very_good_create_docs_site}
/// A [CreateSubCommand] for creating Dart command line interfaces.
/// {@endtemplate}
class CreateDocsSite({
  required super.logger,
  required super.generatorFromBundle,
}) extends CreateSubCommand with Publishable, FreeFormOrgName {
  /// {@macro very_good_create_docs_site}
  this;

  @override
  String get defaultOrgName => 'my-org';

  @override
  String get name => 'docs_site';

  @override
  String get description => 'Generate a Very Good documentation site.';

  @override
  Template get template => VeryGoodDocsSiteTemplate();
}
