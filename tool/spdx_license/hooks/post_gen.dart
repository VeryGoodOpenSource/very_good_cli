import 'dart:async';
import 'dart:io';

import 'package:mason/mason.dart';
import 'package:spdx_license_hooks/hooks.dart';

Future<void> run(HookContext context) async {
  final runProcess = ProcessOverrides.current?.runProcess ?? Process.run;
  final result = await runProcess(
    'dart',
    ['format'],
    workingDirectory: Directory.current.path,
    runInShell: true,
  );

  if (result.exitCode != ExitCode.success.code) {
    throw Exception(result.stderr);
  }
}
