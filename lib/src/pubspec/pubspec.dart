/// A simple parser for pubspec.yaml files.
///
/// This is used by the `packages check licenses` command to detect workspace
/// configurations and collect dependencies from workspace members.
library;

import 'dart:collection';
import 'dart:io';

import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

/// {@template PubspecParseException}
/// Thrown when a [Pubspec] fails to parse.
/// {@endtemplate}
class PubspecParseException implements Exception {
  /// {@macro PubspecParseException}
  const PubspecParseException([this.message]);

  /// The error message.
  final String? message;

  @override
  String toString() => message != null
      ? 'PubspecParseException: $message'
      : 'PubspecParseException';
}

/// {@template Pubspec}
/// A representation of a pubspec.yaml file.
/// {@endtemplate}
class Pubspec {
  const Pubspec._({
    required this.name,
    required this.dependencies,
    required this.devDependencies,
    required this.workspace,
    required this.resolution,
  });

  /// Parses a [Pubspec] from a string.
  ///
  /// Throws a [PubspecParseException] if the string cannot be parsed.
  factory Pubspec.fromString(String content) {
    late final YamlMap yaml;
    try {
      yaml = loadYaml(content) as YamlMap;
      // loadYaml throws TypeError when it fails to cast content as a YamlMap.
      // YamlException is thrown when the content is not valid YAML.
      // We need to catch both to provide a meaningful exception.
      // ignore: avoid_catching_errors
    } on TypeError catch (_) {
      throw const PubspecParseException('Failed to parse YAML content');
    } on YamlException catch (_) {
      throw const PubspecParseException('Failed to parse YAML content');
    }

    final name = yaml['name'] as String? ?? '';

    final dependencies = _parseDependencies(yaml['dependencies']);
    final devDependencies = _parseDependencies(yaml['dev_dependencies']);

    final workspaceValue = yaml['workspace'];
    List<String>? workspace;
    if (workspaceValue is YamlList) {
      workspace = workspaceValue.cast<String>().toList();
    }

    final resolutionValue = yaml['resolution'];
    PubspecResolution? resolution;
    if (resolutionValue is String) {
      resolution = PubspecResolution.tryParse(resolutionValue);
    }

    return Pubspec._(
      name: name,
      dependencies: UnmodifiableListView(dependencies),
      devDependencies: UnmodifiableListView(devDependencies),
      workspace: workspace != null ? UnmodifiableListView(workspace) : null,
      resolution: resolution,
    );
  }

  /// Parses a [Pubspec] from a file.
  ///
  /// Throws a [PubspecParseException] if the file cannot be read or parsed.
  factory Pubspec.fromFile(File file) {
    if (!file.existsSync()) {
      throw PubspecParseException('File not found: ${file.path}');
    }
    return Pubspec.fromString(file.readAsStringSync());
  }

  /// The name of the package.
  final String name;

  /// The direct main dependencies.
  final UnmodifiableListView<String> dependencies;

  /// The direct dev dependencies.
  final UnmodifiableListView<String> devDependencies;

  /// The workspace member paths, if this is a workspace root.
  ///
  /// This is `null` if this pubspec is not a workspace root.
  final UnmodifiableListView<String>? workspace;

  /// The resolution mode for this package.
  ///
  /// This is `null` if no resolution is specified (typical for standalone
  /// packages or workspace roots).
  final PubspecResolution? resolution;

  /// Whether this pubspec is a workspace root.
  bool get isWorkspaceRoot => workspace != null;

  /// Whether this pubspec is a workspace member.
  bool get isWorkspaceMember => resolution == PubspecResolution.workspace;

  /// Resolves workspace member paths to actual directories.
  ///
  /// This handles glob patterns in workspace paths (e.g., `packages/*`).
  /// The [rootDirectory] should be the directory containing this pubspec.
  ///
  /// Returns an empty list if this is not a workspace root.
  List<Directory> resolveWorkspaceMembers(Directory rootDirectory) {
    if (workspace == null) return [];

    final members = <Directory>[];
    for (final pattern in workspace!) {
      if (_isGlobPattern(pattern)) {
        // Handle glob patterns
        final glob = Glob(pattern);
        final matches = glob.listSync(root: rootDirectory.path);
        for (final match in matches) {
          if (match is Directory) {
            final pubspecFile = File(path.join(match.path, 'pubspec.yaml'));
            if (pubspecFile.existsSync()) {
              members.add(Directory(match.path));
            }
          } else if (match is File &&
              path.basename(match.path) == 'pubspec.yaml') {
            members.add(Directory(match.parent.path));
          }
        }
      } else {
        // Handle direct path
        final memberPath = path.join(rootDirectory.path, pattern);
        final memberDir = Directory(memberPath);
        if (memberDir.existsSync()) {
          members.add(memberDir);
        }
      }
    }

    return members;
  }
}

/// Parses dependency names from a YAML dependencies map.
List<String> _parseDependencies(Object? value) {
  if (value == null) return [];
  if (value is! YamlMap) return [];

  return value.keys.cast<String>().toList();
}

/// Checks if a path pattern contains glob characters.
bool _isGlobPattern(String pattern) {
  return pattern.contains('*') ||
      pattern.contains('?') ||
      pattern.contains('[') ||
      pattern.contains('{');
}

/// {@template PubspecResolution}
/// The resolution mode for a pubspec.
/// {@endtemplate}
enum PubspecResolution {
  /// This package is a workspace member and should resolve with the workspace
  /// root.
  workspace._('workspace'),

  /// This package uses external resolution (e.g., Dart SDK packages).
  external._('external'),
  ;

  const PubspecResolution._(this.value);

  /// Tries to parse a [PubspecResolution] from a string.
  ///
  /// Returns `null` if the string is not a valid resolution value.
  static PubspecResolution? tryParse(String value) {
    for (final resolution in PubspecResolution.values) {
      if (resolution.value == value) {
        return resolution;
      }
    }
    return null;
  }

  /// The string representation as it appears in pubspec.yaml.
  final String value;
}
