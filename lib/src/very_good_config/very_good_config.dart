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
  disallowUnrecognizedKeys: true,
  fieldRename: FieldRename.snake,
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

  /// Loads the closest [VeryGoodConfig] by searching [directory] and each of
  /// its ancestors, from the innermost directory outward.
  ///
  /// [directory] is resolved to an absolute path before the walk, so a relative
  /// [directory] is searched relative to the current working directory.
  ///
  /// This allows a single repository-wide `very_good.yaml` at the project root
  /// to apply to commands run from any nested package directory. The first
  /// configuration file encountered wins; ancestors are not merged.
  ///
  /// Returns [VeryGoodConfig.empty] when no configuration file is found.
  /// Throws a [VeryGoodConfigParseException] when the closest file exists but
  /// cannot be parsed.
  factory VeryGoodConfig.loadFromClosestAncestor(Directory directory) {
    var current = directory.absolute;
    while (true) {
      final config = _loadFromDirectory(current);
      if (config != null) return config;
      final parent = current.parent;
      if (parent.path == current.path) return VeryGoodConfig.empty;
      current = parent;
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

// The coercers below intentionally validate more strictly than the CLI flag
// parser. A value such as `min_coverage: 150` is rejected here at config load
// time even though `--min-coverage 150` is accepted by the flag parser, so
// misconfigured `very_good.yaml` files fail fast with a clear message.

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

/// Validates and returns the `collect_coverage_from` value.
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
