import 'package:very_good_cli/src/commands/create/commands/create_subcommand.dart';
import 'package:very_good_cli/src/commands/create/templates/templates.dart';

/// {@template very_good_create_flame_game_command}
/// A [CreateSubCommand] for creating Flame games.
/// {@endtemplate}
class CreateFlameGame extends CreateSubCommand with OrgName {
  /// {@macro very_good_create_flame_game_command}
  CreateFlameGame({
    required super.logger,
    required super.generatorFromBundle,
    required super.generatorFromBrick,
  }) {
    argParser.addMultiOption(
      'platforms',
      help:
          'The platforms supported by the game. By default, all platforms '
          'are enabled. Example: --platforms=android,ios',
      defaultsTo: ['android', 'ios', 'web', 'macos', 'windows'],
      allowed: ['android', 'ios', 'web', 'macos', 'windows'],
      allowedHelp: {
        'android': 'The plugin supports the Android platform.',
        'ios': 'The plugin supports the iOS platform.',
        'web': 'The plugin supports the Web platform.',
        'macos': 'The plugin supports the macOS platform.',
        'windows': 'The plugin supports the Windows platform.',
      },
    );
  }

  @override
  String get name => 'flame_game';

  @override
  String get description => 'Generate a Very Good Flame game.';

  @override
  Template get template => VeryGoodFlameGameTemplate();

  @override
  Map<String, dynamic> getTemplateVars() {
    final vars = super.getTemplateVars();

    final platforms = argResults['platforms'] as List<String>;

    vars['platforms'] = platforms;

    return vars;
  }
}
