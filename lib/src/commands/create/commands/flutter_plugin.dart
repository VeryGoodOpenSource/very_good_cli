import 'package:mason_logger/mason_logger.dart';
import 'package:usage/usage.dart';
import 'package:very_good_cli/src/commands/commands.dart';
import 'package:very_good_cli/src/commands/create/templates/templates.dart';

/// {@template very_good_create_flutter_plugin_command}
/// A [CreateSubCommand] for creating Flutter plugins.
/// {@endtemplate}
class CreateFlutterPlugin extends CreateSubCommand with Publishable {
  /// {@macro very_good_create_flutter_plugin_command}
  CreateFlutterPlugin({
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
  String get description =>
      'Creates a new very good federated Flutter plugin in the specified '
      'directory.';

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
