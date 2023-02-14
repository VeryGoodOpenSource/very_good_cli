part of 'cli.dart';

/// Dart CLI
class Dart {
  /// Determine whether dart is installed.
  static Future<bool> installed({
    required Logger logger,
  }) async {
    try {
      await _Cmd.run('dart', ['--version'], logger: logger);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Apply all fixes (`dart fix --apply`).
  static Future<void> applyFixes({
    required Logger logger,
    String cwd = '.',
    bool recursive = false,
    Set<String> ignore = const {},
  }) async {
    if (!recursive) {
      final pubspec = File(p.join(cwd, 'pubspec.yaml'));
      if (!pubspec.existsSync()) throw PubspecNotFound();

      await _Cmd.run(
        'dart',
        ['fix', '--apply'],
        workingDirectory: cwd,
        logger: logger,
      );
      return;
    }

    final processes = _Cmd.runWhere(
      run: (entity) => _Cmd.run(
        'dart',
        ['fix', '--apply'],
        workingDirectory: entity.parent.path,
        logger: logger,
      ),
      where: (entity) => !ignore.excludes(entity) && _isPubspec(entity),
      cwd: cwd,
    );

    if (processes.isEmpty) throw PubspecNotFound();

    await Future.wait<void>(processes);
  }
}
