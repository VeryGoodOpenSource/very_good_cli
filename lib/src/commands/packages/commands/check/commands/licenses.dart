import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:mason/mason.dart';
import 'package:meta/meta.dart';

/// {@template packages_check_licenses_command}
/// `very_good packages check licenses` command for checking packages.
/// {@endtemplate}
class PackagesCheckLicensesCommand extends Command<int> {
  /// {@macro packages_check_licenses_command}
  PackagesCheckLicensesCommand({Logger? logger})
      : _logger = logger ?? Logger() {
    argParser
      ..addFlag(
        'recursive',
        abbr: 'r',
        help: 'Check licenses recursively for all nested packages.',
        negatable: false,
      )
      ..addMultiOption(
        'ignore',
        help: 'Exclude packages from licenses checks.',
      );
  }

  final Logger _logger;

  @override
  String get description =>
      'Check packages licenses in a Dart or Flutter project.';

  @override
  String get name => 'licenses';

  /// [ArgResults] which can be overridden for testing.
  @visibleForTesting
  ArgResults? argResultOverrides;

  ArgResults get _argResults => argResultOverrides ?? argResults!;

  @override
  Future<int> run() async {
    if (_argResults.rest.length > 1) {
      usageException('Too many arguments');
    }

    return ExitCode.success.code;
  }
}
