import 'package:path/path.dart' as p;
import 'package:universal_io/io.dart';

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

/// Abstraction for running commands via command-line.
class _Cmd {
  /// Runs the specified [cmd] with the provided [args].
  static Future<ProcessResult> run(
    String cmd,
    List<String> args, {
    bool throwOnError = true,
    String? workingDirectory,
  }) async {
    final result = await Process.run(cmd, args,
        workingDirectory: workingDirectory, runInShell: true);

    if (throwOnError) {
      _throwIfProcessFailed(result, cmd, args);
    }
    return result;
  }

  static void _throwIfProcessFailed(
    ProcessResult pr,
    String process,
    List<String> args,
  ) {
    if (pr.exitCode != 0) {
      final values = {
        'Standard out': pr.stdout.toString().trim(),
        'Standard error': pr.stderr.toString().trim()
      }..removeWhere((k, v) => v.isEmpty);

      var message = 'Unknown error';
      if (values.isNotEmpty) {
        message = values.entries.map((e) => '${e.key}\n${e.value}').join('\n');
      }

      throw ProcessException(process, args, message, pr.exitCode);
    }
  }
}

bool _isPubspec(FileSystemEntity entity) {
  if (entity is! File) return false;
  return p.basename(entity.path) == 'pubspec.yaml';
}
