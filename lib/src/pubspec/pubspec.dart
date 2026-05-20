/// Workspace-aware helpers around [package:pubspec_parse].
///
/// Parsing is delegated to [Pubspec.parse]; this library only adds the
/// filesystem and glob expansion helpers needed by
/// `packages check licenses` to walk workspace members.
library;

import 'dart:io';

import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';
import 'package:path/path.dart' as path;
import 'package:pubspec_parse/pubspec_parse.dart';

export 'package:pubspec_parse/pubspec_parse.dart' show Pubspec;

/// The basename of the pubspec file.
const pubspecBasename = 'pubspec.yaml';

/// Workspace-related conveniences on top of [Pubspec].
extension PubspecWorkspace on Pubspec {
  /// Whether this pubspec is a workspace root.
  bool get isWorkspaceRoot => workspace != null;

  /// Resolves the workspace members declared by this pubspec, expanding any
  /// glob patterns relative to [root].
  ///
  /// Returns an empty list when this pubspec is not a workspace root.
  List<Directory> resolveMembers(Directory root) {
    final patterns = workspace;
    if (patterns == null) return const [];

    final members = <Directory>[];
    for (final pattern in patterns) {
      final matches = Glob(pattern).listSync(root: root.path);
      for (final match in matches) {
        if (match is Directory) {
          final pubspecFile = File(path.join(match.path, pubspecBasename));
          if (pubspecFile.existsSync()) {
            members.add(Directory(match.path));
          }
        } else if (match is File &&
            path.basename(match.path) == pubspecBasename) {
          members.add(Directory(match.parent.path));
        }
      }
    }

    return members;
  }

  /// Collects direct dependencies from this workspace root and all its members.
  ///
  /// Returns `null` when this pubspec is not a workspace root. Otherwise
  /// returns a [Set] of dependency names collected from the root and all
  /// members (recursively) filtered by [dependencyTypes].
  ///
  /// The [visited] parameter prevents infinite recursion from circular
  /// workspace references; pass `null` to start a fresh traversal.
  Set<String>? collectWorkspaceDependencies({
    required Directory root,
    required List<String> dependencyTypes,
    Set<String>? visited,
  }) {
    if (!isWorkspaceRoot) return null;

    final seen = visited ?? {};
    if (!seen.add(root.absolute.path)) return {};

    final deps = <String>{};

    if (dependencyTypes.contains('direct-main')) {
      deps.addAll(dependencies.keys);
    }
    if (dependencyTypes.contains('direct-dev')) {
      deps.addAll(devDependencies.keys);
    }

    for (final memberDir in resolveMembers(root)) {
      final memberPubspecFile = File(
        path.join(memberDir.path, pubspecBasename),
      );
      final memberPubspec = tryParsePubspec(memberPubspecFile);
      if (memberPubspec == null) continue;

      if (dependencyTypes.contains('direct-main')) {
        deps.addAll(memberPubspec.dependencies.keys);
      }
      if (dependencyTypes.contains('direct-dev')) {
        deps.addAll(memberPubspec.devDependencies.keys);
      }

      if (memberPubspec.isWorkspaceRoot) {
        final nestedDeps = memberPubspec.collectWorkspaceDependencies(
          root: memberDir,
          dependencyTypes: dependencyTypes,
          visited: seen,
        );
        if (nestedDeps != null) deps.addAll(nestedDeps);
      }
    }

    return deps;
  }
}

/// Attempts to read and parse a [Pubspec] from [file].
///
/// Returns `null` when the file does not exist or cannot be parsed.
Pubspec? tryParsePubspec(File file) {
  if (!file.existsSync()) return null;
  try {
    return Pubspec.parse(file.readAsStringSync(), sourceUrl: file.uri);
  } on Exception {
    return null;
  }
}
