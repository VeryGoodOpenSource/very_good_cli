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
    argParser
      ..addMultiOption(
        'ignore',
        help: 'Ignore packages from licenses checks.',
      )
      ..addMultiOption(
        'allowed',
        help: 'Allowed licenses.',
        defaultsTo: [],
      )
      ..addMultiOption(
        'forbidden',
        help: 'Not allowed licenses.',
        defaultsTo: [],
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

    final allowed = (_argResults['allowed'] as List<String>).toSet();
    final forbidden = (_argResults['forbidden'] as List<String>).toSet();
    final allowedForbiddenIntersection = allowed.intersection(forbidden);
    if (allowedForbiddenIntersection.isNotEmpty) {
      usageException(
        '''Allowed and forbidden licenses cannot intersect, found: $allowedForbiddenIntersection''',
      );
    }

    final target = _argResults.rest.length == 1 ? _argResults.rest[0] : '.';
    final targetPath = path.normalize(Directory(target).absolute.path);

    final progress = _logger.progress('Checking licenses on $targetPath');

    final pubspecLock = _tryParsePubspecLock(targetPath);
    if (pubspecLock == null) {
      progress.cancel();
      return ExitCode.usage.code;
    }

    progress.update('Collecting licenses');
    final packagesLicenses = await _collectLicenses(pubspecLock.packages);

    final uniqueLicenseTypes = packagesLicenses.values
        .where((license) => license != null)
        .map((license) => license!.value)
        .toSet();
    progress.complete(
      '''Retrieved ${packagesLicenses.length} licenses of type: ${uniqueLicenseTypes.toList().stringify()}''',
    );

    final forbiddenPackages = Map<String, SpdxLicense>.from(packagesLicenses)
      ..removeWhere((key, value) => !forbidden.contains(value.value));
    final failedPackages = (Map<String, SpdxLicense?>.from(packagesLicenses)
          ..removeWhere((key, value) => value != null))
        .keys;
    _reportResults(
      forbiddenPackages: forbiddenPackages,
      failedPackages: failedPackages,
    );

    // TODO(alestiago): Consider allowed to!
    if (failedPackages.isNotEmpty) {
      return ExitCode.unavailable.code;
    } else if (forbiddenPackages.isNotEmpty) {
      return ExitCode.data.code;
    } else {
      _logger.success('All licenses are allowed.');
      return ExitCode.success.code;
    }
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

  /// Collects the licenses of the given [dependencies].
  ///
  /// Only those dependencies that are direct and hosted in pub.dev are
  /// considered.
  ///
  /// If a license is not found it is reported as `null`. This differs from
  /// [SpdxLicense.$unknown] which is used whenever the author has not specified
  /// a license, or a license is found but is not recognized as a [SpdxLicense].
  Future<Map<String, SpdxLicense?>> _collectLicenses(
    Iterable<PackageDependency> dependencies,
  ) async {
    final licenses = <String, SpdxLicense?>{};
    for (final dependency in dependencies) {
      // ignore: invalid_use_of_protected_member
      final isPubHostedDepedency = dependency.hosted != null;
      final isDirectDependency = dependency.type() == DependencyType.direct;
      if (!isDirectDependency || !isPubHostedDepedency) continue;

      final packageName = dependency.package();
      final license = await _tryParseLicenseFromPub(packageName);

      licenses[packageName] = license;
    }

    return licenses;
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

  /// Reports the results of the licenses check.
  void _reportResults({
    required Map<String, SpdxLicense> forbiddenPackages,
    required Iterable<String> failedPackages,
  }) {
    if (forbiddenPackages.isNotEmpty) {
      _logger.err(
        '''Found ${forbiddenPackages.length} forbidden packages: ${forbiddenPackages.stringify()}''',
      );
    }

    if (failedPackages.isNotEmpty) {
      _logger.err(
        '''Failed to retrieve the license of ${failedPackages.length} packages: ${failedPackages.toList().stringify()}''',
      );
    }
  }
}

extension on Map<String, SpdxLicense> {
  String stringify() {
    final buffer = StringBuffer();
    final entries = this.entries.toList();
    for (final entry in entries) {
      buffer.write('${entry.key} (${entry.value.value})');

      if (entries.length > 1 && entries[entries.length - 2] == entry) {
        buffer.write(' and ');
      } else if (entry == entries.last) {
        buffer.write('.');
      } else {
        buffer.write(', ');
      }
    }
    return buffer.toString();
  }
}

extension on List<String> {
  String stringify() {
    final buffer = StringBuffer();
    for (final entry in this) {
      buffer.write(entry);

      if (length > 1 && this[length - 2] == entry) {
        buffer.write(' and ');
      } else if (entry == last) {
        buffer.write('.');
      } else {
        buffer.write(', ');
      }
    }
    return buffer.toString();
  }
}
