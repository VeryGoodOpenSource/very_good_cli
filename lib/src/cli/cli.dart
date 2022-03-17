import 'dart:async';

import 'package:glob/glob.dart';
import 'package:lcov_parser/lcov_parser.dart';
import 'package:mason/mason.dart';
import 'package:path/path.dart' as p;
import 'package:universal_io/io.dart';
import 'package:very_good_test_runner/very_good_test_runner.dart';

part 'dart_cli.dart';
part 'flutter_cli.dart';

/// Abstraction for running commands via command-line.
class _Cmd {
  /// Runs the specified [cmd] with the provided [args].
  static Future<ProcessResult> run(
    String cmd,
    List<String> args, {
    bool throwOnError = true,
    String? workingDirectory,
  }) async {
    final result = await Process.run(
      cmd,
      args,
      workingDirectory: workingDirectory,
      runInShell: true,
    );

    if (throwOnError) {
      _throwIfProcessFailed(result, cmd, args);
    }
    return result;
  }

  static Iterable<Future> runWhere<T>({
    required Future<T> Function(FileSystemEntity) run,
    required bool Function(FileSystemEntity) where,
    String cwd = '.',
  }) {
    return Directory(cwd).listSync(recursive: true).where(where).map(run);
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

const _ignoredDirectories = {
  'ios',
  'android',
  'windows',
  'linux',
  'macos',
  '.symlinks',
  '.plugin_symlinks',
  '.dart_tool',
  'build',
  '.fvm',
};

bool _isPubspec(FileSystemEntity entity) {
  final segments = p.split(entity.path).toSet();
  if (segments.intersection(_ignoredDirectories).isNotEmpty) return false;
  if (entity is! File) return false;
  return p.basename(entity.path) == 'pubspec.yaml';
}
