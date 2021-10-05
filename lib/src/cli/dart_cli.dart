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
    if (!recursive) {
      final pubspec = File(p.join(cwd, 'pubspec.yaml'));
      if (!pubspec.existsSync()) throw PubspecNotFound();

      await _Cmd.run('dart', ['fix', '--apply'], workingDirectory: cwd);
      return;
    }

    final processes = _process(
      run: (entity) => _Cmd.run(
        'dart',
        ['fix', '--apply'],
        workingDirectory: entity.parent.path,
      ),
      where: _isPubspec,
      cwd: cwd,
    );

    if (processes.isEmpty) throw PubspecNotFound();

    await Future.wait(processes);
  }
}

bool _isPubspec(FileSystemEntity entity) {
  if (entity is! File) return false;
  return p.basename(entity.path) == 'pubspec.yaml';
}

Iterable<Future<ProcessResult>> _process({
  required Future<ProcessResult> Function(FileSystemEntity) run,
  required bool Function(FileSystemEntity) where,
  String cwd = '.',
}) {
  return Directory(cwd).listSync(recursive: true).where(where).map(run);
}
