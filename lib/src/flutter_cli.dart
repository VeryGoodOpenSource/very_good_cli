import 'commands/commands.dart';

/// Flutter CLI
class Flutter {
  /// Install flutter dependencies (`flutter packages get`).
  static Future<void> packagesGet([String? cwd]) {
    return Cmd.run('flutter', ['packages', 'get'], workingDirectory: cwd);
  }

  /// Determine whether flutter is installed
  static Future<bool> installed() async {
    try {
      await Cmd.run('flutter', []);
      return true;
    } catch (_) {
      return false;
    }
  }
}
