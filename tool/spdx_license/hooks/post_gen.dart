import 'dart:io';
import 'package:mason/mason.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;

typedef ProcessRun = Future<ProcessResult> Function(
  String command,
  List<String> args, {
  bool runInShell,
  String workingDirectory,
});

@visibleForTesting
ProcessRun? processOverride;

Future<void> run(HookContext context) async {
  final runProcess = processOverride ?? Process.run;

  final progress = context.logger.progress('Formatting files');

  await runProcess(
    'dart',
    ['format', path.join('test', 'spdx_license.gen.dart')],
    workingDirectory: Directory.current.path,
    runInShell: true,
  );

  progress.complete();
}
