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
    await _installPackages(
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
    await _installPackages(
      cmd: (cwd) => _Cmd.run(
        'flutter',
        ['pub', 'get'],
        workingDirectory: cwd,
      ),
      cwd: cwd,
      recursive: recursive,
    );
  }

  /// Determine whether flutter is installed
  static Future<bool> installed() async {
    try {
      await _Cmd.run('flutter', []);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> _installPackages({
    required Future<ProcessResult> Function(String cwd) cmd,
    required String cwd,
    required bool recursive,
  }) async {
    if (!recursive) {
      final pubspec = File(p.join(cwd, 'pubspec.yaml'));
      if (!pubspec.existsSync()) throw PubspecNotFound();

      await cmd(cwd);
      return;
    }

    final processes = _process(
      run: (entity) => cmd(entity.parent.path),
      where: _isPubspec,
      cwd: cwd,
    );

    if (processes.isEmpty) throw PubspecNotFound();

    await Future.wait(processes);
  }

  static Iterable<Future<ProcessResult>> _process({
    required Future<ProcessResult> Function(FileSystemEntity) run,
    required bool Function(FileSystemEntity) where,
    String cwd = '.',
  }) {
    return Directory(cwd).listSync(recursive: true).where(where).map(run);
  }
}

bool _isPubspec(FileSystemEntity entity) {
  if (entity is! File) return false;
  return p.basename(entity.path) == 'pubspec.yaml';
}
