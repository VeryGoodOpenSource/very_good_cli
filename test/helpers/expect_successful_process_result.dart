import 'dart:io';

import 'package:mason/mason.dart';
import 'package:test/test.dart';

Future<ProcessResult> expectSuccessfulProcessResult(
  String executable,
  List<String> arguments, {
  required String workingDirectory,
}) async {
  final result = await Process.run(
    executable,
    arguments,
    workingDirectory: workingDirectory,
    runInShell: true,
  );
  expect(
    result.exitCode,
    equals(ExitCode.success.code),
    reason:
        '''`$executable ${arguments.join(' ')}` in $workingDirectory failed with "${result.stderr}" and "${result.stdout}"''',
  );
  expect(result.stderr, isEmpty);

  return result;
}
