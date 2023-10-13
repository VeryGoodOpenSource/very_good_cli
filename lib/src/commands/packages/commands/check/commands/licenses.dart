import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:mason/mason.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import 'package:pubspec_lock/pubspec_lock.dart';
import 'package:very_good_cli/src/pub_license/pub_license.dart';
import 'package:very_good_cli/src/pub_license/spdx_license.gen.dart';

/// The basename of the pubspec lock file.
@visibleForTesting
const pubspecLockBasename = 'pubspec.lock';

/// The URI for the pub.dev license page for the given [packageName].
@visibleForTesting
Uri pubLicenseUri(String packageName) =>
    Uri.parse('https://pub.dev/packages/$packageName/license');

/// {@template packages_check_licenses_command}
/// `very_good packages check licenses` command for checking packages licenses.
/// {@endtemplate}
class PackagesCheckLicensesCommand extends Command<int> {
  /// {@macro packages_check_licenses_command}
  PackagesCheckLicensesCommand({
    Logger? logger,
    PubLicense? pubLicense,
  })  : _logger = logger ?? Logger(),
        _pubLicense = pubLicense ?? PubLicense() {
    argParser
      ..addFlag(
        'ignore-failures',
        help: 'Ignore any license that failed to be retrieved.',
        negatable: false,
      )
      ..addMultiOption(
        'dependency-type',
        help: 'The type of dependencies to check licenses for.',
        allowed: [
          'direct-main',
          'direct-dev',
          'transitive',
        ],
        allowedHelp: {
          'direct-main': 'Check for direct main dependencies.',
          'direct-dev': 'Check for direct dev dependencies.',
          'transitive': 'Check for transitive dependencies.',
        },
        defaultsTo: ['direct-main'],
      )
      ..addMultiOption(
        'allowed',
        help: 'Whitelist of allowed licenses.',
      )
      ..addMultiOption(
        'forbidden',
        help: 'Block-list of not allowed licenses.',
      );
  }

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
    if (_argResults.rest.length > 1) {
      usageException('Too many arguments');
    }

    final ignoreFailures = _argResults['ignore-failures'] as bool;
    final dependencyTypes = _argResults['dependency-type'] as List<String>;
    final allowedLicenses = _argResults['allowed'] as List<String>;
    final blockedLicenses = _argResults['forbidden'] as List<String>;

    if (allowedLicenses.isNotEmpty && blockedLicenses.isNotEmpty) {
      usageException(
        '''Cannot specify both ${styleItalic.wrap('allowed')} and ${styleItalic.wrap('forbidden')} options.''',
      );
    }

    final invalidLicenses = _invalidLicenses(allowedLicenses);
    if (invalidLicenses.isNotEmpty) {
      _logger.warn(
        '''Some ${styleItalic.wrap('allowed')} licenses failed to be recognized: ${invalidLicenses.stringify()}. Refer to the documentation for a list of valid licenses.''',
      );
    }

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

    final filteredDependencies = pubspecLock.packages.where((dependency) {
      // ignore: invalid_use_of_protected_member
      final isPubHosted = dependency.hosted != null;
      if (!isPubHosted) return false;

      final dependencyType = dependency.type();
      return (dependencyTypes.contains('direct-main') &&
              dependencyType == DependencyType.direct) ||
          (dependencyTypes.contains('direct-dev') &&
              dependencyType == DependencyType.development) ||
          (dependencyTypes.contains('transitive') &&
              dependencyType == DependencyType.transitive);
    });

    if (filteredDependencies.isEmpty) {
      progress.cancel();
      _logger.err('No hosted direct dependencies found in $targetPath');
      return ExitCode.usage.code;
    }

    final licenses = <String, Set<String>?>{};
    for (final dependency in filteredDependencies) {
      progress.update(
        'Collecting licenses of ${licenses.length}/${filteredDependencies.length} packages.',
      );

      final dependencyName = dependency.package();
      Set<String>? rawLicense;
      try {
        rawLicense = await _pubLicense.getLicense(dependencyName);
      } on PubLicenseException catch (e) {
        final errorMessage = '[$dependencyName] ${e.message}';
        if (!ignoreFailures) {
          progress.cancel();
          _logger.err(errorMessage);
          return ExitCode.unavailable.code;
        }

        _logger.err('\n$errorMessage');
      } catch (e) {
        final errorMessage =
            '[$dependencyName] Unexpected failure with error: $e';
        if (!ignoreFailures) {
          progress.cancel();
          _logger.err(errorMessage);
          return ExitCode.software.code;
        }

        _logger.err('\n$errorMessage');
      } finally {
        licenses[dependencyName] = rawLicense;
      }
    }

    final allowedLicenseSet = allowedLicenses.toSet();
    final bannedDependencies = <String, Set<String>>{};
    if (allowedLicenseSet.isNotEmpty) {
      for (final dependency in licenses.entries) {
        final name = dependency.key;
        final license = dependency.value;
        if (license == null) continue;

        final bannedLicenses = license.difference(allowedLicenseSet);
        if (bannedLicenses.isNotEmpty) {
          bannedDependencies[name] = bannedLicenses;
        }
      }
    }

    progress.complete(
      _composeReport(
        licenses: licenses,
        bannedDependencies: bannedDependencies,
      ),
    );

    if (bannedDependencies.isNotEmpty) {
      _logger.err(_composeBannedReport(bannedDependencies));
      return ExitCode.config.code;
    }

    return ExitCode.success.code;
  }
}

/// Attempts to parse a [PubspecLock] file in the given [path].
///
/// If [pubspecLockFile] is not readable or fails to be parsed, `null` is
/// returned.
PubspecLock? _tryParsePubspecLock(File pubspecLockFile) {
  try {
    return pubspecLockFile.readAsStringSync().loadPubspecLockFromYaml();
  } catch (e) {
    return null;
  }
}

/// Composes a human friendly [String] to report the result of the retrieved
/// licenses.
String _composeReport({
  required Map<String, Set<String>?> licenses,
  required Map<String, Set<String>> bannedDependencies,
}) {
  final bannedLicenseTypes =
      bannedDependencies.values.fold(<String>{}, (previousValue, licenses) {
    if (licenses.isEmpty) return previousValue;
    return previousValue..addAll(licenses);
  });
  final licenseTypes =
      licenses.values.fold(<String>{}, (previousValue, licenses) {
    if (licenses == null) return previousValue;
    return previousValue..addAll(licenses);
  });
  final coloredLicenseTypes = licenseTypes.map((license) {
    if (bannedLicenseTypes.contains(license)) {
      return red.wrap(license)!;
    }
    return green.wrap(license)!;
  });

  final licenseCount = licenses.values.fold<int>(0, (previousValue, element) {
    if (element == null) return previousValue;
    return previousValue + element.length;
  });

  final licenseWord = licenseCount == 1 ? 'license' : 'licenses';
  final packageWord = licenses.length == 1 ? 'package' : 'packages';
  final suffix = coloredLicenseTypes.isEmpty
      ? ''
      : ' of type: ${coloredLicenseTypes.toList().stringify()}';

  return '''Retrieved $licenseCount $licenseWord from ${licenses.length} $packageWord$suffix.''';
}

String _composeBannedReport(Map<String, Set<String>> bannedDependencies) {
  final bannedDependenciesList = bannedDependencies.entries.fold(
    <String>[],
    (previousValue, element) {
      final dependencyName = element.key;
      final dependencyLicenses = element.value;

      final text = '$dependencyName (${link(
        uri: pubLicenseUri(dependencyName),
        message: dependencyLicenses.toList().stringify(),
      )})';
      return previousValue..add(text);
    },
  );
  final bannedLicenseTypes =
      bannedDependencies.values.fold(<String>{}, (previousValue, licenses) {
    if (licenses.isEmpty) return previousValue;
    return previousValue..addAll(licenses);
  });

  final prefix =
      bannedDependencies.length == 1 ? 'dependency has' : 'dependencies have';
  final suffix =
      bannedLicenseTypes.length == 1 ? 'a banned license' : 'banned licenses';

  return '''${bannedDependencies.length} $prefix $suffix: ${bannedDependenciesList.stringify()}.''';
}

/// Verifies that all [licenses] are valid license inputs.
///
/// Valid license inputs are:
/// - [SpdxLicense] values.
///
/// Returns a [List] of invalid licenses, if all licenses are valid the list
/// will be empty.
List<String> _invalidLicenses(List<String> licenses) {
  final invalidLicenses = <String>[];
  for (final license in licenses) {
    final parsedLicense = SpdxLicense.tryParse(license);
    if (parsedLicense == null) {
      invalidLicenses.add(license);
    }
  }

  return invalidLicenses;
}

extension on List<Object> {
  String stringify() {
    if (isEmpty) return '';
    if (length == 1) return first.toString();
    final last = removeLast();
    return '${join(', ')} and $last';
  }
}
