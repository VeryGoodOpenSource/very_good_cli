import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:mason/mason.dart';
import 'package:meta/meta.dart';
import 'package:very_good_cli/src/commands/packages/commands/check/commands/commands.dart';

/// {@template packages_check_command}
/// `very_good packages check` command for checking packages.
/// {@endtemplate}
class PackagesCheckCommand extends Command<int> {
  /// {@macro packages_check_command}
  PackagesCheckCommand({Logger? logger}) : _logger = logger ?? Logger() {
    addSubcommand(PackagesCheckLicensesCommand(logger: _logger));
  }

  final Logger _logger;

  @override
  String get description => 'Check packages in a Dart or Flutter project.';

  @override
  String get name => 'check';

  @override
  bool get hidden => true;
}
