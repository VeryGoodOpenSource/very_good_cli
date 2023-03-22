import 'package:args/command_runner.dart';
import 'package:mason/mason.dart';
import 'package:usage/usage_io.dart';
import 'package:very_good_cli/src/commands/create/commands/commands.dart';

/// {@template create_command}
/// `very_good create` command creates code from various built-in templates.
/// {@endtemplate}
///
/// See also:
/// - [CreateSubCommand] for the base class for all create subcommands.
class CreateCommand extends Command<int> {
  /// {@macro create_command}
  CreateCommand({
    required Analytics analytics,
    required Logger logger,
    MasonGeneratorFromBundle? generatorFromBundle,
    MasonGeneratorFromBrick? generatorFromBrick,
  }) {
    // very_good create flutter_app <args>
    addSubcommand(
      CreateFlutterApp(
        analytics: analytics,
        logger: logger,
        generatorFromBundle: generatorFromBundle,
        generatorFromBrick: generatorFromBrick,
      ),
    );

    // very_good create dart_package <args>
    addSubcommand(
      CreateDartPackage(
        analytics: analytics,
        logger: logger,
        generatorFromBundle: generatorFromBundle,
        generatorFromBrick: generatorFromBrick,
      ),
    );

    // very_good create dart_cli <args>
    addSubcommand(
      CreateDartCLI(
        analytics: analytics,
        logger: logger,
        generatorFromBundle: generatorFromBundle,
        generatorFromBrick: generatorFromBrick,
      ),
    );

    // very_good create docs_site <args>
    addSubcommand(
      CreateDocsSite(
        analytics: analytics,
        logger: logger,
        generatorFromBundle: generatorFromBundle,
        generatorFromBrick: generatorFromBrick,
      ),
    );

    // very_good create flutter_package <args>
    addSubcommand(
      CreateFlutterPackage(
        analytics: analytics,
        logger: logger,
        generatorFromBundle: generatorFromBundle,
        generatorFromBrick: generatorFromBrick,
      ),
    );

    // very_good create flutter_plugin <args>
    addSubcommand(
      CreateFlutterPlugin(
        analytics: analytics,
        logger: logger,
        generatorFromBundle: generatorFromBundle,
        generatorFromBrick: generatorFromBrick,
      ),
    );

    // very_good create flame_game <args>
    addSubcommand(
      CreateFlameGame(
        analytics: analytics,
        logger: logger,
        generatorFromBundle: generatorFromBundle,
        generatorFromBrick: generatorFromBrick,
      ),
    );
  }

  @override
  String get summary => '$invocation\n$description';

  @override
  String get description =>
      'Creates a new very good project in the specified directory.';

  @override
  String get name => 'create';

  @override
  String get invocation =>
      'very_good create <subcommand> <project-name> [arguments]';
}
