import 'dart:io';

import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import 'package:very_good_cli/src/pubspec/pubspec.dart';

/// A workspace project that should have its tests re-run.
@immutable
class WorkspaceProject {
  /// Creates a [WorkspaceProject].
  const WorkspaceProject({required this.name, required this.path});

  /// Project name from `pubspec.yaml`.
  final String name;

  /// Project path relative to the current directory.
  final String path;

  /// Converts this project to JSON.
  Map<String, String> toJson() => {'name': name, 'path': path};

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is WorkspaceProject && other.name == name && other.path == path;
  }

  @override
  int get hashCode => Object.hash(name, path);
}

/// Resolves affected projects in [rootDirectory] from [changedFiles].
///
/// A project is affected when:
/// - files in the project changed directly, or
/// - it depends (directly or transitively) on a changed project via a
///   `path:` dependency listed under `dependencies` or `dev_dependencies`.
List<WorkspaceProject> resolveAffectedWorkspaceProjects({
  required Directory rootDirectory,
  required List<String> changedFiles,
}) {
  final projects = _discoverProjects(rootDirectory);
  if (projects.isEmpty || changedFiles.isEmpty) return const [];

  final projectsByPath = {
    for (final project in projects) project.absolutePath: project,
  };

  // Ensures that more specific projects are checked first, so that a file
  // change in a sub-project is attributed to the sub-project rather than a
  // parent project.
  //
  // Suppose we have the following project structure:
  //   root/
  //     project_a/
  //       pubspec.yaml
  //     project_a/sub_project/
  //       pubspec.yaml
  //
  // If a file in `project_a/sub_project` changes, we want to attribute that
  // change to `sub_project` rather than `project_a`. Therefore, we sort the
  // projects by the number of path segments in their relative paths, in
  // descending order, so that `sub_project` is checked before `project_a`.
  final projectsBySpecificity = [...projects]
    ..sort(
      (a, b) => path
          .split(b.relativePath)
          .length
          .compareTo(path.split(a.relativePath).length),
    );

  final directlyAffected = <_DiscoveredProject>{};
  for (final changedFile in changedFiles) {
    final normalized = path.normalize(
      path.isAbsolute(changedFile)
          ? changedFile
          : path.join(rootDirectory.path, changedFile),
    );

    for (final project in projectsBySpecificity) {
      final isInProject =
          normalized == project.absolutePath ||
          path.isWithin(project.absolutePath, normalized);
      if (isInProject) {
        directlyAffected.add(project);
        break;
      }
    }
  }

  // When there are no directly affected projects, there is no need to check for
  // transitive dependencies.
  if (directlyAffected.isEmpty) return const [];

  final dependents = <_DiscoveredProject, Set<_DiscoveredProject>>{
    for (final project in projects) project: <_DiscoveredProject>{},
  };

  for (final project in projects) {
    for (final dependencyPath in project.pathDependencies) {
      final dependencyAbsolutePath = path.normalize(
        path.join(project.absolutePath, dependencyPath),
      );
      final dependencyProject = projectsByPath[dependencyAbsolutePath];
      if (dependencyProject == null || dependencyProject == project) continue;
      dependents[dependencyProject]!.add(project);
    }
  }

  final affected = <_DiscoveredProject>{...directlyAffected};
  final queue = <_DiscoveredProject>[...directlyAffected];

  while (queue.isNotEmpty) {
    final current = queue.removeAt(0);
    for (final dependent in dependents[current]!) {
      if (!affected.add(dependent)) continue;
      queue.add(dependent);
    }
  }

  final result =
      affected
          .map(
            (project) => WorkspaceProject(
              name: project.name,
              path: project.relativePath,
            ),
          )
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  return result;
}

const _ignoredDirectoryNames = <String>{
  '.dart_tool',
  '.fvm',
  '.git',
  '.symlinks',
  '.plugin_symlinks',
  'android',
  'build',
  'ios',
  'linux',
  'macos',
  'windows',
};

List<_DiscoveredProject> _discoverProjects(Directory rootDirectory) {
  final pubspecFiles = <File>[];

  void visit(Directory directory) {
    for (final entity in directory.listSync(followLinks: false)) {
      if (entity is File && path.basename(entity.path) == 'pubspec.yaml') {
        pubspecFiles.add(entity);
        continue;
      }

      if (entity is! Directory) continue;
      final basename = path.basename(entity.path);
      if (_ignoredDirectoryNames.contains(basename)) continue;
      visit(entity);
    }
  }

  visit(rootDirectory);

  final projects = <_DiscoveredProject>[];
  for (final pubspecFile in pubspecFiles) {
    final pubspec = tryParsePubspec(pubspecFile);
    if (pubspec == null) continue;

    final projectDirectory = pubspecFile.parent;
    final relativePath = path.relative(
      projectDirectory.path,
      from: rootDirectory.path,
    );

    projects.add(
      _DiscoveredProject(
        name: pubspec.name,
        absolutePath: path.normalize(projectDirectory.path),
        relativePath: _toPosixPath(relativePath),
        pathDependencies: _extractPathDependencies(pubspec),
      ),
    );
  }

  return projects;
}

List<String> _extractPathDependencies(Pubspec pubspec) {
  final pathDependencies = <String>[];
  final dependencies = [
    ...pubspec.dependencies.values,
    ...pubspec.devDependencies.values,
  ];

  for (final dependency in dependencies) {
    if (dependency is! PathDependency) continue;
    pathDependencies.add(dependency.path);
  }

  return pathDependencies;
}

String _toPosixPath(String relativePath) {
  if (relativePath == '.') return relativePath;
  return path.posix.joinAll(path.split(relativePath));
}

class _DiscoveredProject {
  const _DiscoveredProject({
    required this.name,
    required this.absolutePath,
    required this.relativePath,
    required this.pathDependencies,
  });

  final String name;
  final String absolutePath;
  final String relativePath;
  final List<String> pathDependencies;
}
