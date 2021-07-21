import 'commands/commands.dart';

/// Dart CLI
class Dart {
  /// Install dart dependencies (`dart pub get`).
  static Future<void> packagesGet([String? cwd]) {
    return Cmd.run('dart', ['pub', 'get'], workingDirectory: cwd);
  }

  /// Determine whether dart is installed
  static Future<bool> installed() async {
    try {
      await Cmd.run('dart', []);
      return true;
    } catch (_) {
      return false;
    }
  }
}
