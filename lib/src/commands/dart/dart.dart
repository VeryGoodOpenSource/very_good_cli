import 'package:args/command_runner.dart';
import 'package:mason/mason.dart';
import 'package:very_good_cli/src/commands/dart/commands/commands.dart';

/// {@template dart_command}
/// `very_good dart` command for running dart related commands.
/// {@endtemplate}
class DartCommand({required Logger logger}) extends Command<int> {
  /// {@macro packages_command}
  this {
    addSubcommand(DartTestCommand(logger: logger));
  }

  @override
  String get description => 'Command for running dart related commands.';

  @override
  String get name => 'dart';
}
