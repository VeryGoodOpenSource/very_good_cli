import 'package:universal_io/io.dart';

/// Flutter CLI
class Flutter {
  /// Install flutter dependencies (`flutter packages get`).
  static Future<void> packagesGet([String? cwd]) {
    return _Cmd.run('flutter', ['packages', 'get'], workingDirectory: cwd);
  }

  /// Install dart dependencies (`flutter pub get`).
  static Future<void> pubGet([String? cwd]) {
    return _Cmd.run('flutter', ['pub', 'get'], workingDirectory: cwd);
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
}

/// Abstraction for running commands via command-line.
class _Cmd {
  /// Runs the specific command
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
