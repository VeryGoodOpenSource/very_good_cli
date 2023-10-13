import 'dart:io';
import 'package:mason/mason.dart';

Future<void> run(HookContext context) async {
  final progress = context.logger.progress('Formatting files');

  await Process.run(
    'dart',
    ['format', '.'],
    workingDirectory: Directory.current.path,
  );

  progress.complete();
}
