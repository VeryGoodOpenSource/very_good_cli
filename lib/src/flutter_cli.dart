import 'package:path/path.dart' as p;
import 'package:universal_io/io.dart';

/// Flutter CLI
class Flutter {
  /// Install flutter dependencies (`flutter packages get`).
  static Future<void> packagesGet({String? cwd, bool recursive = true}) async {
    var foundPubspec = false;

    if (recursive) {
      final futures =
          Directory(cwd ?? '').listSync(recursive: true).where((element) {
        final e = element;
        if (e is! File) return false;

        return p.basename(e.path) == 'pubspec.yaml';
      }).map(
        (element) {
          foundPubspec = true;
          return _Cmd.run(
            'flutter',
            ['packages', 'get'],
            workingDirectory: element.parent.path,
          );
        },
      );

      await Future.wait(futures);
    }

    if (foundPubspec == false) {
      await _Cmd.run('flutter', ['packages', 'get'], workingDirectory: cwd);
    }
  }

  /// Install dart dependencies (`flutter pub get`).
  static Future<void> pubGet({String? cwd, bool recursive = true}) async {
    var hasPubspec = false;

    if (recursive) {
      final futures =
          Directory(cwd ?? '').listSync(recursive: true).where((element) {
        final e = element;
        if (e is! File) return false;

        return p.basename(e.path) == 'pubspec.yaml';
      }).map(
        (element) {
          hasPubspec = true;
          return _Cmd.run(
            'flutter',
            ['pub', 'get'],
            workingDirectory: element.parent.path,
          );
        },
      );

      await Future.wait(futures);
    }

    if (hasPubspec == false) {
      await _Cmd.run('flutter', ['pub', 'get'], workingDirectory: cwd);
    }
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
