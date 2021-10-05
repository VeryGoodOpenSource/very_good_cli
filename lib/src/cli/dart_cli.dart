part of 'cli.dart';

/// Dart CLI
class Dart {
  /// Determine whether dart is installed.
  static Future<bool> installed() async {
    try {
      await _Cmd.run('dart', ['--version']);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Apply all fixes (`dart fix --apply`).
  static Future<void> applyFixes({
    String cwd = '.',
    bool recursive = false,
  }) async {
    await _process(
      cmd: (cwd) => _Cmd.run(
        'dart',
        ['fix', '--apply'],
        workingDirectory: cwd,
      ),
      cwd: cwd,
      recursive: recursive,
    );
  }

  static Future<void> _process({
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

    await Future.wait(processes);
  }
}
