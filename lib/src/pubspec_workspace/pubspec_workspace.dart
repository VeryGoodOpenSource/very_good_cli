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
import 'package:yaml/yaml.dart';

/// The basename of a pubspec file.
const _pubspecBasename = 'pubspec.yaml';

/// The basename of a pubspec overrides file.
///
/// Pub allows this file to replace the top-level `workspace`, `resolution`,
/// and `dependency_overrides` keys of the sibling `pubspec.yaml`.
const _pubspecOverridesBasename = 'pubspec_overrides.yaml';

/// Top-level pubspec keys that `pubspec_overrides.yaml` may replace.
const _overridableKeys = <String>{
  'workspace',
  'resolution',
  'dependency_overrides',
};

/// Characters that make a workspace entry a glob rather than a literal path.
///
/// A workspace entry containing none of these is treated as a literal member
/// path; anything else is expanded through [Glob].
final _globCharacters = RegExp(r'[*?\[\]{}]');

/// Resolves the directly-declared dependencies across the Pub workspace rooted
/// at [rootDirectory], mapping each dependency name to its workspace-wide
/// [PubspecDependencyType].
///
/// Walks the root and every member `pubspec.yaml` (recursively following nested
/// `workspace:` lists and glob entries) and unions their declared dependencies.
/// Each package's `pubspec_overrides.yaml`, if present, is overlaid on its
/// `pubspec.yaml` before the walk, matching Pub's override semantics for
/// `workspace`, `resolution`, and `dependency_overrides`.
///
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
  final rootPubspecFile = File(path.join(rootDirectory.path, _pubspecBasename));

  // A missing pubspec is the normal non-workspace case: fall back silently to
  // the lock's own classification.
  if (!rootPubspecFile.existsSync()) return null;

  final rootPubspec = _tryParsePubspecWithOverrides(rootDirectory);
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
      final isLiteral = !_globCharacters.hasMatch(entry);
      for (final memberDirectory in _expandMembers(
        directory,
        entry,
        isLiteral: isLiteral,
        logger: logger,
      )) {
        final memberPubspecFile = File(
          path.join(memberDirectory.path, _pubspecBasename),
        );
        final memberPubspec = _tryParsePubspecWithOverrides(memberDirectory);
        if (memberPubspec == null) {
          // Silently skip glob-matched directories that don't contain a
          // pubspec.yaml — a common `packages/*` workspace should not warn
          // for documentation or fixture folders sitting next to packages.
          // For literal entries, or for glob-matched directories where a
          // pubspec.yaml IS present but unparseable, keep the warning so
          // real misconfigurations are still surfaced.
          if (isLiteral || memberPubspecFile.existsSync()) {
            logger.warn(
              '''Skipping workspace member at ${memberDirectory.path}: missing or unparseable $_pubspecBasename.''',
            );
          }
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
///
/// Honors a sibling `pubspec_overrides.yaml`, since Pub allows the `resolution`
/// key to be set there instead of in `pubspec.yaml`.
bool declaresWorkspaceResolution(Directory directory) {
  final pubspec = _tryParsePubspecWithOverrides(directory);
  return pubspec?.resolution == 'workspace';
}

/// Tolerantly parses the pubspec at [directory], overlaying any sibling
/// `pubspec_overrides.yaml`.
///
/// Overrides replace the corresponding top-level `workspace`, `resolution`,
/// and `dependency_overrides` keys (they do not merge with them), matching
/// Pub's semantics. Any other key in the overrides file is ignored.
///
/// Returns `null` when the pubspec.yaml file does not exist or cannot be
/// parsed. When the overrides file exists but cannot be parsed, falls back to
/// the pubspec.yaml alone rather than treating the whole package as broken.
Pubspec? _tryParsePubspecWithOverrides(Directory directory) {
  final pubspecFile = File(path.join(directory.path, _pubspecBasename));
  if (!pubspecFile.existsSync()) return null;

  final overridesFile = File(
    path.join(directory.path, _pubspecOverridesBasename),
  );

  if (!overridesFile.existsSync()) return tryParsePubspec(pubspecFile);

  try {
    final pubspecYaml = loadYaml(pubspecFile.readAsStringSync());
    if (pubspecYaml is! Map) return tryParsePubspec(pubspecFile);

    final overridesYaml = loadYaml(overridesFile.readAsStringSync());

    final merged = <String, dynamic>{
      for (final entry in pubspecYaml.entries) entry.key as String: entry.value,
    };

    if (overridesYaml is Map) {
      for (final key in _overridableKeys) {
        if (overridesYaml.containsKey(key)) {
          merged[key] = overridesYaml[key];
        }
      }
    }

    return Pubspec.fromJson(merged, lenient: true);
    // Tolerate any malformed pubspec / overrides by falling back to the
    // pubspec.yaml alone instead of treating the whole package as broken.
    // ignore: avoid_catches_without_on_clauses
  } catch (_) {
    return tryParsePubspec(pubspecFile);
  }
}

/// Expands a single `workspace:` [entry] relative to [base] into the member
/// directories it matches.
///
/// A literal path is the no-wildcard case of a glob, so one code path covers
/// both. Only existing directories are returned. When [isLiteral] is `false`
/// (the entry contains glob wildcards), matches are further filtered to
/// directories containing a `pubspec.yaml`, and no warning is emitted when the
/// filter or the glob itself returns nothing — a `packages/*` workspace
/// legitimately co-exists with non-package folders and with an empty
/// `packages/` directory. Literal entries continue to warn on no-match so
/// typo'd `workspace:` entries are still visible.
Iterable<Directory> _expandMembers(
  Directory base,
  String entry, {
  required bool isLiteral,
  required Logger logger,
}) {
  List<FileSystemEntity> matches;
  try {
    matches = Glob(entry).listSync(root: base.path);
    // A missing intermediate directory (e.g. `packages/*` when `packages/`
    // does not exist) surfaces as a FileSystemException; treat it as no match.
    //
    // On Unix, globbing into a path whose intermediate segment is a file
    // throws (ENOTDIR); on Windows glob swallows it internally, so this catch
    // is unreachable there and cannot be covered on both platforms.
    // coverage:ignore-start
  } on FileSystemException {
    matches = const [];
    // coverage:ignore-end
  }

  var directories = matches.whereType<Directory>().toList();
  if (!isLiteral) {
    directories = directories
        .where(
          (directory) =>
              File(path.join(directory.path, _pubspecBasename)).existsSync(),
        )
        .toList();
  }

  if (directories.isEmpty) {
    if (isLiteral) {
      logger.warn(
        '''No workspace member directory matched "$entry" (resolved from ${base.path}).''',
      );
    }
    return const [];
  }

  return directories;
}
