import 'package:very_good_cli/src/commands/create/commands/commands.dart';
import 'package:very_good_cli/src/commands/create/templates/templates.dart';

/// {@template very_good_create_dart_cli_command}
/// A [CreateSubCommand] for creating Dart command line interfaces.
/// {@endtemplate}
class CreateDartCLI({required super.logger, required super.generatorFromBundle})
    extends CreateSubCommand
    with Publishable, Workspace {
  /// {@macro very_good_create_dart_cli_command}
  this {
    argParser.addOption(
      'executable-name',
      help: 'The CLI executable name (defaults to the project name)',
    );
  }

  @override
  String get name => 'dart_cli';

  @override
  String get description => 'Generate a Very Good Dart CLI application.';

  @override
  Template get template => VeryGoodDartCLITemplate();

  @override
  TemplateVarResolvers get templateVarResolvers => {
    ...super.templateVarResolvers,
    'executable_name': () =>
        argResults['executable-name'] as String? ?? projectName,
  };
}
