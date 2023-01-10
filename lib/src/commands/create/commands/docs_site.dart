import 'package:mason_logger/mason_logger.dart';
import 'package:usage/usage.dart';
import 'package:very_good_cli/src/commands/commands.dart';
import 'package:very_good_cli/src/commands/create/templates/templates.dart';

/// {@template very_good_create_docs_site}
/// A [CreateSubCommand] for creating Dart command line interfaces.
/// {@endtemplate}
class CreateDocsSite extends CreateSubCommand with OrgName {
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
        );

  @override
  String get name => 'docs_site';

  @override
  String get description =>
      'Creates a new very good docs site in the specified directory.';

  @override
  Template get template => VeryGoodDocsSiteTemplate();
}
