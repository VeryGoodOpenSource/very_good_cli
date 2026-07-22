/// A tolerant resolver for Pub workspace dependency classification.
///
/// This is used by the `packages check licenses` command. In a Pub workspace,
/// member packages share a single `pubspec.lock` at the workspace root, and
/// that lock classifies every member's direct dependency as `transitive` (only
/// the root package's own dependencies are classified relative to it). As a
/// result, running the command at the workspace root reports no direct
/// dependencies.
///
/// This resolver rebuilds the correct classification by unioning the
/// directly-declared dependencies across the root and every member
/// `pubspec.yaml`. It mirrors the shape and philosophy of `pubspec_lock.dart`:
/// a small, tolerant, single-purpose parser. It is not a general workspace
/// model.
library;

import 'dart:io';

import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as path;
import 'package:very_good_cli/src/pubspec/pubspec.dart';

/// The basename of a pubspec file.
const _pubspecBasename = 'pubspec.yaml';

/// Resolves the directly-declared dependencies across the Pub workspace rooted
/// at [rootDirectory], mapping each dependency name to its workspace-wide
/// [PubspecDependencyType].
///
/// Walks the root and every member `pubspec.yaml` (recursively following nested
/// `workspace:` lists and glob entries) and unions their declared dependencies.
/// Precedence when a name appears under multiple types across members:
/// `directMain` > `directDev` > `directOverridden` (approximates pub's
/// precedence). Names not directly declared by any member are absent from the
/// map; the caller treats an absent name as
/// [PubspecDependencyType.transitive].
///
/// Returns `null` when [rootDirectory] has no readable workspace-root pubspec
/// (missing pubspec, or no non-empty `workspace:` list) — the caller then falls
/// back to the lock's own classification (non-workspace behavior). A present
/// but unparseable root pubspec logs a warning via [logger] before returning
/// `null`. [logger] also receives a warning for every skipped member.
Map<String, PubspecDependencyType>? resolveWorkspaceDependencies(
  Directory rootDirectory, {
  required Logger logger,
}) {
  final rootPubspecFile = File(
    path.join(rootDirectory.path, _pubspecBasename),
  );

  // A missing pubspec is the normal non-workspace case: fall back silently to
  // the lock's own classification.
  if (!rootPubspecFile.existsSync()) return null;

  final rootPubspec = tryParsePubspec(rootPubspecFile);
  if (rootPubspec == null) {
    logger.warn(
      '''Could not parse the workspace-root $_pubspecBasename in ${rootDirectory.path}. Falling back to the lock file classification.''',
    );
    return null;
  }

  final workspace = rootPubspec.workspace;
  if (workspace == null || workspace.isEmpty) return null;

  final visited = <String>{};
  final directDev = <String>{};
  final directMain = <String>{};
  final directOverridden = <String>{};

  void visit(Directory directory, Pubspec pubspec) {
    if (!visited.add(directory.resolveSymbolicLinksSync())) return;

    directMain.addAll(pubspec.dependencies.keys);
    directDev.addAll(pubspec.devDependencies.keys);
    directOverridden.addAll(pubspec.dependencyOverrides.keys);

    for (final entry in pubspec.workspace ?? const <String>[]) {
      for (final memberDirectory in _expandMembers(directory, entry, logger)) {
        final memberPubspec = tryParsePubspec(
          File(path.join(memberDirectory.path, _pubspecBasename)),
        );
        if (memberPubspec == null) {
          logger.warn(
            '''Skipping workspace member at ${memberDirectory.path}: missing or unparseable $_pubspecBasename.''',
          );
          continue;
        }
        visit(memberDirectory, memberPubspec);
      }
    }
  }

  visit(rootDirectory, rootPubspec);

  // Build highest precedence first so lower-precedence writes of the same name
  // are no-ops: directMain > directDev > directOverridden.
  final dependencies = <String, PubspecDependencyType>{};

  for (final name in directMain) {
    dependencies[name] = PubspecDependencyType.directMain;
  }

  for (final name in directDev) {
    dependencies.putIfAbsent(name, () => PubspecDependencyType.directDev);
  }

  for (final name in directOverridden) {
    dependencies.putIfAbsent(
      name,
      () => PubspecDependencyType.directOverridden,
    );
  }

  return dependencies;
}

/// Whether the package rooted at [directory] declares `resolution: workspace`,
/// indicating it is a member of a Pub workspace and must have its licenses
/// checked from the workspace root instead.
bool declaresWorkspaceResolution(Directory directory) {
  final pubspec = tryParsePubspec(
    File(path.join(directory.path, _pubspecBasename)),
  );
  return pubspec?.resolution == 'workspace';
}

/// Expands a single `workspace:` [entry] relative to [base] into the member
/// directories it matches.
///
/// A literal path is the no-wildcard case of a glob, so one code path covers
/// both. Only existing directories are returned. When nothing matches, [logger]
/// receives a warning and an empty iterable is returned.
Iterable<Directory> _expandMembers(
  Directory base,
  String entry,
  Logger logger,
) {
  List<FileSystemEntity> matches;
  try {
    matches = Glob(entry).listSync(root: base.path);
    // A missing intermediate directory (e.g. `packages/*` when `packages/`
    // does not exist) surfaces as a FileSystemException; treat it as no match.
  } on FileSystemException {
    matches = const [];
  }

  final directories = matches.whereType<Directory>().toList();
  if (directories.isEmpty) {
    logger.warn(
      '''No workspace member directory matched "$entry" (resolved from ${base.path}).''',
    );
    return const [];
  }

  return directories;
}
