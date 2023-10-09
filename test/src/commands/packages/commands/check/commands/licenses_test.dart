import 'dart:collection';

import 'package:mason_logger/mason_logger.dart';
import 'package:test/test.dart';
import 'package:very_good_cli/src/commands/packages/commands/check/commands/commands.dart';

import '../../../../../../helpers/helpers.dart';

const _expectedPackagesCheckLicensesUsage = [
  // ignore: no_adjacent_strings_in_list
  'Check packages licenses in a Dart or Flutter project.\n'
      '\n'
      'Usage: very_good packages check licenses [arguments]\n'
      '-h, --help    Print this usage information.\n'
      '\n'
      'Run "very_good help" to see global options.'
];

void main() {
  group('packages check licenses', () {
    final commandArguments = UnmodifiableListView(
      ['packages', 'check', 'licenses'],
    );

    test(
      'help',
      withRunner(
          (commandRunner, logger, pubUpdater, pubLicense, printLogs) async {
        final result = await commandRunner.run(
          [...commandArguments, '--help'],
        );
        expect(printLogs, equals(_expectedPackagesCheckLicensesUsage));
        expect(result, equals(ExitCode.success.code));

        printLogs.clear();

        final resultAbbr = await commandRunner.run([...commandArguments, '-h']);
        expect(printLogs, equals(_expectedPackagesCheckLicensesUsage));
        expect(resultAbbr, equals(ExitCode.success.code));
      }),
    );

    test(
      'returns exit code 0',
      withRunner(
          (commandRunner, logger, pubUpdater, pubLicense, printLogs) async {
        final result = await commandRunner.run(commandArguments);
        expect(result, equals(ExitCode.success.code));
      }),
    );

    test('is hidden', () {
      final command = PackagesCheckLicensesCommand();
      expect(command.hidden, isTrue);
    });
  });
}
