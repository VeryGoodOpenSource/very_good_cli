import 'package:path/path.dart' as path;
import 'package:universal_io/io.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

/// {@template workspace_integrator}
/// Registers a package as a member of a Dart/Flutter [pub workspace][1] by
/// adding its path to the `workspace:` list in the workspace's `pubspec.yaml`.
///
/// Edits are made with `yaml_edit` so existing formatting and comments are
/// preserved.
///
/// [1]: https://dart.dev/tools/pub/workspaces
/// {@endtemplate}
class WorkspaceIntegrator {
  /// {@macro workspace_integrator}
  const WorkspaceIntegrator();

  /// Adds [packageDirectory] to the `workspace:` list of the workspace rooted
  /// at [workspaceRoot].
  ///
  /// Returns the relative member path that was added, or `null` if no change
  /// was made — either because the package is already a member, or because it
  /// lies outside [workspaceRoot].
  String? addPackage({
    required Directory workspaceRoot,
    required Directory packageDirectory,
  }) {
    final relative = path.relative(
      packageDirectory.absolute.path,
      from: workspaceRoot.absolute.path,
    );
    final member = path.split(relative).join('/');

    // Refuse to register the workspace root itself or anything outside it.
    if (member == '.' || member.startsWith('..')) return null;

    final pubspecFile = File(path.join(workspaceRoot.path, 'pubspec.yaml'));
    final editor = YamlEditor(pubspecFile.readAsStringSync());

    final members = _members(editor);
    if (members.contains(member)) return null;

    if (members.isEmpty) {
      // Replaces a missing or empty `workspace:` value with a fresh block
      // list, ensuring clean block-style formatting on the first member.
      editor.update(['workspace'], [member]);
    } else {
      editor.appendToList(['workspace'], member);
    }

    pubspecFile.writeAsStringSync(editor.toString());
    return member;
  }

  /// Ensures the package at [packagePubspec] declares `resolution: workspace`
  /// so it participates in the surrounding workspace's shared resolution.
  ///
  /// Returns `true` if the file was modified.
  bool ensureWorkspaceResolution(File packagePubspec) {
    if (!packagePubspec.existsSync()) return false;

    final editor = YamlEditor(packagePubspec.readAsStringSync());
    final existing = editor.parseAt(
      ['resolution'],
      orElse: () => wrapAsYamlNode(null),
    );
    if (existing.value == 'workspace') return false;

    editor.update(['resolution'], 'workspace');
    packagePubspec.writeAsStringSync(editor.toString());
    return true;
  }

  /// Adds a path dependency on [packageName] (resolved at [relativePath],
  /// using forward slashes) to the `dependencies:` of [appPubspec].
  ///
  /// Returns `true` if the dependency was added, or `false` if it was already
  /// present.
  bool addPathDependency({
    required File appPubspec,
    required String packageName,
    required String relativePath,
  }) {
    final editor = YamlEditor(appPubspec.readAsStringSync());

    final dependencies = editor.parseAt(
      ['dependencies'],
      orElse: () => wrapAsYamlNode(null),
    );
    if (dependencies is YamlMap && dependencies.containsKey(packageName)) {
      return false;
    }

    if (dependencies is! YamlMap) {
      editor.update(['dependencies'], <String, dynamic>{});
    }
    editor.update(['dependencies', packageName], {'path': relativePath});

    appPubspec.writeAsStringSync(editor.toString());
    return true;
  }

  List<String> _members(YamlEditor editor) {
    // `orElse` handles an absent `workspace:` key without throwing.
    final node = editor.parseAt([
      'workspace',
    ], orElse: () => wrapAsYamlNode(null));
    if (node is YamlList) {
      return node.map((dynamic e) => '$e').toList();
    }
    return [];
  }
}
