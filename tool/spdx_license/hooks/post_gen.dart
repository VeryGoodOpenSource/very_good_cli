import 'dart:io';
import 'package:mason/mason.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;

typedef ProcessRun =
    Future<ProcessResult> Function(
      String command,
      List<String> args, {
      bool runInShell,
      String workingDirectory,
    });

Future<void> run(
  HookContext context, {
  @visibleForTesting ProcessRun runProcess = Process.run,
}) async {
  final progress = context.logger.progress('Formatting files...');

  await runProcess(
    'dart',
    ['format', path.join('test', 'spdx_license.gen.dart')],
    runInShell: true,
    workingDirectory: Directory.current.path,
  );

  progress.complete('Completed post generation');
}
