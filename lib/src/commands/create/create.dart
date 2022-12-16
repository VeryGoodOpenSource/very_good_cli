import 'package:args/command_runner.dart';
import 'package:mason/mason.dart';
import 'package:usage/usage_io.dart';
import 'package:very_good_cli/src/commands/create/commands/flutter_app.dart';
import 'package:very_good_cli/src/commands/create/create_legacy.dart';
import 'package:very_good_cli/src/commands/create/create_subcommand.dart';

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
    // Legacy sub command: hidden sub command that maintains backwards
    // compatibility with the `very_good create <project name>` command syntax.
    // The command runner will call legacy if the suer run the legacy syntax.
    addSubcommand(
      LegacyCreateCommand(
        analytics: analytics,
        logger: logger,
        generatorFromBundle: generatorFromBundle,
        generatorFromBrick: generatorFromBrick,
      ),
    );

    // very_good create flutter_app <args>
    addSubcommand(
      CreateFlutterApp(
        analytics: analytics,
        logger: logger,
        generatorFromBundle: generatorFromBundle,
        generatorFromBrick: generatorFromBrick,
      ),
    );
  }

  @override
  String get description =>
      'Creates a new very good project in the specified directory.';

  @override
  String get name => 'create';

  @override
  String get invocation => 'very_good create <subcommand> [arguments]';
}
