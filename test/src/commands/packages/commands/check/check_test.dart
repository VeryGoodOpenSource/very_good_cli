import 'dart:collection';

import 'package:mason_logger/mason_logger.dart';
import 'package:test/test.dart';
import 'package:very_good_cli/src/commands/packages/commands/check/check.dart';

import '../../../../../helpers/helpers.dart';

const _expectedPackagesCheckUsage = [
  // ignore: no_adjacent_strings_in_list
  'Perform checks in a Dart or Flutter project.\n'
      '\n'
      'Usage: very_good packages check <subcommand> [arguments]\n'
      '-h, --help    Print this usage information.\n'
      '\n'
      'Available subcommands:\n'
      "  licenses   Check packages' licenses in a Dart or Flutter project.\n"
      '\n'
      'Run "very_good help" to see global options.'
];

void main() {
  group('packages check licenses', () {
    final commandArguments = UnmodifiableListView(
      ['packages', 'check'],
    );

    test(
      'help',
      withRunner((commandRunner, logger, pubUpdater, printLogs) async {
        final result = await commandRunner.run(
          [...commandArguments, '--help'],
        );
        expect(printLogs, equals(_expectedPackagesCheckUsage));
        expect(result, equals(ExitCode.success.code));

        printLogs.clear();

        final resultAbbr = await commandRunner.run([...commandArguments, '-h']);
        expect(printLogs, equals(_expectedPackagesCheckUsage));
        expect(resultAbbr, equals(ExitCode.success.code));
      }),
    );

    test('is not hidden', () {
      final command = PackagesCheckCommand();
      expect(command.hidden, isFalse);
    });
  });
}
