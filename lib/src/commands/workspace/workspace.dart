import 'package:args/command_runner.dart';
import 'package:mason/mason.dart';
import 'package:very_good_cli/src/commands/workspace/commands/commands.dart';

/// {@template workspace_command}
/// `very_good workspace` command for managing Pub workspaces.
/// {@endtemplate}
class WorkspaceCommand extends Command<int> {
  /// {@macro workspace_command}
  WorkspaceCommand({required Logger logger}) {
    addSubcommand(WorkspaceMatrixCommand(logger: logger));
  }

  @override
  String get description => 'Command for managing Pub workspaces.';

  @override
  String get name => 'workspace';
}
