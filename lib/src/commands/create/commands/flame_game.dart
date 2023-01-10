import 'package:mason/mason.dart';
import 'package:usage/usage.dart';
import 'package:very_good_cli/src/commands/create/commands/create_subcommand.dart';
import 'package:very_good_cli/src/commands/create/templates/templates.dart';

/// {@template very_good_create_flame_game_command}
/// A [CreateSubCommand] for creating Flame games.
/// {@endtemplate}
class CreateFlameGame extends CreateSubCommand with OrgName {
  /// {@macro very_good_create_flame_game_command}
  CreateFlameGame({
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
  String get name => 'flame_game';

  @override
  String get description =>
      'Creates a new very good Flame game in the specified directory.';

  @override
  Template get template => VeryGoodFlameGameTemplate();
}
