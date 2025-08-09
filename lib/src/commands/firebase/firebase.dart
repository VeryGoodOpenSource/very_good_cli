import 'package:args/command_runner.dart';
import 'package:mason/mason.dart';
import 'package:very_good_cli/src/commands/firebase/commands/commands.dart';

/// {@template firebase}
/// `very_good firebase` command provides commands for Firebase checkings.
/// {@endtemplate}
class FirebaseCommand extends Command<int> {
  /// {@macro firebase}
  FirebaseCommand({
    required Logger logger,
  }) {
    addSubcommand(FirebaseCheckCommand(logger: logger));
  }

  @override
  String get summary => '$invocation\n$description';

  @override
  String get description =>
      'Perform checkings and operations related to Firebase.';

  @override
  String get name => 'firebase';

  @override
  String get invocation => 'very_good firebase <subcommand> [arguments]';
}
