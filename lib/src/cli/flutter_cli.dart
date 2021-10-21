part of 'cli.dart';

/// Thrown when `flutter packages get` or `flutter pub get`
/// is executed without a `pubspec.yaml`.
class PubspecNotFound implements Exception {}

/// Flutter CLI
class Flutter {
  /// Determine whether flutter is installed.
  static Future<bool> installed() async {
    try {
      await _Cmd.run('flutter', ['--version']);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Install flutter dependencies (`flutter packages get`).
  static Future<void> packagesGet({
    String cwd = '.',
    bool recursive = false,
    void Function([String?]) Function(String message)? progress,
  }) async {
    await _installPackages(
      cmd: (cwd) async {
        final installDone = progress?.call(
          'Running "flutter packages get" in $cwd',
        );
        try {
          final result = await _Cmd.run(
            'flutter',
            ['packages', 'get'],
            workingDirectory: cwd,
          );
          return result;
        } catch (_) {
          rethrow;
        } finally {
          installDone?.call();
        }
      },
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

  /// Install dependencies in directories with a `pubspec.yaml`.
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

    final processes = _Cmd.runWhere(
      run: (entity) => cmd(entity.parent.path),
      where: _isPubspec,
      cwd: cwd,
    );

    if (processes.isEmpty) throw PubspecNotFound();

    for (final process in processes) {
      await process;
    }
  }
}
