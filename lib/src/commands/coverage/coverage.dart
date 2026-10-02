import 'package:args/command_runner.dart';
import 'package:mason/mason.dart';
import 'package:very_good_cli/src/commands/coverage/commands/commands.dart';

export 'commands/commands.dart';

/// {@template coverage_command}
/// `very_good coverage` command for working with coverage reports.
/// {@endtemplate}
class CoverageCommand extends Command<int> {
  /// {@macro coverage_command}
  new({required Logger logger}) {
    addSubcommand(CoverageMergeCommand(logger: logger));
  }

  @override
  String get description => 'Command for working with coverage reports.';

  @override
  String get name => 'coverage';
}
