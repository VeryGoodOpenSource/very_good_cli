import 'package:args/command_runner.dart';
import 'package:mason/mason.dart';
import 'package:very_good_cli/src/commands/packages/commands/check/commands/commands.dart';

/// {@template packages_check_command}
/// `very_good packages check` command for performing checks in a Dart or
/// Flutter project.
/// {@endtemplate}
class PackagesCheckCommand extends Command<int> {
  /// {@macro packages_check_command}
  PackagesCheckCommand({
    Logger? logger,
  }) {
    addSubcommand(
      PackagesCheckLicensesCommand(logger: logger),
    );
  }

  @override
  String get description => 'Perform checks in a Dart or Flutter project.';

  @override
  String get name => 'check';
}
