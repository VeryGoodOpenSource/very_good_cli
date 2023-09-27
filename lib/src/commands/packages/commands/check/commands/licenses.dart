import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:mason/mason.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import 'package:pub_license/pub_license.dart';
import 'package:pubspec_lock/pubspec_lock.dart';

/// {@template packages_check_licenses_command}
/// `very_good packages check licenses` command for checking packages.
/// {@endtemplate}
class PackagesCheckLicensesCommand extends Command<int> {
  /// {@macro packages_check_licenses_command}
  PackagesCheckLicensesCommand({Logger? logger})
      : _logger = logger ?? Logger() {
    argParser.addMultiOption(
      'ignore',
      help: 'Exclude packages from licenses checks.',
    );
    // ..addFlag(
    //   'recursive',
    //   abbr: 'r',
    //   help: 'Check licenses recursively for all nested packages.',
    //   negatable: false,
    // )
  }

  final Logger _logger;

  final PubLicense _pubLicense = PubLicense();

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

    final target = _argResults.rest.length == 1 ? _argResults.rest[0] : '.';
    final targetPath = path.normalize(Directory(target).absolute.path);

    final pubspecLockFile = File(path.join(targetPath, 'pubspec.lock'));
    if (!pubspecLockFile.existsSync()) {
      _logger.err('Could not find a pubspec.lock in $targetPath');
    }

    final pubspecLock =
        pubspecLockFile.readAsStringSync().loadPubspecLockFromYaml();

    for (final dependency in pubspecLock.packages) {
      final isDirectDependency = dependency.type() == DependencyType.direct;
      // ignore: invalid_use_of_protected_member
      final isPubHostedDepedency = dependency.hosted != null;
      if (!isDirectDependency || !isPubHostedDepedency) continue;

      final name = dependency.package();
      late final SpdxLicense license;

      try {
        license = await _pubLicense.getLicense(name);
      } on PubLicenseException {
        _logger.err('Failed to retrieve the license of the package: $name');
        return ExitCode.unavailable.code;
      } catch (error) {
        _logger.err('Unexpected error: $error.');
        return ExitCode.unavailable.code;
      }

      _logger.info('$name: ${license.value}');
    }

    return ExitCode.success.code;
  }
}
