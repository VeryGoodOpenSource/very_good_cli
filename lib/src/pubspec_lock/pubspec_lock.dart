/// A simple parser for pubspec.lock files.
///
/// This is used by the `packages check license` command to check the type and
/// source of the dependencies to analyze. Hence, it is not a complete parser,
/// it only parses the information that is needed for the
/// `packages check license` command.
library pubspec_lock;

import 'dart:collection';

import 'package:equatable/equatable.dart';
import 'package:yaml/yaml.dart';

/// {@template PubspecLockParseException}
/// Thrown when a [PubspecLock] fails to parse.
/// {@endtemplate}
class PubspecLockParseException implements Exception {
  /// {@macro PubspecLockParseException}
  const PubspecLockParseException();
}

/// {@template PubspecLock}
/// A representation of a pubspec.lock file.
/// {@endtemplate}
class PubspecLock {
  const PubspecLock._({
    required this.packages,
  });

  /// Parses a [PubspecLock] from a string.
  ///
  /// If no packages are found, an empty [PubspecLock] is returned. Those
  /// packages entries that cannot be parsed are ignored.
  ///
  /// It throws a [PubspecLockParseException] if the string cannot be parsed
  /// as a [YamlMap].
  factory PubspecLock.fromString(String content) {
    late final YamlMap yaml;
    try {
      yaml = loadYaml(content) as YamlMap;
    } catch (_) {
      throw const PubspecLockParseException();
    }

    if (!yaml.containsKey('packages')) {
      return PubspecLock.empty;
    }

    final packages = yaml['packages'] as YamlMap;

    final parsedPackages = <PubspecLockPackage>[];
    for (final entry in packages.entries) {
      try {
        final package = PubspecLockPackage.fromYamlMap(
          name: entry.key as String,
          data: entry.value as YamlMap,
        );
        parsedPackages.add(package);
      } catch (_) {
        // Ignore those packages that for some reason cannot be parsed.
      }
    }

    return PubspecLock._(
      packages: UnmodifiableListView(parsedPackages),
    );
  }

  /// An empty [PubspecLock].
  static PubspecLock empty = PubspecLock._(
    packages: UnmodifiableListView([]),
  );

  /// All the dependencies in the pubspec.lock file.
  final UnmodifiableListView<PubspecLockPackage> packages;
}

/// {@template PubspecLockDependency}
/// A representation of a dependency in a pubspec.lock file.
/// {@endtemplate}
class PubspecLockPackage extends Equatable {
  /// {@macro PubspecLockDependency}
  const PubspecLockPackage({
    required this.name,
    required this.type,
    required this.isPubHosted,
  });

  /// Parses a [PubspecLockPackage] from a [YamlMap].
  factory PubspecLockPackage.fromYamlMap({
    required String name,
    required YamlMap data,
  }) {
    final dependency = data['dependency'] as String;
    final dependencyType = PubspecLockPackageDependencyType.parse(dependency);

    final source = data['source'] as String;
    late final bool isPubHosted;
    if (source == 'hosted') {
      final description = data['description'] as YamlMap;
      final url = description['url'] as String;
      isPubHosted = url == 'https://pub.dev';
    } else {
      isPubHosted = false;
    }

    return PubspecLockPackage(
      name: name,
      type: dependencyType,
      isPubHosted: isPubHosted,
    );
  }

  /// The name of the dependency.
  final String name;

  /// {@macro PubspecLockDependencyType}
  final PubspecLockPackageDependencyType type;

  /// Whether the dependency is hosted on pub.dev or not.
  final bool isPubHosted;

  @override
  List<Object?> get props => [type, isPubHosted];
}

/// {@template PubspecLockDependencyType}
/// The type of a [PubspecLockPackage].
/// {@endtemplate}
enum PubspecLockPackageDependencyType {
  /// Another package that your package needs to work.
  ///
  /// See also:
  ///
  /// * [Dart's dependency documentation](https://dart.dev/tools/pub/dependencies)
  directMain._('direct main'),

  /// Another package that your package needs during development.
  ///
  /// See also:
  ///
  /// * [Dart's developer dependency documentation](https://dart.dev/tools/pub/dependencies#dev-dependencies)
  directDev._('direct dev'),

  /// A dependency that your package indirectly uses because one of its
  /// dependencies requires it.
  ///
  /// See also:
  ///
  /// * [Dart's transitive dependency documentation](https://dart.dev/tools/pub/glossary#transitive-)
  transitive._('transitive'),

  ///  A dependency that your package overrides that is not already a
  /// `direct main` or `direct dev` dependency.
  ///
  /// See also:
  ///
  /// * [Dart's dependency override documentation](https://dart.dev/tools/pub/dependencies#dependency-overrides)
  directOverridden._('direct overridden');

  const PubspecLockPackageDependencyType._(this.value);

  /// Parses a [PubspecLockPackageDependencyType] from a string.
  ///
  /// Throws an [ArgumentError] if the string is not a valid dependency type.
  factory PubspecLockPackageDependencyType.parse(String value) {
    if (_valueMap.containsKey(value)) {
      return _valueMap[value]!;
    }

    throw ArgumentError.value(
      value,
      'value',
      'Invalid PubspecLockPackageDependencyType value.',
    );
  }

  static Map<String, PubspecLockPackageDependencyType> _valueMap = {
    for (final type in PubspecLockPackageDependencyType.values)
      type.value: type,
  };

  /// The string representation of the [PubspecLockPackageDependencyType]
  /// as it appears in a pubspec.lock file.
  final String value;
}
