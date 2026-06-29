import 'package:very_good_cli/src/commands/commands.dart';
import 'package:very_good_cli/src/commands/create/templates/templates.dart';

/// {@template very_good_create_workspace_command}
/// A [CreateSubCommand] for creating multi-package workspaces.
/// {@endtemplate}
class CreateWorkspace extends CreateSubCommand {
  /// {@macro very_good_create_workspace_command}
  CreateWorkspace({required super.logger, required super.generatorFromBundle});

  @override
  String get name => 'workspace';

  @override
  List<String> get aliases => ['ws'];

  @override
  String get description => 'Generate a Very Good multi-package workspace.';

  // A workspace must not register itself as a member of another workspace.
  @override
  bool get registersInWorkspace => false;

  @override
  Template get template => VeryGoodWorkspaceTemplate();
}
