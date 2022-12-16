import 'package:args/command_runner.dart';
import 'package:mason/mason.dart';
import 'package:usage/usage_io.dart';
import 'package:very_good_cli/src/commands/create/commands/flutter_app.dart';
import 'package:very_good_cli/src/commands/create/create_legacy.dart';
import 'package:very_good_cli/src/commands/create/create_subcommand.dart';

/// {@template create_command}
/// `very_good create` command creates code from various built-in templates.
/// {@endtemplate}
class CreateCommand extends Command<int> {
  /// {@macro create_command}
  CreateCommand({
    required Analytics analytics,
    required Logger logger,
    MasonGeneratorFromBundle? generatorFromBundle,
    MasonGeneratorFromBrick? generatorFromBrick,
  }) {
    addSubcommand(
      LegacyCreateCommand(
        analytics: analytics,
        logger: logger,
        generatorFromBundle: generatorFromBundle,
        generatorFromBrick: generatorFromBrick,
      ),
    );
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
