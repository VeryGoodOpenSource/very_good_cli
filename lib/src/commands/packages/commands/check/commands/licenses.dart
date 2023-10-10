import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:mason/mason.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import 'package:pubspec_lock/pubspec_lock.dart';
import 'package:very_good_cli/src/pub_license/pub_license.dart';

/// The basename of the pubspec lock file.
@visibleForTesting
const pubspecLockBasename = 'pubspec.lock';

/// {@template packages_check_licenses_command}
/// `very_good packages check licenses` command for checking packages licenses.
/// {@endtemplate}
class PackagesCheckLicensesCommand extends Command<int> {
  /// {@macro packages_check_licenses_command}
  PackagesCheckLicensesCommand({
    Logger? logger,
    PubLicense? pubLicense,
  })  : _logger = logger ?? Logger(),
        _pubLicense = pubLicense ?? PubLicense();

  final Logger _logger;

  final PubLicense _pubLicense;

  @override
  String get description =>
      'Check packages licenses in a Dart or Flutter project.';

  @override
  String get name => 'licenses';

  @override
  bool get hidden => true;

  ArgResults get _argResults => argResults!;

  @override
  Future<int> run() async {
    final target = _argResults.rest.length == 1 ? _argResults.rest[0] : '.';
    final targetPath = path.normalize(Directory(target).absolute.path);

    final progress = _logger.progress('Checking licenses on $targetPath');

    final pubspecLockFile = File(path.join(targetPath, pubspecLockBasename));
    if (!pubspecLockFile.existsSync()) {
      progress.cancel();
      _logger.err('Could not find a $pubspecLockBasename in $targetPath');
      return ExitCode.noInput.code;
    }

    final pubspecLock = _tryParsePubspecLock(pubspecLockFile);
    if (pubspecLock == null) {
      progress.cancel();
      _logger.err('Could not parse $pubspecLockBasename in $targetPath');
      return ExitCode.noInput.code;
    }

    final filteredDependencies =
        pubspecLock.packages.where(_isHostedDirectDependency);

    if (filteredDependencies.isEmpty) {
      progress.cancel();
      _logger.err('No hosted direct dependencies found in $targetPath');
      return ExitCode.usage.code;
    }

    final licenses = <String, Set<String>>{};
    for (final dependency in filteredDependencies) {
      progress.update(
        'Collecting licenses of ${licenses.length}/${filteredDependencies.length} packages',
      );

      final dependencyName = dependency.package();
      Set<String> rawLicense;
      try {
        rawLicense = await _pubLicense.getLicense(dependencyName);
      } on PubLicenseException catch (e) {
        progress.cancel();
        _logger.err('[$dependencyName] ${e.message}');
        return ExitCode.unavailable.code;
      } catch (e) {
        progress.cancel();
        _logger.err('[$dependencyName] Unexpected failure with error: $e');
        return ExitCode.software.code;
      }

      licenses[dependencyName] = rawLicense;
    }

    final licenseTypes = licenses.values.fold(
      <String>{},
      (previousValue, element) => previousValue..addAll(element),
    );
    final licenseCount = licenses.values.fold<int>(
      0,
      (previousValue, element) => previousValue + element.length,
    );

    final licenseWord = licenseCount == 1 ? 'license' : 'licenses';
    final packageWord =
        filteredDependencies.length == 1 ? 'package' : 'packages';
    progress.complete(
      '''Retrieved $licenseCount $licenseWord from ${filteredDependencies.length} $packageWord of type: ${licenseTypes.toList().stringify()}.''',
    );

    return ExitCode.success.code;
  }
}

/// Attempts to parse a [PubspecLock] file in the given [path].
///
/// If no [PubspecLock] file is found or is unable to be parsed, `null` is
/// returned.
PubspecLock? _tryParsePubspecLock(File pubspecLockFile) {
  try {
    return pubspecLockFile.readAsStringSync().loadPubspecLockFromYaml();
  } catch (e) {
    return null;
  }
}

bool _isHostedDirectDependency(
  PackageDependency dependency,
) {
  // ignore: invalid_use_of_protected_member
  final isPubHostedDependency = dependency.hosted != null;
  final isDirectDependency = dependency.type() == DependencyType.direct;
  return isPubHostedDependency && isDirectDependency;
}

extension on List<Object> {
  String stringify() {
    if (isEmpty) return '';
    if (length == 1) return first.toString();
    final last = removeLast();
    return '${join(', ')} and $last';
  }
}
