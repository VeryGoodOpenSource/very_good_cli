// Expected usage of the plugin will need to be adjacent strings due to format
// and also be longer than 80 chars.
// ignore_for_file: no_adjacent_strings_in_list, lines_longer_than_80_chars

import 'package:mason/mason.dart';
import 'package:test/test.dart';

import '../../../helpers/helpers.dart';

const _expectedCoverageUsage = [
  'Command for working with coverage reports.\n'
      '\n'
      'Usage: very_good coverage <subcommand> [arguments]\n'
      '-h, --help    Print this usage information.\n'
      '\n'
      'Available subcommands:\n'
      '  merge   Merge lcov reports, from sharded or recursive test runs, and check the merged coverage.\n'
      '\n'
      'Run "very_good help" to see global options.',
];

void main() {
  group('coverage', () {
    test(
      'help',
      withRunner((commandRunner, logger, pubUpdater, printLogs) async {
        final result = await commandRunner.run(['coverage', '--help']);
        expect(printLogs, equals(_expectedCoverageUsage));
        expect(result, equals(ExitCode.success.code));
      }),
    );
  });
}
