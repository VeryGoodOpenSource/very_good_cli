import 'dart:async';
import 'dart:convert';

import 'package:mason/mason.dart';
import 'package:path/path.dart' as p;
import 'package:universal_io/io.dart';
import 'package:very_good_cli/src/cli/test_event.dart';

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
    void Function(String message)? stdout,
    void Function(String message)? stderr,
  }) async {
    final stdoutLogs = <String>[];
    final stderrLogs = <String>[];
    final process = await Process.start(
      cmd,
      args,
      workingDirectory: workingDirectory,
      runInShell: true,
    );
    final stdoutSubscription = process.stdout.transform(utf8.decoder).listen(
      (message) {
        stdout?.call(message);
        stdoutLogs.add(message);
      },
    );
    final stderrSubscription = process.stderr.transform(utf8.decoder).listen(
      (message) {
        stderr?.call(message);
        stderrLogs.add(message);
      },
    );
    final exitCode = await process.exitCode;
    await Future.wait([
      stdoutSubscription.cancel(),
      stderrSubscription.cancel(),
    ]);

    final result = ProcessResult(process.pid, exitCode, stdoutLogs, stderrLogs);

    if (throwOnError) {
      _throwIfProcessFailed(result, cmd, args);
    }
    return result;
  }

  static Iterable<Future<ProcessResult>> runWhere({
    required Future<ProcessResult> Function(FileSystemEntity) run,
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
