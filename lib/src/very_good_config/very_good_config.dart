/// Support for loading Very Good CLI configuration from a
/// `very_good.yaml` file.
///
/// The configuration file lives at the root of a project and allows
/// developers to persist frequently used CLI parameters (for example
/// `test` coverage excludes) so that running the CLI locally produces the
/// same results as running it on CI.
library;

import 'package:equatable/equatable.dart';
import 'package:path/path.dart' as p;
import 'package:universal_io/io.dart';
import 'package:yaml/yaml.dart';

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
class VeryGoodConfig extends Equatable {
  /// {@macro very_good_config}
  const VeryGoodConfig({this.test = const VeryGoodTestConfig()});

  /// An empty [VeryGoodConfig] with no values set.
  static const VeryGoodConfig empty = VeryGoodConfig();

  /// Parses a [VeryGoodConfig] from a YAML [content] string.
  ///
  /// An empty or `null` YAML document yields [VeryGoodConfig.empty].
  ///
  /// Throws a [VeryGoodConfigParseException] if [content] is not a valid
  /// YAML map or if any known section is malformed.
  factory VeryGoodConfig.fromString(String content) {
    final dynamic loaded;
    try {
      loaded = loadYaml(content);
    } on YamlException catch (e) {
      throw VeryGoodConfigParseException('Failed to parse YAML: ${e.message}');
    }

    if (loaded == null) return VeryGoodConfig.empty;
    if (loaded is! YamlMap) {
      throw const VeryGoodConfigParseException(
        'The root of `very_good.yaml` must be a map.',
      );
    }

    final testSection = loaded['test'];
    final testConfig = testSection == null
        ? const VeryGoodTestConfig()
        : VeryGoodTestConfig.fromYaml(testSection);

    return VeryGoodConfig(test: testConfig);
  }

  /// Loads a [VeryGoodConfig] from the given [directory].
  ///
  /// Returns [VeryGoodConfig.empty] when the configuration file does not
  /// exist. Throws a [VeryGoodConfigParseException] when the file exists
  /// but cannot be parsed.
  static VeryGoodConfig loadFromDirectory(Directory directory) {
    final file = File(p.join(directory.path, veryGoodConfigFileName));
    if (!file.existsSync()) return VeryGoodConfig.empty;
    return VeryGoodConfig.fromString(file.readAsStringSync());
  }

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

  /// Parses a [VeryGoodTestConfig] from a YAML node.
  ///
  /// Throws a [VeryGoodConfigParseException] if the [yaml] node is not a
  /// map or if any known field has an unsupported type.
  factory VeryGoodTestConfig.fromYaml(dynamic yaml) {
    if (yaml is! YamlMap) {
      throw const VeryGoodConfigParseException(
        'The `test` section of `very_good.yaml` must be a map.',
      );
    }

    return VeryGoodTestConfig(
      coverage: _readBool(yaml, 'coverage'),
      optimization: _readBool(yaml, 'optimization'),
      concurrency: _readIntAsString(yaml, 'concurrency'),
      tags: _readString(yaml, 'tags'),
      excludeCoverage: _readString(yaml, 'exclude-coverage'),
      excludeTags: _readString(yaml, 'exclude-tags'),
      minCoverage: _readNumAsString(yaml, 'min-coverage'),
      showUncovered: _readBool(yaml, 'show-uncovered'),
      collectCoverageFrom: _readCollectCoverageFrom(yaml),
      updateGoldens: _readBool(yaml, 'update-goldens'),
      failFast: _readBool(yaml, 'fail-fast'),
      dartDefine: _readStringList(yaml, 'dart-define'),
      dartDefineFromFile: _readStringList(yaml, 'dart-define-from-file'),
      platform: _readString(yaml, 'platform'),
      reportOn: _readStringList(yaml, 'report-on'),
      runSkipped: _readBool(yaml, 'run-skipped'),
      flavor: _readString(yaml, 'flavor'),
      timeout: _readIntAsString(yaml, 'timeout'),
    );
  }

  /// Whether to collect coverage information.
  final bool? coverage;

  /// Whether to apply optimizations for test performance.
  final bool? optimization;

  /// The number of concurrent test suites run.
  final String? concurrency;

  /// Run only tests associated with the specified tags.
  final String? tags;

  /// A glob which will be used to exclude files that match from the coverage.
  final String? excludeCoverage;

  /// Run only tests that do not have the specified tags.
  final String? excludeTags;

  /// The minimum coverage percentage enforced.
  final String? minCoverage;

  /// Whether to show uncovered lines when coverage is below 100%.
  final bool? showUncovered;

  /// Whether to collect coverage from imported files only or all files.
  final String? collectCoverageFrom;

  /// Whether `matchesGoldenFile()` calls should update the golden files.
  final bool? updateGoldens;

  /// Whether to stop running tests after the first failure.
  final bool? failFast;

  /// Additional `--dart-define` values.
  final List<String>? dartDefine;

  /// Paths of `.json` or `.env` files with `--dart-define-from-file` values.
  final List<String>? dartDefineFromFile;

  /// The platform to run tests on (e.g. `chrome`, `vm`, `android`, `ios`).
  final String? platform;

  /// Optional file paths to report coverage information to.
  final List<String>? reportOn;

  /// Whether to run skipped tests instead of skipping them.
  final bool? runSkipped;

  /// The flavor to build for testing.
  final String? flavor;

  /// Maximum seconds to let tests run before killing the process.
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

bool? _readBool(YamlMap yaml, String key) {
  if (!yaml.containsKey(key)) return null;
  final value = yaml[key];
  if (value is! bool) {
    throw VeryGoodConfigParseException(
      'Expected a boolean value for `$key` but got `$value`.',
    );
  }
  return value;
}

String? _readString(YamlMap yaml, String key) {
  if (!yaml.containsKey(key)) return null;
  final value = yaml[key];
  if (value is! String) {
    throw VeryGoodConfigParseException(
      'Expected a string value for `$key` but got `$value`.',
    );
  }
  return value;
}

String? _readIntAsString(YamlMap yaml, String key) {
  if (!yaml.containsKey(key)) return null;
  final value = yaml[key];
  if (value is int) return value.toString();
  if (value is String) return value;
  throw VeryGoodConfigParseException(
    'Expected an integer or string value for `$key` but got `$value`.',
  );
}

String? _readNumAsString(YamlMap yaml, String key) {
  if (!yaml.containsKey(key)) return null;
  final value = yaml[key];
  if (value is num) return value.toString();
  if (value is String) return value;
  throw VeryGoodConfigParseException(
    'Expected a number or string value for `$key` but got `$value`.',
  );
}

String? _readCollectCoverageFrom(YamlMap yaml) {
  const key = 'collect-coverage-from';
  final value = _readString(yaml, key);
  if (value == null) return null;
  if (value != 'imports' && value != 'all') {
    throw VeryGoodConfigParseException(
      'Expected `$key` to be `imports` or `all` but got `$value`.',
    );
  }
  return value;
}

List<String>? _readStringList(YamlMap yaml, String key) {
  if (!yaml.containsKey(key)) return null;
  final value = yaml[key];
  if (value is String) return [value];
  if (value is YamlList) {
    return value
        .map((dynamic e) {
          if (e is! String) {
            throw VeryGoodConfigParseException(
              'Expected every entry of `$key` to be a string but got `$e`.',
            );
          }
          return e;
        })
        .toList(growable: false);
  }
  throw VeryGoodConfigParseException(
    'Expected a string or list of strings for `$key` but got `$value`.',
  );
}
