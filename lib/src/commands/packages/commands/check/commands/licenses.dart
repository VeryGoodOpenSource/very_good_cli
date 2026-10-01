import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:collection/collection.dart';
import 'package:mason/mason.dart';
import 'package:meta/meta.dart';
import 'package:package_config/package_config.dart' as package_config;

// We rely on PANA's license detection algorithm to retrieve licenses from
// packages.
//
// This license detection algorithm is not exposed as a public API, so we have
// to import it directly.
//
// See also:
//
// * [PANA's faster license detection GitHub issue](https://github.com/dart-lang/pana/issues/1277)
// ignore: implementation_imports
import 'package:pana/src/license_detection/license_detector.dart' as detector;
import 'package:path/path.dart' as path;
import 'package:very_good_cli/src/pub_license/spdx_license.gen.dart';
import 'package:very_good_cli/src/pubspec/pubspec.dart';
import 'package:very_good_cli/src/pubspec_lock/pubspec_lock.dart';
import 'package:very_good_cli/src/pubspec_workspace/pubspec_workspace.dart';
import 'package:very_good_cli/src/very_good_config/very_good_config.dart';

/// Overrides the [package_config.findPackageConfig] function for testing.
@visibleForTesting
Future<package_config.PackageConfig?> Function(Directory directory)?
findPackageConfigOverride;

/// Overrides the [resolveWorkspaceDependencies] function for testing.
@visibleForTesting
Map<String, PubspecDependencyType>? Function(
  Directory directory, {
  required Logger logger,
})?
resolveWorkspaceOverride;

/// Overrides the [detector.detectLicense] function for testing.
@visibleForTesting
Future<detector.Result> Function(String, double)? detectLicenseOverride;

/// The basename of the pubspec lock file.
@visibleForTesting
const pubspecLockBasename = 'pubspec.lock';

/// The URI for the pub.dev license page for the given [packageName].
@visibleForTesting
Uri pubLicenseUri(String packageName) =>
    Uri.parse('https://pub.dev/packages/$packageName/license');

/// The URI for the very_good_cli license documentation page.
@visibleForTesting
final Uri licenseDocumentationUri = Uri.parse(
  'https://cli.vgv.dev/docs/commands/check_licenses',
);

/// The detection threshold used by [detector.detectLicense].
///
/// This value is used to determine the confidence threshold for detecting
/// licenses. The value should match the default value used by PANA.
///
/// See also:
///
/// * [PANA's default threshold value](https://github.com/dart-lang/pana/blob/b598d45051ba4e028e9021c2aeb9c04e4335de76/lib/src/license.dart#L48)
const _defaultDetectionThreshold = 0.95;

/// Defines a [Map] with dependencies as keys and their licenses as values.
///
/// If a dependency's license failed to be retrieved its license will be `null`.
typedef _DependencyLicenseMap = Map<String, Set<String>?>;

/// Defines a [Map] with banned dependencies as keys and their banned licenses
/// as values.
typedef _BannedDependencyLicenseMap = Map<String, Set<String>>;

/// Options for configuring the `very_good packages check licenses` command.
class PackagesCheckLicensesOptions {
  new _({
    required this.ignoreRetrievalFailures,
    required this.dependencyTypes,
    required this.allowedLicenses,
    required this.forbiddenLicenses,
    required this.skippedPackages,
    required this.reporterOutputFormat,
  });

  /// Parses [ArgResults] into a [PackagesCheckLicensesOptions] instance.
  ///
  /// When [config] is provided, its values are used as defaults for any
  /// option that was not explicitly parsed on the command line.
  factory parse(
    ArgResults argResults, {
    VeryGoodConfig config = VeryGoodConfig.empty,
  }) {
    final licensesConfig = config.packages.check.licenses;

    final ignoreRetrievalFailures = argResults.resolve(
      'ignore-retrieval-failures',
      licensesConfig.ignoreRetrievalFailures,
    );
    final dependencyTypes = argResults.resolve<List<String>>(
      'dependency-type',
      licensesConfig.dependencyType,
    );
    final allowedLicenses = argResults.resolve<List<String>>(
      'allowed',
      licensesConfig.allowed,
    );
    final forbiddenLicenses = argResults.resolve<List<String>>(
      'forbidden',
      licensesConfig.forbidden,
    );
    final skippedPackages = argResults.resolve<List<String>>(
      'skip-packages',
      licensesConfig.skipPackages,
    );
    final reporter = argResults.resolve<String?>(
      'reporter',
      licensesConfig.reporter,
    );

    return PackagesCheckLicensesOptions._(
      ignoreRetrievalFailures: ignoreRetrievalFailures,
      dependencyTypes: dependencyTypes.toSet(),
      allowedLicenses: allowedLicenses.withoutBlanks,
      forbiddenLicenses: forbiddenLicenses.withoutBlanks,
      skippedPackages: skippedPackages.toSet(),
      reporterOutputFormat: ReporterOutputFormat.fromString(reporter),
    );
  }

  /// Whether to disregard licenses that failed to be retrieved.
  final bool ignoreRetrievalFailures;

  /// The type of dependencies to check licenses for.
  final Set<String> dependencyTypes;

  /// The only licenses allowed to be used.
  final List<String> allowedLicenses;

  /// The licenses denied from being used.
  final List<String> forbiddenLicenses;

  /// Packages skipped from having their licenses checked.
  final Set<String> skippedPackages;

  /// The format used to list all licenses.
  final ReporterOutputFormat? reporterOutputFormat;
}

/// {@template packages_check_licenses_command}
/// `very_good packages check licenses` command for checking packages licenses.
/// {@endtemplate}
class PackagesCheckLicensesCommand extends Command<int> {
  /// {@macro packages_check_licenses_command}
  new({Logger? logger}) : _logger = logger ?? Logger() {
    argParser
      ..addFlag(
        'ignore-retrieval-failures',
        help: 'Disregard licenses that failed to be retrieved.',
        negatable: false,
      )
      ..addMultiOption(
        'dependency-type',
        help: 'The type of dependencies to check licenses for.',
        allowed: dependencyTypeAllowedValues,
        allowedHelp: {
          'direct-main': 'Check for direct main dependencies.',
          'direct-dev': 'Check for direct dev dependencies.',
          'transitive': 'Check for transitive dependencies.',
          'direct-overridden': 'Check for direct overridden dependencies.',
        },
        defaultsTo: ['direct-main'],
      )
      ..addMultiOption(
        'allowed',
        help: 'Only allow the use of certain licenses.',
      )
      ..addMultiOption('forbidden', help: 'Deny the use of certain licenses.')
      ..addMultiOption(
        'skip-packages',
        help: 'Skip packages from having their licenses checked.',
      )
      ..addOption(
        'reporter',
        help: 'Lists all licenses.',
        allowed: reporterAllowedValues,
        allowedHelp: {
          'text': 'Lists licenses without a specific format.',
          'csv': 'Lists licenses in a CSV format.',
        },
      );
  }

  final Logger _logger;

  @override
  String get description =>
      "Check packages' licenses in a Dart or Flutter project.";

  @override
  String get name => 'licenses';

  ArgResults get _argResults => argResults!;

  @override
  Future<int> run() async {
    if (_argResults.rest.length > 1) {
      usageException('Too many arguments');
    }

    final target = _argResults.rest.firstOrNull ?? '.';
    final targetPath = path.normalize(Directory(target).absolute.path);
    final targetDirectory = Directory(targetPath);

    final config = VeryGoodConfig.load(targetDirectory, logger: _logger);
    if (config == null) return ExitCode.config.code;

    final options = PackagesCheckLicensesOptions.parse(
      _argResults,
      config: config,
    );
    _validateLicenseOptions(options);

    if (!targetDirectory.existsSync()) {
      _logger.err(
        '''Could not find directory at $targetPath. Specify a valid path to a Dart or Flutter project.''',
      );
      return ExitCode.noInput.code;
    }

    final progress = _logger.progress('Checking licenses on $targetPath');

    final pubspecLockFile = File(path.join(targetPath, pubspecLockBasename));
    if (!pubspecLockFile.existsSync()) {
      progress.cancel();
      _logger.err(_missingPubspecLockMessage(targetDirectory));
      return ExitCode.noInput.code;
    }

    final pubspecLock = _tryParsePubspecLock(pubspecLockFile);
    if (pubspecLock == null) {
      progress.cancel();
      _logger.err('Could not parse $pubspecLockBasename in $targetPath');
      return ExitCode.noInput.code;
    }

    final dependencies = _dependenciesToCheck(
      pubspecLock,
      targetDirectory: targetDirectory,
      options: options,
    );
    if (dependencies.isEmpty) {
      progress.cancel();
      _logger.info(
        '''No hosted dependencies found in $targetPath of type: ${options.dependencyTypes.stringify()}.''',
      );
      return ExitCode.success.code;
    }

    final packageConfig = await _tryFindPackageConfig(targetDirectory);
    if (packageConfig == null) {
      progress.cancel();
      _logger.err(
        '''Could not find a valid package config in $targetPath. Run `dart pub get` or `flutter pub get` to generate one.''',
      );
      return ExitCode.noInput.code;
    }

    final _DependencyLicenseMap licenses;
    try {
      licenses = await _collectLicenses(
        dependencies,
        packageConfig: packageConfig,
        options: options,
        progress: progress,
      );
    } on _LicenseRetrievalFailure catch (failure) {
      progress.cancel();
      _logger.err(failure.message);
      return failure.exitCode.code;
    }

    final bannedDependencies = _bannedDependenciesFor(licenses, options);

    progress.complete(
      _composeReport(
        licenses: licenses,
        bannedDependencies: bannedDependencies,
        reporterOutputFormat: options.reporterOutputFormat,
      ),
    );

    if (bannedDependencies != null) {
      _logger.err(_composeBannedReport(bannedDependencies));
      return ExitCode.config.code;
    }

    return ExitCode.success.code;
  }

  /// Rejects combining allowed and forbidden licenses, and warns about any
  /// license that is not a recognized SPDX identifier.
  void _validateLicenseOptions(PackagesCheckLicensesOptions options) {
    final PackagesCheckLicensesOptions(:allowedLicenses, :forbiddenLicenses) =
        options;

    if (allowedLicenses.isNotEmpty && forbiddenLicenses.isNotEmpty) {
      usageException(
        '''Cannot specify both ${styleItalic.wrap('allowed')} and ${styleItalic.wrap('forbidden')} options.''',
      );
    }

    final invalidLicenses = _invalidLicenses([
      ...allowedLicenses,
      ...forbiddenLicenses,
    ]);
    if (invalidLicenses.isEmpty) return;

    final documentationLink = link(
      uri: licenseDocumentationUri,
      message: 'documentation',
    );
    _logger.warn(
      '''Some licenses failed to be recognized: ${invalidLicenses.stringify()}. Refer to the $documentationLink for a list of valid licenses.''',
    );
  }

  /// The hosted dependencies in [pubspecLock] whose licenses should be
  /// checked according to [options].
  ///
  /// When [targetDirectory] is part of a Pub workspace, dependency types are
  /// resolved from the workspace instead of the [pubspecLock].
  List<PubspecLockPackage> _dependenciesToCheck(
    PubspecLock pubspecLock, {
    required Directory targetDirectory,
    required PackagesCheckLicensesOptions options,
  }) {
    final resolveWorkspace =
        resolveWorkspaceOverride ?? resolveWorkspaceDependencies;
    final workspaceDeps = resolveWorkspace(targetDirectory, logger: _logger);

    PubspecDependencyType typeOf(PubspecLockPackage dependency) =>
        workspaceDeps == null
        ? dependency.type
        : workspaceDeps[dependency.name] ?? PubspecDependencyType.transitive;

    return pubspecLock.packages
        .where(
          (dependency) =>
              dependency.isPubHosted &&
              !options.skippedPackages.contains(dependency.name) &&
              options.dependencyTypes.contains(typeOf(dependency).optionName),
        )
        .toList();
  }

  /// Retrieves the licenses of every dependency in [dependencies].
  ///
  /// Throws a [_LicenseRetrievalFailure] when a license fails to be retrieved,
  /// unless [PackagesCheckLicensesOptions.ignoreRetrievalFailures] is set, in
  /// which case the failure is logged and the license is reported as unknown.
  Future<_DependencyLicenseMap> _collectLicenses(
    List<PubspecLockPackage> dependencies, {
    required package_config.PackageConfig packageConfig,
    required PackagesCheckLicensesOptions options,
    required Progress progress,
  }) async {
    final licenses = <String, Set<String>?>{};
    final detectLicense = detectLicenseOverride ?? detector.detectLicense;
    final packageWord = dependencies.length == 1 ? 'package' : 'packages';

    for (final PubspecLockPackage(:name) in dependencies) {
      progress.update(
        '''Collecting licenses from ${licenses.length + 1} out of ${dependencies.length} $packageWord''',
      );

      try {
        licenses[name] = await _retrieveLicenses(
          name,
          packageConfig: packageConfig,
          detectLicense: detectLicense,
        );
      } on _LicenseRetrievalFailure catch (failure) {
        if (!options.ignoreRetrievalFailures) rethrow;

        _logger.err('\n${failure.message}');
        licenses[name] = {SpdxLicense.$unknown.value};
      }
    }

    return licenses;
  }
}

/// {@template license_retrieval_failure}
/// Signals that the license of a dependency failed to be retrieved.
/// {@endtemplate}
class _LicenseRetrievalFailure implements Exception {
  /// {@macro license_retrieval_failure}
  const new(this.message, this.exitCode);

  /// A human friendly description of the failure.
  final String message;

  /// The exit code to return when the failure is not ignored.
  final ExitCode exitCode;
}

/// Retrieves the licenses of the package named [dependencyName] from its
/// cached `LICENSE` file.
///
/// Returns an unknown license when the package has no `LICENSE` file, or when
/// no license is detected in it.
///
/// Throws a [_LicenseRetrievalFailure] when the cached package cannot be found
/// or its license fails to be detected.
Future<Set<String>> _retrieveLicenses(
  String dependencyName, {
  required package_config.PackageConfig packageConfig,
  required Future<detector.Result> Function(String, double) detectLicense,
}) async {
  final cachePackageEntry = packageConfig.packages.firstWhereOrNull(
    (package) => package.name == dependencyName,
  );
  if (cachePackageEntry == null) {
    throw _LicenseRetrievalFailure(
      '''[$dependencyName] Could not find cached package path. Consider running `dart pub get` or `flutter pub get` to generate a new `package_config.json`.''',
      ExitCode.noInput,
    );
  }

  final packagePath = path.normalize(cachePackageEntry.root.toFilePath());
  if (!Directory(packagePath).existsSync()) {
    throw _LicenseRetrievalFailure(
      '''[$dependencyName] Could not find package directory at $packagePath.''',
      ExitCode.noInput,
    );
  }

  final licenseFile = File(path.join(packagePath, 'LICENSE'));
  if (!licenseFile.existsSync()) return {SpdxLicense.$unknown.value};

  final licenseFileContent = licenseFile.readAsStringSync();

  final detector.Result detectorResult;
  try {
    detectorResult = await detectLicense(
      licenseFileContent,
      _defaultDetectionThreshold,
    );
  } on Exception catch (e) {
    throw _LicenseRetrievalFailure(
      '''[$dependencyName] Failed to detect license from $packagePath: $e''',
      ExitCode.software,
    );
  }

  final rawLicense = detectorResult.matches
      // Accessing license is necessary to get the identifier of the license
      // ignore: invalid_use_of_visible_for_testing_member
      .map((match) => match.license.identifier)
      .toSet();
  return {
    ...rawLicense,
    // If there are no matches, we add the unknown license
    if (rawLicense.isEmpty) SpdxLicense.$unknown.value,
  };
}

/// The error message reported when the `pubspec.lock` file is missing from
/// [targetDirectory].
String _missingPubspecLockMessage(Directory targetDirectory) {
  final targetPath = targetDirectory.path;
  return declaresWorkspaceResolution(targetDirectory)
      ? 'Could not find a $pubspecLockBasename in $targetPath.\n'
            'This package resolves as part of a Pub workspace. '
            'Run the command from the workspace root instead.'
      : 'Could not find a $pubspecLockBasename in $targetPath';
}

/// Attempts to parse a [PubspecLock] file in the given [path].
///
/// If [pubspecLockFile] is not readable or fails to be parsed, `null` is
/// returned.
PubspecLock? _tryParsePubspecLock(File pubspecLockFile) {
  if (pubspecLockFile.existsSync()) {
    final content = pubspecLockFile.readAsStringSync();
    try {
      return PubspecLock.fromString(content);
    } on Exception catch (_) {}
  }

  return null;
}

/// Attempts to find a [package_config.PackageConfig] using
/// [package_config.findPackageConfig].
///
/// If [package_config.findPackageConfig] fails to find a package config `null`
/// is returned.
Future<package_config.PackageConfig?> _tryFindPackageConfig(
  Directory directory,
) async {
  try {
    final findPackageConfig =
        findPackageConfigOverride ?? package_config.findPackageConfig;
    return await findPackageConfig(directory);
  } on Exception catch (_) {
    return null;
  }
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

/// Returns a [Map] of banned dependencies and their banned licenses.
///
/// The [Map] is lazily initialized, if no dependencies are banned `null` is
/// returned.
_BannedDependencyLicenseMap? _bannedDependencies({
  required _DependencyLicenseMap licenses,
  required bool Function(String license) isAllowed,
}) {
  _BannedDependencyLicenseMap? bannedDependencies;
  for (final dependency in licenses.entries) {
    final name = dependency.key;
    final license = dependency.value;
    if (license == null) continue;

    for (final licenseType in license) {
      if (isAllowed(licenseType)) continue;

      bannedDependencies ??= <String, Set<String>>{};
      bannedDependencies.putIfAbsent(name, () => <String>{});
      bannedDependencies[name]!.add(licenseType);
    }
  }

  return bannedDependencies;
}

/// Returns the banned dependencies in [licenses] according to the allowed or
/// forbidden licenses in [options].
///
/// Returns `null` when neither allowed nor forbidden licenses are specified,
/// or when no dependency is banned.
_BannedDependencyLicenseMap? _bannedDependenciesFor(
  _DependencyLicenseMap licenses,
  PackagesCheckLicensesOptions options,
) {
  final PackagesCheckLicensesOptions(:allowedLicenses, :forbiddenLicenses) =
      options;

  if (allowedLicenses.isNotEmpty) {
    return _bannedDependencies(
      licenses: licenses,
      isAllowed: allowedLicenses.contains,
    );
  }
  if (forbiddenLicenses.isNotEmpty) {
    return _bannedDependencies(
      licenses: licenses,
      isAllowed: (license) => !forbiddenLicenses.contains(license),
    );
  }
  return null;
}

/// Composes a human friendly [String] to report the result of the retrieved
/// licenses.
///
/// If [bannedDependencies] is provided those banned licenses will be
/// highlighted in red.
String _composeReport({
  required _DependencyLicenseMap licenses,
  required _BannedDependencyLicenseMap? bannedDependencies,
  ReporterOutputFormat? reporterOutputFormat,
}) {
  final bannedLicenseTypes =
      bannedDependencies?.values.expand((licenses) => licenses).toSet() ??
      const <String>{};

  final licenseTypes = licenses.values.nonNulls
      .expand((licenses) => licenses)
      .toList();
  final totalLicenseCount = licenseTypes.length;

  final licenseCount = <String, int>{};
  for (final license in licenseTypes) {
    licenseCount.update(license, (value) => value + 1, ifAbsent: () => 1);
  }

  final formattedLicenseTypes = licenseCount.entries.map((entry) {
    final MapEntry(key: license, value: count) = entry;
    final colorWrapper = bannedLicenseTypes.contains(license)
        ? red.wrap
        : green.wrap;
    final formattedCount = darkGray.wrap('($count)');

    return '${colorWrapper(license)} $formattedCount';
  });

  final licenseWord = totalLicenseCount == 1 ? 'license' : 'licenses';
  final packageWord = licenses.length == 1 ? 'package' : 'packages';
  final suffix = formattedLicenseTypes.isEmpty
      ? ''
      : ' of type: ${formattedLicenseTypes.toList().stringify()}';
  final listing = _composeLicenseListing(licenses, reporterOutputFormat);

  return '''Retrieved $totalLicenseCount $licenseWord from ${licenses.length} $packageWord$suffix.$listing''';
}

/// Lists every license of every dependency in [licenses] using
/// [reporterOutputFormat], one per line.
///
/// Returns an empty [String] when no [reporterOutputFormat] is given.
String _composeLicenseListing(
  _DependencyLicenseMap licenses,
  ReporterOutputFormat? reporterOutputFormat,
) {
  if (reporterOutputFormat == null) return '';

  final listing = StringBuffer('\n');
  for (final MapEntry(key: packageName, value: dependencyLicenses)
      in licenses.entries) {
    for (final licenseName in dependencyLicenses ?? const <String>{}) {
      listing.writeln(
        reporterOutputFormat.formatLicense(
          packageName: packageName,
          licenseName: licenseName,
        ),
      );
    }
  }
  return listing.toString();
}

String _composeBannedReport(_BannedDependencyLicenseMap bannedDependencies) {
  final bannedDependenciesList = bannedDependencies.entries.fold(<String>[], (
    previousValue,
    element,
  ) {
    final dependencyName = element.key;
    final dependencyLicenses = element.value;
    final hyperlink = link(
      uri: pubLicenseUri(dependencyName),
      message: dependencyLicenses.toList().stringify(),
    );

    final text = '$dependencyName ($hyperlink)';
    return previousValue..add(text);
  });
  final bannedLicenseTypes = bannedDependencies.values.fold(<String>{}, (
    previousValue,
    licenses,
  ) {
    if (licenses.isEmpty) return previousValue;
    return previousValue..addAll(licenses);
  });

  final prefix = bannedDependencies.length == 1
      ? 'dependency has'
      : 'dependencies have';
  final suffix = bannedLicenseTypes.length == 1
      ? 'a banned license'
      : 'banned licenses';

  return '''${bannedDependencies.length} $prefix $suffix: ${bannedDependenciesList.stringify()}.''';
}

extension on Iterable<Object> {
  String stringify() {
    if (isEmpty) return '';
    if (length == 1) return first.toString();
    return '${take(length - 1).join(', ')} and $last';
  }
}

extension on PubspecDependencyType {
  /// The `--dependency-type` option value that selects this dependency type.
  String get optionName => switch (this) {
    PubspecDependencyType.directMain => 'direct-main',
    PubspecDependencyType.directDev => 'direct-dev',
    PubspecDependencyType.transitive => 'transitive',
    PubspecDependencyType.directOverridden => 'direct-overridden',
  };
}

extension on List<String> {
  /// The licenses that are not blank.
  List<String> get withoutBlanks =>
      where((license) => license.trim().isNotEmpty).toList();
}

/// Format type for listing all licenses via --reporter option.
enum ReporterOutputFormat {
  /// List all licenses separated by a dash.
  ///
  /// Example: very_good_cli - MIT
  text,

  /// List all licenses in a CSV format.
  ///
  /// Example: very_good_cli,MIT
  csv;

  /// Convenience parsing method from user input.
  ///
  /// Return desired format for valid inputs
  ///        null for invalid inputs or unspecified input.
  static ReporterOutputFormat? fromString(String? value) {
    return switch (value) {
      'text' => text,
      'csv' => csv,
      _ => null,
    };
  }

  /// Stringify the package with it's license into the desired format
  String formatLicense({
    required String packageName,
    required String licenseName,
  }) {
    return switch (this) {
      text => '$packageName - $licenseName',
      csv => '$packageName,$licenseName',
    };
  }
}
