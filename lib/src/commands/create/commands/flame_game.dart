import 'package:very_good_cli/src/commands/create/commands/create_subcommand.dart';
import 'package:very_good_cli/src/commands/create/templates/templates.dart';

/// {@template very_good_create_flame_game_command}
/// A [CreateSubCommand] for creating Flame games.
/// {@endtemplate}
class CreateFlameGame extends CreateSubCommand with OrgName {
  /// {@macro very_good_create_flame_game_command}
  CreateFlameGame({
    required super.analytics,
    required super.logger,
    required super.generatorFromBundle,
    required super.generatorFromBrick,
  });

  @override
  String get name => 'flame_game';

  @override
  String get description => 'Generate a Very Good Flame game.';

  @override
  Template get template => VeryGoodFlameGameTemplate();
}
