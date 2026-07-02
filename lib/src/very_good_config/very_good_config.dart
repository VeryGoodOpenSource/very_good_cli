/// Support for loading Very Good CLI configuration from a
/// `very_good.yaml` file.
///
/// The configuration file lives at the root of a project and allows developers
/// to persist frequently used CLI parameters so that running the CLI locally
/// produces the same results as running it on CI.
library;

import 'dart:io';

import 'package:checked_yaml/checked_yaml.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:path/path.dart' as path;

part 'very_good_config.g.dart';

/// The default name of the Very Good CLI configuration file.
const veryGoodConfigFileName = 'very_good.yaml';

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
  fieldRename: FieldRename.kebab,
)
class VeryGoodConfig extends Equatable {
  /// {@macro very_good_config}
  const VeryGoodConfig({this.test = const VeryGoodTestConfig()});

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

  /// Loads a [VeryGoodConfig] from the given [directory].
  ///
  /// Returns [VeryGoodConfig.empty] when the configuration file does not
  /// exist. Throws a [VeryGoodConfigParseException] when the file exists
  /// but cannot be parsed.
  factory VeryGoodConfig.loadFromDirectory(Directory directory) {
    final file = File(path.join(directory.path, veryGoodConfigFileName));
    if (!file.existsSync()) return VeryGoodConfig.empty;
    return VeryGoodConfig.fromString(
      file.readAsStringSync(),
      sourceUrl: file.uri,
    );
  }

  /// An empty [VeryGoodConfig] with no values set.
  static const VeryGoodConfig empty = VeryGoodConfig();

  /// Configuration values for the `very_good test` command.
  final VeryGoodTestConfig test;

  @override
  List<Object?> get props => [test];
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
  fieldRename: FieldRename.kebab,
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
  @JsonKey(fromJson: _numAsString)
  final String? concurrency;

  /// Run only tests associated with the specified tags.
  final String? tags;

  /// A glob which will be used to exclude files that match from the coverage.
  final String? excludeCoverage;

  /// Run only tests that do not have the specified tags.
  final String? excludeTags;

  /// The minimum coverage percentage enforced.
  @JsonKey(fromJson: _numAsString)
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
  @JsonKey(fromJson: _numAsString)
  final String? timeout;

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

/// Validates and returns the `collect-coverage-from` value.
///
/// Accepts only `imports` or `all`.
String? _collectCoverageFrom(Object? value) {
  if (value == null) return null;
  if (value != 'imports' && value != 'all') {
    throw FormatException('Expected `imports` or `all` but got `$value`.');
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
