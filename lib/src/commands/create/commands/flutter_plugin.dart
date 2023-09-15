import 'package:very_good_cli/src/commands/commands.dart';
import 'package:very_good_cli/src/commands/create/templates/templates.dart';

/// {@template very_good_create_flutter_plugin_command}
/// A [CreateSubCommand] for creating Flutter plugins.
/// {@endtemplate}
class CreateFlutterPlugin extends CreateSubCommand with Publishable, OrgName {
  /// {@macro very_good_create_flutter_plugin_command}
  CreateFlutterPlugin({
    required super.logger,
    required super.generatorFromBundle,
    required super.generatorFromBrick,
  }) {
    argParser.addMultiOption(
      'platforms',
      help: 'The platforms supported by the plugin. By default, all platforms '
          'are enabled. Example: --platforms=android,ios',
      defaultsTo: ['android', 'ios', 'web', 'linux', 'macos', 'windows'],
      allowed: ['android', 'ios', 'web', 'linux', 'macos', 'windows'],
      allowedHelp: {
        'android': 'The plugin supports the Android platform.',
        'ios': 'The plugin supports the iOS platform.',
        'web': 'The plugin supports the Web platform.',
        'linux': 'The plugin supports the Linux platform.',
        'macos': 'The plugin supports the macOS platform.',
        'windows': 'The plugin supports the Windows platform.',
      },
    );
  }

  @override
  String get name => 'flutter_plugin';

  @override
  String get description => 'Generate a Very Good Flutter plugin.';

  @override
  Template get template => FlutterPluginTemplate();

  @override
  Map<String, dynamic> getTemplateVars() {
    final vars = super.getTemplateVars();

    final platforms = argResults['platforms'] as List<String>;

    vars['platforms'] = platforms;

    return vars;
  }
}
