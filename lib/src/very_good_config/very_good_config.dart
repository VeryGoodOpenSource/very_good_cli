/// Support for loading Very Good CLI configuration from a
/// `very_good.yaml` file.
///
/// The configuration file lives at the root of a project and allows developers
/// to persist frequently used CLI parameters so that running the CLI locally
/// produces the same results as running it on CI.
library;

import 'dart:io';
import 'package:args/args.dart';
import 'package:checked_yaml/checked_yaml.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as path;

part 'very_good_config.g.dart';

/// The default name of the Very Good CLI configuration file.
const veryGoodConfigFileName = 'very_good.yaml';

/// Extension that resolves argument values against `very_good.yaml`
/// configuration values.
extension ArgResultsResolver on ArgResults {
  /// Resolves the value for the argument named [name] against a
  /// `very_good.yaml` configuration value.
  ///
  /// Resolution follows a fixed precedence, from highest to lowest:
  ///
  /// 1. A command line argument that was explicitly parsed.
  /// 2. [configValue], the corresponding value from the configuration file.
  /// 3. [fallbackValue], used when neither the command line nor the
  ///    configuration provide a value (typically the argument's command line
  ///    default).
  T resolve<T>(String name, T? configValue, {T? fallbackValue}) {
    final value = configValue != null && !wasParsed(name)
        ? configValue
        : this[name] as T?;
    return (value ?? fallbackValue) as T;
  }
}

/// {@template very_good_config_parse_exception}
/// Thrown when a [VeryGoodConfig] fails to parse.
/// {@endtemplate}
class VeryGoodConfigParseException implements Exception {
  /// {@macro very_good_config_parse_exception}
  const VeryGoodConfigParseException(this.message);

  /// A human readable description of the parse failure.
  final String message;

  @override
  String toString() => 'VeryGoodConfigParseException: $message';
}

/// {@template very_good_config}
/// A representation of a `very_good.yaml` configuration file.
///
/// The configuration file may declare per-command sections whose values
/// are used as defaults whenever the corresponding CLI flag is not
/// explicitly passed at the command line.
/// {@endtemplate}
@JsonSerializable(
  anyMap: true,
  checked: true,
  createToJson: false,
  disallowUnrecognizedKeys: true,
  fieldRename: FieldRename.snake,
)
class VeryGoodConfig extends Equatable {
  /// {@macro very_good_config}
  const VeryGoodConfig({
    this.test = const VeryGoodTestConfig(),
    this.create = const VeryGoodCreateConfig(),
    this.dart = const VeryGoodDartConfig(),
    this.packages = const VeryGoodPackagesConfig(),
  });

  /// Creates a [VeryGoodConfig] from a decoded YAML/JSON [json] map.
  factory VeryGoodConfig.fromJson(Map<dynamic, dynamic> json) {
    return _$VeryGoodConfigFromJson(json);
  }

  /// Parses a [VeryGoodConfig] from a YAML [content] string.
  ///
  /// An empty or `null` YAML document yields [VeryGoodConfig.empty].
  ///
  /// When provided, [sourceUrl] is used to enrich error messages with the
  /// location the [content] originated from.
  ///
  /// Throws a [VeryGoodConfigParseException] if [content] is not a valid
  /// YAML map or if any known section is malformed.
  factory VeryGoodConfig.fromString(String content, {Uri? sourceUrl}) {
    try {
      return checkedYamlDecode(
        content,
        (json) => VeryGoodConfig.fromJson(json ?? const {}),
        allowNull: true,
        sourceUrl: sourceUrl,
      );
    } on ParsedYamlException catch (e) {
      throw VeryGoodConfigParseException(e.formattedMessage ?? e.message);
    }
  }

  /// Loads the closest [VeryGoodConfig] by searching [directory] and each of
  /// its ancestors, from the innermost directory outward.
  ///
  /// Returns [VeryGoodConfig.empty] when no configuration file is found.
  ///
  /// On a parse failure, logs a formatted error via [logger] and returns
  /// `null`, signalling that the caller should exit with a config error.
  static VeryGoodConfig? load(Directory directory, {required Logger logger}) {
    try {
      var current = directory.absolute;
      while (true) {
        final config = _loadFromDirectory(current);
        if (config != null) return config;
        final parent = current.parent;
        if (parent.path == current.path) return VeryGoodConfig.empty;
        current = parent;
      }
    } on VeryGoodConfigParseException catch (e) {
      logger.err(
        'Could not read `$veryGoodConfigFileName`.\n${e.message}',
      );
      return null;
    }
  }

  /// Loads a [VeryGoodConfig] from the configuration file directly inside
  /// [directory], or `null` when the file does not exist.
  ///
  /// Throws a [VeryGoodConfigParseException] when the file exists but cannot be
  /// parsed.
  static VeryGoodConfig? _loadFromDirectory(Directory directory) {
    final file = File(path.join(directory.path, veryGoodConfigFileName));
    if (!file.existsSync()) return null;
    return VeryGoodConfig.fromString(
      file.readAsStringSync(),
      sourceUrl: file.uri,
    );
  }

  /// An empty [VeryGoodConfig] with no values set.
  static const VeryGoodConfig empty = VeryGoodConfig();

  /// Configuration values for the `very_good test` command.
  final VeryGoodTestConfig test;

  /// Configuration values for the `very_good create` command.
  final VeryGoodCreateConfig create;

  /// Configuration values for the `very_good dart test` command.
  final VeryGoodDartConfig dart;

  /// Configuration values for the `very_good packages` command.
  final VeryGoodPackagesConfig packages;

  @override
  List<Object?> get props => [test, create, dart, packages];
}

/// {@template very_good_create_config}
/// Configuration values that customize the defaults of the
/// `very_good create` command and its subcommands.
///
/// Any field that is left as `null` retains its CLI default.
/// {@endtemplate}
@JsonSerializable(
  anyMap: true,
  checked: true,
  createToJson: false,
  disallowUnrecognizedKeys: true,
  fieldRename: FieldRename.snake,
)
class VeryGoodCreateConfig extends Equatable {
  /// {@macro very_good_create_config}
  const VeryGoodCreateConfig({
    this.description,
    this.orgName,
    this.publishable,
    this.template,
    this.workspace,
  });

  /// Creates a [VeryGoodCreateConfig] from a decoded YAML/JSON [json] map.
  factory VeryGoodCreateConfig.fromJson(Map<dynamic, dynamic> json) {
    return _$VeryGoodCreateConfigFromJson(json);
  }

  /// The description for the generated project.
  final String? description;

  /// The organization for the generated project.
  final String? orgName;

  /// Whether the generated project is intended to be published.
  final bool? publishable;

  /// The template used to generate the project.
  final String? template;

  /// Whether the generated project should resolve its dependencies from a
  /// parent Pub workspace.
  final bool? workspace;

  @override
  List<Object?> get props => [
    description,
    orgName,
    publishable,
    template,
    workspace,
  ];
}

/// {@template very_good_test_config}
/// Configuration values that customize the defaults of the
/// `very_good test` command.
///
/// Any field that is left as `null` retains its CLI default.
/// {@endtemplate}
@JsonSerializable(
  anyMap: true,
  checked: true,
  createToJson: false,
  disallowUnrecognizedKeys: true,
  fieldRename: FieldRename.snake,
)
class VeryGoodTestConfig extends Equatable {
  /// {@macro very_good_test_config}
  const VeryGoodTestConfig({
    this.coverage,
    this.optimization,
    this.concurrency,
    this.tags,
    this.excludeCoverage,
    this.excludeTags,
    this.minCoverage,
    this.showUncovered,
    this.collectCoverageFrom,
    this.updateGoldens,
    this.failFast,
    this.dartDefine,
    this.dartDefineFromFile,
    this.platform,
    this.reportOn,
    this.runSkipped,
    this.flavor,
    this.timeout,
    this.fileReporter,
  });

  /// Creates a [VeryGoodTestConfig] from a decoded YAML/JSON [json] map.
  factory VeryGoodTestConfig.fromJson(Map<dynamic, dynamic> json) {
    return _$VeryGoodTestConfigFromJson(json);
  }

  /// Whether to collect coverage information.
  final bool? coverage;

  /// Whether to apply optimizations for test performance.
  final bool? optimization;

  /// The number of concurrent test suites run.
  @JsonKey(fromJson: _concurrency)
  final String? concurrency;

  /// Run only tests associated with the specified tags.
  final String? tags;

  /// A glob which will be used to exclude files that match from the coverage.
  final String? excludeCoverage;

  /// Run only tests that do not have the specified tags.
  final String? excludeTags;

  /// The minimum coverage percentage enforced.
  @JsonKey(fromJson: _minCoverage)
  final String? minCoverage;

  /// Whether to show uncovered lines when coverage is below 100%.
  final bool? showUncovered;

  /// Whether to collect coverage from imported files only or all files.
  @JsonKey(fromJson: _collectCoverageFrom)
  final String? collectCoverageFrom;

  /// Whether `matchesGoldenFile()` calls should update the golden files.
  final bool? updateGoldens;

  /// Whether to stop running tests after the first failure.
  final bool? failFast;

  /// Additional `--dart-define` values.
  @JsonKey(fromJson: _stringList)
  final List<String>? dartDefine;

  /// Paths of `.json` or `.env` files with `--dart-define-from-file` values.
  @JsonKey(fromJson: _stringList)
  final List<String>? dartDefineFromFile;

  /// The platform to run tests on (e.g. `chrome`, `vm`, `android`, `ios`).
  final String? platform;

  /// Optional file paths to report coverage information to.
  @JsonKey(fromJson: _stringList)
  final List<String>? reportOn;

  /// Whether to run skipped tests instead of skipping them.
  final bool? runSkipped;

  /// The flavor to build for testing.
  final String? flavor;

  /// Maximum seconds to let tests run before killing the process.
  @JsonKey(fromJson: _timeout)
  final String? timeout;

  /// Additional reporter that writes test results to a file, expressed as
  /// `<name>:<path>` (e.g. `json:reports/tests.json`).
  final String? fileReporter;

  @override
  List<Object?> get props => [
    coverage,
    optimization,
    concurrency,
    tags,
    excludeCoverage,
    excludeTags,
    minCoverage,
    showUncovered,
    collectCoverageFrom,
    updateGoldens,
    failFast,
    dartDefine,
    dartDefineFromFile,
    platform,
    reportOn,
    runSkipped,
    flavor,
    timeout,
    fileReporter,
  ];
}

/// {@template very_good_dart_config}
/// Configuration values that customize the defaults of the
/// `very_good dart test` command.
///
/// Any field that is left as `null` retains its CLI default.
/// {@endtemplate}
@JsonSerializable(
  anyMap: true,
  checked: true,
  createToJson: false,
  disallowUnrecognizedKeys: true,
  fieldRename: FieldRename.snake,
)
class VeryGoodDartConfig extends Equatable {
  /// {@macro very_good_dart_config}
  const VeryGoodDartConfig({this.test = const VeryGoodDartTestConfig()});

  /// Creates a [VeryGoodDartConfig] from a decoded YAML/JSON [json] map.
  factory VeryGoodDartConfig.fromJson(Map<dynamic, dynamic> json) {
    return _$VeryGoodDartConfigFromJson(json);
  }

  /// Configuration values for the `very_good dart test` subcommand.
  final VeryGoodDartTestConfig test;

  @override
  List<Object?> get props => [test];
}

/// {@template very_good_dart_test_config}
/// Configuration values that customize the defaults of the
/// `very_good dart test` command.
///
/// Any field that is left as `null` retains its CLI default.
/// {@endtemplate}
@JsonSerializable(
  anyMap: true,
  checked: true,
  createToJson: false,
  disallowUnrecognizedKeys: true,
  fieldRename: FieldRename.snake,
)
class VeryGoodDartTestConfig extends Equatable {
  /// {@macro very_good_dart_test_config}
  const VeryGoodDartTestConfig({
    this.coverage,
    this.optimization,
    this.concurrency,
    this.tags,
    this.excludeCoverage,
    this.excludeTags,
    this.minCoverage,
    this.showUncovered,
    this.collectCoverageFrom,
    this.failFast,
    this.platform,
    this.reportOn,
    this.runSkipped,
    this.checkIgnore,
    this.fileReporter,
  });

  /// Creates a [VeryGoodDartTestConfig] from a decoded YAML/JSON [json] map.
  factory VeryGoodDartTestConfig.fromJson(Map<dynamic, dynamic> json) {
    return _$VeryGoodDartTestConfigFromJson(json);
  }

  /// Whether to collect coverage information.
  final bool? coverage;

  /// Whether to apply optimizations for test performance.
  final bool? optimization;

  /// The number of concurrent test suites run.
  @JsonKey(fromJson: _concurrency)
  final String? concurrency;

  /// Run only tests associated with the specified tags.
  final String? tags;

  /// A glob which will be used to exclude files that match from the coverage.
  final String? excludeCoverage;

  /// Run only tests that do not have the specified tags.
  final String? excludeTags;

  /// The minimum coverage percentage enforced.
  @JsonKey(fromJson: _minCoverage)
  final String? minCoverage;

  /// Whether to show uncovered lines when coverage is below 100%.
  final bool? showUncovered;

  /// Whether to collect coverage from imported files only or all files.
  @JsonKey(fromJson: _collectCoverageFrom)
  final String? collectCoverageFrom;

  /// Whether to stop running tests after the first failure.
  final bool? failFast;

  /// The platform to run tests on (e.g. `chrome`, `vm`).
  final String? platform;

  /// Optional file paths to report coverage information to.
  @JsonKey(fromJson: _stringList)
  final List<String>? reportOn;

  /// Whether to run skipped tests instead of skipping them.
  final bool? runSkipped;

  /// Whether to check for and respect coverage ignore comments.
  final bool? checkIgnore;

  /// Additional reporter that writes test results to a file, expressed as
  /// `<name>:<path>` (e.g. `json:reports/tests.json`).
  final String? fileReporter;

  @override
  List<Object?> get props => [
    coverage,
    optimization,
    concurrency,
    tags,
    excludeCoverage,
    excludeTags,
    minCoverage,
    showUncovered,
    collectCoverageFrom,
    failFast,
    platform,
    reportOn,
    runSkipped,
    checkIgnore,
    fileReporter,
  ];
}

/// {@template very_good_packages_config}
/// Configuration values that customize the defaults of the
/// `very_good packages` command.
/// {@endtemplate}
@JsonSerializable(
  anyMap: true,
  checked: true,
  createToJson: false,
  disallowUnrecognizedKeys: true,
  fieldRename: FieldRename.snake,
)
class VeryGoodPackagesConfig extends Equatable {
  /// {@macro very_good_packages_config}
  const VeryGoodPackagesConfig({
    this.get = const VeryGoodPackagesGetConfig(),
    this.check = const VeryGoodPackagesCheckConfig(),
  });

  /// Creates a [VeryGoodPackagesConfig] from a decoded YAML/JSON [json] map.
  factory VeryGoodPackagesConfig.fromJson(Map<dynamic, dynamic> json) {
    return _$VeryGoodPackagesConfigFromJson(json);
  }

  /// Configuration values for the `very_good packages get` command.
  final VeryGoodPackagesGetConfig get;

  /// Configuration values for the `very_good packages check` command.
  final VeryGoodPackagesCheckConfig check;

  @override
  List<Object?> get props => [get, check];
}

/// {@template very_good_packages_get_config}
/// Configuration values that customize the defaults of the
/// `very_good packages get` command.
///
/// Any field that is left as `null` retains its CLI default.
/// {@endtemplate}
@JsonSerializable(
  anyMap: true,
  checked: true,
  createToJson: false,
  disallowUnrecognizedKeys: true,
  fieldRename: FieldRename.snake,
)
class VeryGoodPackagesGetConfig extends Equatable {
  /// {@macro very_good_packages_get_config}
  const VeryGoodPackagesGetConfig({this.recursive, this.ignore});

  /// Creates a [VeryGoodPackagesGetConfig] from a decoded YAML/JSON [json] map.
  factory VeryGoodPackagesGetConfig.fromJson(Map<dynamic, dynamic> json) {
    return _$VeryGoodPackagesGetConfigFromJson(json);
  }

  /// Whether to install dependencies recursively for all nested packages.
  final bool? recursive;

  /// Packages to exclude from installing dependencies.
  @JsonKey(fromJson: _stringList)
  final List<String>? ignore;

  @override
  List<Object?> get props => [recursive, ignore];
}

/// {@template very_good_packages_check_config}
/// Configuration values that customize the defaults of the
/// `very_good packages check` command.
/// {@endtemplate}
@JsonSerializable(
  anyMap: true,
  checked: true,
  createToJson: false,
  disallowUnrecognizedKeys: true,
  fieldRename: FieldRename.snake,
)
class VeryGoodPackagesCheckConfig extends Equatable {
  /// {@macro very_good_packages_check_config}
  const VeryGoodPackagesCheckConfig({
    this.licenses = const VeryGoodPackagesCheckLicensesConfig(),
  });

  /// Creates a [VeryGoodPackagesCheckConfig] from a decoded YAML/JSON [json]
  /// map.
  factory VeryGoodPackagesCheckConfig.fromJson(Map<dynamic, dynamic> json) {
    return _$VeryGoodPackagesCheckConfigFromJson(json);
  }

  /// Configuration values for the `very_good packages check licenses` command.
  final VeryGoodPackagesCheckLicensesConfig licenses;

  @override
  List<Object?> get props => [licenses];
}

/// {@template very_good_packages_check_licenses_config}
/// Configuration values that customize the defaults of the
/// `very_good packages check licenses` command.
///
/// Any field that is left as `null` retains its CLI default.
/// {@endtemplate}
@JsonSerializable(
  anyMap: true,
  checked: true,
  createToJson: false,
  disallowUnrecognizedKeys: true,
  fieldRename: FieldRename.snake,
)
class VeryGoodPackagesCheckLicensesConfig extends Equatable {
  /// {@macro very_good_packages_check_licenses_config}
  const VeryGoodPackagesCheckLicensesConfig({
    this.ignoreRetrievalFailures,
    this.dependencyType,
    this.allowed,
    this.forbidden,
    this.skipPackages,
    this.reporter,
  });

  /// Creates a [VeryGoodPackagesCheckLicensesConfig] from a decoded YAML/JSON
  /// [json] map.
  factory VeryGoodPackagesCheckLicensesConfig.fromJson(
    Map<dynamic, dynamic> json,
  ) {
    return _$VeryGoodPackagesCheckLicensesConfigFromJson(json);
  }

  /// Whether to disregard licenses that failed to be retrieved.
  final bool? ignoreRetrievalFailures;

  /// The type of dependencies to check licenses for.
  @JsonKey(fromJson: _dependencyType)
  final List<String>? dependencyType;

  /// Only allow the use of certain licenses.
  @JsonKey(fromJson: _stringList)
  final List<String>? allowed;

  /// Deny the use of certain licenses.
  @JsonKey(fromJson: _stringList)
  final List<String>? forbidden;

  /// Packages to skip from having their licenses checked.
  @JsonKey(fromJson: _stringList)
  final List<String>? skipPackages;

  /// The format used to list all licenses.
  @JsonKey(fromJson: _reporter)
  final String? reporter;

  @override
  List<Object?> get props => [
    ignoreRetrievalFailures,
    dependencyType,
    allowed,
    forbidden,
    skipPackages,
    reporter,
  ];
}

/// Coerces a `num` or `String` value into a `String`.
///
/// Options are stored as strings to match the CLI's argument parsing (which
/// always yields strings) but are naturally written as numbers in YAML.
String? _numAsString(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toString();
  if (value is String) return value;
  throw FormatException('Expected a number or string but got `$value`.');
}

/// Coerces and validates a positive integer option stored as a string.
///
/// [key] is the option name used to enrich the error message.
String? _positiveInt(Object? value, String key) {
  final asString = _numAsString(value);
  if (asString == null) return null;
  final parsed = int.tryParse(asString);
  if (parsed == null || parsed < 1) {
    throw FormatException(
      'Expected `$key` to be a positive integer but got `$asString`.',
    );
  }
  return asString;
}

/// Validates and returns the `concurrency` value.
///
/// Accepts only positive integers.
String? _concurrency(Object? value) => _positiveInt(value, 'concurrency');

/// Validates and returns the `timeout` value.
///
/// Accepts only positive integers (seconds).
String? _timeout(Object? value) => _positiveInt(value, 'timeout');

/// Validates and returns the `min_coverage` value.
///
/// Accepts only a number between 0 and 100 (inclusive).
String? _minCoverage(Object? value) {
  final asString = _numAsString(value);
  if (asString == null) return null;
  final parsed = double.tryParse(asString);
  if (parsed == null || parsed < 0 || parsed > 100) {
    throw FormatException(
      'Expected `min_coverage` to be a number between 0 and 100 '
      'but got `$asString`.',
    );
  }
  return asString;
}

/// The values accepted by the `collect-coverage-from` option, shared between
/// the CLI argument parser and the `very_good.yaml` validator so they cannot
/// drift apart.
const collectCoverageFromAllowedValues = ['imports', 'all'];

/// The dependency types accepted by `very_good packages check licenses`, shared
/// between the CLI argument parser and the `very_good.yaml` validator so they
/// cannot drift apart.
const dependencyTypeAllowedValues = [
  'direct-main',
  'direct-dev',
  'direct-overridden',
  'transitive',
];

/// The values accepted by the license `reporter` option, shared between the
/// CLI argument parser and the `very_good.yaml` validator so they cannot drift
/// apart.
const reporterAllowedValues = ['text', 'csv'];

/// Validates and returns the `collect_coverage_from` value.
///
/// Accepts only `imports` or `all`.
String? _collectCoverageFrom(Object? value) {
  if (value == null) return null;
  if (!collectCoverageFromAllowedValues.contains(value)) {
    throw FormatException('Expected `imports` or `all` but got `$value`.');
  }
  return value as String;
}

/// Validates and returns the `dependency_type` value.
///
/// Accepts only the values allowed by the CLI option.
List<String>? _dependencyType(Object? value) {
  final values = _stringList(value);
  if (values == null) return null;
  for (final value in values) {
    if (!dependencyTypeAllowedValues.contains(value)) {
      throw FormatException(
        'Expected one of ${dependencyTypeAllowedValues.join(', ')} '
        'but got `$value`.',
      );
    }
  }
  return values;
}

/// Validates and returns the `reporter` value.
///
/// Accepts only `text` or `csv`.
String? _reporter(Object? value) {
  if (value == null) return null;
  if (!reporterAllowedValues.contains(value)) {
    throw FormatException('Expected `text` or `csv` but got `$value`.');
  }
  return value as String;
}

/// Coerces a single string or a list of strings into a `List<String>`.
List<String>? _stringList(Object? value) {
  if (value == null) return null;
  if (value is String) return [value];
  if (value is List) {
    return value
        .map((dynamic e) {
          if (e is! String) {
            throw FormatException(
              'Expected every entry to be a string but got `$e`.',
            );
          }
          return e;
        })
        .toList(growable: false);
  }
  throw FormatException(
    'Expected a string or list of strings but got `$value`.',
  );
}
