part of 'cli.dart';

/// Thrown when `flutter packages get` or `flutter pub get`
/// is exectuted without a pubspec.yaml
class PubspecNotFound implements Exception {}

/// Flutter CLI
class Flutter {
  /// Install flutter dependencies (`flutter packages get`).
  static Future<void> packagesGet({
    String cwd = '.',
    bool recursive = false,
  }) async {
    await Dart.installPackages(
      cmd: (cwd) => _Cmd.run(
        'flutter',
        ['packages', 'get'],
        workingDirectory: cwd,
      ),
      cwd: cwd,
      recursive: recursive,
    );
  }

  /// Install dart dependencies (`flutter pub get`).
  static Future<void> pubGet({
    String cwd = '.',
    bool recursive = false,
  }) async {
    await Dart.installPackages(
      cmd: (cwd) => _Cmd.run(
        'flutter',
        ['pub', 'get'],
        workingDirectory: cwd,
      ),
      cwd: cwd,
      recursive: recursive,
    );
  }

  /// Determine whether flutter is installed.
  static Future<bool> installed() async {
    try {
      await _Cmd.run('flutter', ['--version']);
      return true;
    } catch (_) {
      return false;
    }
  }
}
