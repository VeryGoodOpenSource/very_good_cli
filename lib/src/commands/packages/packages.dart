import 'package:args/command_runner.dart';
import 'package:mason/mason.dart';
import 'package:very_good_cli/src/commands/packages/commands/check/check.dart';
import 'package:very_good_cli/src/commands/packages/commands/commands.dart';

/// {@template packages_command}
/// `very_good packages` command for managing packages.
/// {@endtemplate}
class PackagesCommand extends Command<int> {
  /// {@macro packages_command}
  PackagesCommand({Logger? logger}) {
    addSubcommand(PackagesGetCommand(logger: logger));
    addSubcommand(PackagesCheckCommand(logger: logger));
  }

  @override
  String get description => 'Command for managing packages.';

  @override
  String get name => 'packages';
}
