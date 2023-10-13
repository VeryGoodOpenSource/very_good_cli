import 'dart:io';
import 'package:mason/mason.dart';
import 'package:path/path.dart' as path;

Future<void> run(HookContext context) async {
  final progress = context.logger.progress('Formatting files');

  await Process.run(
    'dart',
    ['format', path.join('test', 'spdx_license.gen.dart')],
    workingDirectory: Directory.current.path,
  );

  progress.complete();
}
