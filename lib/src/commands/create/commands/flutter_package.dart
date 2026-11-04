import 'package:very_good_cli/src/commands/commands.dart';
import 'package:very_good_cli/src/commands/create/templates/templates.dart';

/// {@template very_good_create_flutter_package_command}
/// A [CreateSubCommand] for creating Flutter packages.
/// {@endtemplate}
class CreateFlutterPackage({
  required super.logger,
  required super.generatorFromBundle,
}) extends CreateSubCommand with Publishable, Workspace, FreeFormOrgName {
  /// {@macro very_good_create_flutter_package_command}
  this;

  @override
  String get defaultOrgName => 'Very Good Ventures';

  @override
  String get name => 'flutter_package';

  @override
  List<String> get aliases => ['flutter_pkg'];

  @override
  String get description => 'Generate a Very Good Flutter package.';

  @override
  Template get template => FlutterPkgTemplate();
}
