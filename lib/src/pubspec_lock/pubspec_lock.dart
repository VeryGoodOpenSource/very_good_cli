/// A simple parser for pubspec.lock files.
///
/// This is used by the `packages check license` command to check the type and
/// source of the dependencies to analyze. Hence, it is not a complete parser,
/// it only parses the information that is needed for the
/// `packages check license` command.
library;

import 'dart:collection';

import 'package:equatable/equatable.dart';
import 'package:very_good_cli/src/pubspec/pubspec.dart';
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
  const PubspecLock._({required this.packages});

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
      // This method throws type error when it fails to parse the content.
      // ignore: avoid_catching_errors
    } on TypeError catch (_) {
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
        // Ignore those packages that for some reason cannot be parsed.
        // ignore: avoid_catches_without_on_clauses
      } catch (_) {}
    }

    return PubspecLock._(packages: UnmodifiableListView(parsedPackages));
  }

  /// An empty [PubspecLock].
  static PubspecLock empty = PubspecLock._(packages: UnmodifiableListView([]));

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
    final dependencyType = PubspecDependencyType.parse(dependency);

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

  /// {@macro pubspec_dependency_type}
  final PubspecDependencyType type;

  /// Whether the dependency is hosted on pub.dev or not.
  final bool isPubHosted;

  @override
  List<Object?> get props => [type, isPubHosted];
}
