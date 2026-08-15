// Expected usage of the plugin will need to be adjacent strings due to format
// and also be longer than 80 chars.
// ignore_for_file: no_adjacent_strings_in_list, lines_longer_than_80_chars

import 'package:mason/mason.dart';
import 'package:test/test.dart';

import '../../../helpers/command_helper.dart';

const _expectedWorkspaceUsage = [
  'Command for managing Pub workspaces.\n'
      '\n'
      'Usage: very_good workspace <subcommand> [arguments]\n'
      '-h, --help    Print this usage information.\n'
      '\n'
      'Available subcommands:\n'
      '  matrix   Return a JSON list of affected projects in the current workspace.\n'
      '\n'
      'Run "very_good help" to see global options.',
];

void main() {
  group('workspace', () {
    test(
      'help',
      withRunner((commandRunner, logger, pubUpdater, printLogs) async {
        final result = await commandRunner.run(['workspace', '--help']);
        expect(printLogs, equals(_expectedWorkspaceUsage));
        expect(result, equals(ExitCode.success.code));

        printLogs.clear();

        final resultAbbr = await commandRunner.run(['workspace', '-h']);
        expect(printLogs, equals(_expectedWorkspaceUsage));
        expect(resultAbbr, equals(ExitCode.success.code));
      }),
    );
  });
}
