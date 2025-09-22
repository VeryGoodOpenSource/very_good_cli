// Expected usage of the plugin will need to be adjacent strings due to format
// and also be longer than 80 chars.
// ignore_for_file: no_adjacent_strings_in_list

import 'package:mason/mason.dart';
import 'package:test/test.dart';

import '../../../helpers/command_helper.dart';

const _expectedDartUsage = [
  'Command for running dart related commands.\n'
      '\n'
      'Usage: very_good dart <subcommand> [arguments]\n'
      '-h, --help    Print this usage information.\n'
      '\n'
      'Available subcommands:\n'
      '  test   Run tests in a Dart project.\n'
      '\n'
      'Run "very_good help" to see global options.',
];

void main() {
  group('dart', () {
    test(
      'help',
      withRunner((commandRunner, logger, pubUpdater, printLogs) async {
        final result = await commandRunner.run(['dart', '--help']);
        expect(printLogs, equals(_expectedDartUsage));
        expect(result, equals(ExitCode.success.code));

        printLogs.clear();

        final resultAbbr = await commandRunner.run(['dart', '-h']);
        expect(printLogs, equals(_expectedDartUsage));
        expect(resultAbbr, equals(ExitCode.success.code));
      }),
    );
  });
}
