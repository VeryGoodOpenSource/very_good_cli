import 'package:very_good_cli/src/commands/commands.dart';
import 'package:very_good_cli/src/commands/create/templates/templates.dart';

/// {@template very_good_create_app_ui_package_command}
/// A [CreateSubCommand] for creating App UI packages.
/// {@endtemplate}
class CreateAppUiPackage extends CreateSubCommand with Publishable {
  /// {@macro very_good_create_app_ui_package_command}
  CreateAppUiPackage({
    required super.logger,
    required super.generatorFromBundle,
    required super.generatorFromBrick,
  });

  @override
  String get name => 'app_ui_package';

  @override
  List<String> get aliases => ['app_ui_pkg'];

  @override
  String get description => 'Generate a Very Good App UI package.';

  @override
  Template get template => AppUiTemplate();
}
