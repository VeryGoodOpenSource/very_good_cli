import 'package:mason_logger/mason_logger.dart';
import 'package:usage/usage.dart';
import 'package:very_good_cli/src/commands/create/commands/commands.dart';
import 'package:very_good_cli/src/commands/create/templates/templates.dart';

/// {@template very_good_create_dart_cli_command}
/// A [CreateSubCommand] for creating Dart command line interfaces.
/// {@endtemplate}
class CreateDartCLI extends CreateSubCommand with Publishable {
  /// {@macro very_good_create_dart_cli_command}
  CreateDartCLI({
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
      'executable-name',
      help: 'The CLI executable name (defaults to the project name)',
    );
  }

  @override
  String get name => 'dart_cli';

  @override
  String get description =>
      'Creates a new very good Dart CLI in the specified directory.';

  @override
  Template get template => VeryGoodDartCLITemplate();

  @override
  Map<String, dynamic> getTemplateVars() {
    final vars = super.getTemplateVars();

    final executableName =
        argResults['executable-name'] as String? ?? projectName;

    vars['executable_name'] = executableName;

    return vars;
  }
}
