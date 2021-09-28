part of 'cli.dart';

/// Dart CLI
class Dart {
  /// Determine whether dart is installed
  static Future<bool> installed() async {
    try {
      await _Cmd.run('dart', ['--version']);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Apply all fixes (`dart fix --apply`).
  static Future<void> applyFixes() {
    return _Cmd.run('dart', ['fix', '--apply']);
  }
}
