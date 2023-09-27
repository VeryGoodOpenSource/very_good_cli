import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:mason/mason.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import 'package:pub_license/pub_license.dart';
import 'package:pubspec_lock/pubspec_lock.dart';

/// The basename of the pubspec lock file.
const _pubspecLockBasename = 'pubspec.lock';

final PubLicense _pubLicense = PubLicense();

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

    final pubspecLock = _tryParsePubspecLock(targetPath);
    if (pubspecLock == null) {
      return ExitCode.usage.code;
    }

    final licenses = <String, SpdxLicense>{};
    for (final dependency in pubspecLock.packages) {
      // ignore: invalid_use_of_protected_member
      final isPubHostedDepedency = dependency.hosted != null;
      final isDirectDependency = dependency.type() == DependencyType.direct;
      if (!isDirectDependency || !isPubHostedDepedency) continue;

      final packageName = dependency.package();
      final license = await _tryParseLicenseFromPub(packageName);
      if (license == null) {
        return ExitCode.unavailable.code;
      }

      _logger.info('$packageName: ${license.value}');
      licenses[packageName] = license;
    }

    return ExitCode.success.code;
  }

  /// Atttempts to parse a [PubspecLock] file in the given [path].
  ///
  /// If no [PubspecLock] file is found or is unable to be parsed, `null` is
  /// returned and an error is logged accordingly.
  PubspecLock? _tryParsePubspecLock(String targetPath) {
    final pubspecLockFile = File(path.join(targetPath, _pubspecLockBasename));

    if (!pubspecLockFile.existsSync()) {
      _logger.err('Could not find a $_pubspecLockBasename in $targetPath');
      return null;
    }

    try {
      return pubspecLockFile.readAsStringSync().loadPubspecLockFromYaml();
    } catch (e) {
      _logger.err('Could not parse $_pubspecLockBasename in $targetPath');
      return null;
    }
  }

  /// Attempts to parse the license of a package registered at pub.dev.
  ///
  /// If no license is found or is unable to be parsed, `null` is
  /// returned and an error is logged accordingly.
  Future<SpdxLicense?> _tryParseLicenseFromPub(String packageName) async {
    try {
      return await _pubLicense.getLicense(packageName);
    } on PubLicenseException {
      _logger
          .err('Failed to retrieve the license of the package: $packageName');
    } catch (error) {
      _logger.err('Unexpected error: $error.');
    }

    return null;
  }
}
