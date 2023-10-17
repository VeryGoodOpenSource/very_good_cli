import 'package:args/command_runner.dart';
import 'package:mason/mason.dart';
import 'package:very_good_cli/src/commands/packages/commands/check/commands/commands.dart';
import 'package:very_good_cli/src/pub_license/pub_license.dart';

/// {@template packages_check_command}
/// `very_good packages check` command for performing checks in a Dart or
/// Flutter project.
/// {@endtemplate}
class PackagesCheckCommand extends Command<int> {
  /// {@macro packages_check_command}
  PackagesCheckCommand({
    Logger? logger,
    PubLicense? pubLicense,
  }) {
    addSubcommand(
      PackagesCheckLicensesCommand(logger: logger, pubLicense: pubLicense),
    );
  }

  @override
  String get description => 'Perform checks in a Dart or Flutter project.';

  @override
  String get name => 'check';

  @override
  bool get hidden => true;
}
