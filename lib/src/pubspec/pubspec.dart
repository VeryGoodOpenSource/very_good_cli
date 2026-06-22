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
  /// Attempts to read and parse a [Pubspec] from [file].
  ///
  /// Returns `null` when [file] does not exist or cannot be parsed; parsing is
  /// strict, so a structurally invalid pubspec (for example, one missing a
  /// `name`) is treated as unparseable rather than yielding a partially
  /// populated [Pubspec].
  ///
  /// Parse failures are swallowed silently: callers that walk workspace members
  /// (see [collectWorkspaceDependencies]) skip members that fail to parse, so a
  /// malformed member contributes no dependencies.
  static Pubspec? tryParse(File file) {
    if (!file.existsSync()) return null;
    try {
      return Pubspec.parse(file.readAsStringSync(), sourceUrl: file.uri);
    } on Exception {
      return null;
    }
  }

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
      // Workspace patterns are POSIX-style (forward slashes) per the pub
      // specification. The platform-default glob context accepts forward
      // slashes on every platform, including Windows, so the pattern needs no
      // separator normalization.
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

  /// Collects the direct dependencies declared by this workspace root and all
  /// of its members.
  ///
  /// Returns an empty [Set] when this pubspec is not a workspace root.
  /// Otherwise returns the names of the dependencies declared by the root and
  /// every member (recursively), filtered by [dependencyTypes] (only
  /// `direct-main` and `direct-dev` are relevant here).
  ///
  /// `dependency_overrides` are intentionally not collected: overridden
  /// dependencies are surfaced by the caller through the workspace's
  /// `pubspec.lock` (as `direct-overridden`) rather than from member pubspecs.
  ///
  /// The [visited] parameter prevents infinite recursion from circular
  /// workspace references; pass `null` to start a fresh traversal.
  Set<String> collectWorkspaceDependencies({
    required Directory root,
    required List<String> dependencyTypes,
    Set<String>? visited,
  }) {
    if (!isWorkspaceRoot) return {};

    final seen = visited ?? {};
    if (!seen.add(root.absolute.path)) return {};

    final deps = <String>{..._directDependencies(dependencyTypes)};

    for (final memberDir in resolveMembers(root)) {
      final memberPubspec = PubspecWorkspace.tryParse(
        File(path.join(memberDir.path, pubspecBasename)),
      );
      if (memberPubspec == null) continue;

      if (memberPubspec.isWorkspaceRoot) {
        // Nested workspace: the recursive call collects the member's own direct
        // dependencies along with those of its descendants, so they are not
        // added here as well.
        deps.addAll(
          memberPubspec.collectWorkspaceDependencies(
            root: memberDir,
            dependencyTypes: dependencyTypes,
            visited: seen,
          ),
        );
      } else {
        deps.addAll(memberPubspec._directDependencies(dependencyTypes));
      }
    }

    return deps;
  }

  /// The names of this pubspec's own direct dependencies, filtered by
  /// [dependencyTypes].
  Set<String> _directDependencies(List<String> dependencyTypes) => {
    if (dependencyTypes.contains('direct-main')) ...dependencies.keys,
    if (dependencyTypes.contains('direct-dev')) ...devDependencies.keys,
  };
}
