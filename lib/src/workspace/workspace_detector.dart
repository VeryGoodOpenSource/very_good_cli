import 'package:path/path.dart' as path;
import 'package:universal_io/io.dart';
import 'package:very_good_cli/src/workspace/workspace_context.dart';
import 'package:yaml/yaml.dart';

/// {@template workspace_detector}
/// Locates the Dart/Flutter [pub workspace][1] that a directory belongs to.
///
/// Starting from a given directory, it walks up the directory tree until it
/// finds a `pubspec.yaml` declaring a top-level `workspace:` key. Member
/// packages (which declare `resolution: workspace` instead) are skipped, so
/// detection from anywhere inside a workspace resolves to its root.
///
/// [1]: https://dart.dev/tools/pub/workspaces
/// {@endtemplate}
class WorkspaceDetector {
  /// {@macro workspace_detector}
  const WorkspaceDetector();

  /// Returns the [WorkspaceContext] for the workspace containing [from], or
  /// `null` if [from] is not inside a workspace.
  WorkspaceContext? detect(Directory from) {
    var directory = from.absolute;

    while (true) {
      final pubspec = File(path.join(directory.path, 'pubspec.yaml'));
      if (pubspec.existsSync()) {
        final context = _contextFor(directory, pubspec);
        if (context != null) return context;
      }

      final parent = directory.parent;
      if (path.equals(parent.path, directory.path)) return null;
      directory = parent;
    }
  }

  WorkspaceContext? _contextFor(Directory directory, File pubspec) {
    final dynamic yaml = loadYaml(pubspec.readAsStringSync());
    if (yaml is! YamlMap || !yaml.containsKey('workspace')) return null;

    final workspace = yaml['workspace'];
    final members = workspace is YamlList
        ? workspace.map((dynamic e) => '$e').toList()
        : <String>[];

    return WorkspaceContext(rootPath: directory.path, members: members);
  }
}
