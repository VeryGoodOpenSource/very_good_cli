import 'package:universal_io/io.dart';

/// Dart CLI
class Dart {
  /// Install dart dependencies (`dart pub get`).
  static Future<void> packagesGet([String? cwd]) {
    return _Cmd.run('dart', ['pub', 'get'], workingDirectory: cwd);
  }

  /// Determine whether dart is installed
  static Future<bool> installed() async {
    try {
      await _Cmd.run('dart', []);
      return true;
    } catch (_) {
      return false;
    }
  }
}

class _Cmd {
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
