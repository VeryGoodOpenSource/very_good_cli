import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:mason/mason.dart';
import 'package:meta/meta.dart';

/// {@template packages_check_licenses_command}
/// `very_good packages check licenses` command for checking packages licenses.
/// {@endtemplate}
class PackagesCheckLicensesCommand extends Command<int> {
  /// {@macro packages_check_licenses_command}
  PackagesCheckLicensesCommand({Logger? logger}) : _logger = logger ?? Logger();

  // ignore: unused_field
  final Logger _logger;

  @override
  String get description =>
      'Check packages licenses in a Dart or Flutter project.';

  @override
  String get name => 'licenses';

  @override
  bool get hidden => true;

  /// [ArgResults] which can be overridden for testing.
  @visibleForTesting
  ArgResults? argResultOverrides;

  // ignore: unused_element
  ArgResults get _argResults => argResultOverrides ?? argResults!;

  @override
  Future<int> run() async {
    return ExitCode.success.code;
  }
}
