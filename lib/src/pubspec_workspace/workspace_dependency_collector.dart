part of 'pubspec_workspace.dart';

/// Walks a Pub workspace depth-first and collects the dependency names each
/// visited package declares, grouped by declaration kind.
///
/// A collector keeps track of the packages it has visited, so each instance
/// is meant to walk a single workspace.
class WorkspaceDependencyCollector({
  /// Receives a warning for every skipped workspace member.
  required final Logger logger,
}) {
  /// Creates a collector that reports skipped members to [logger].
  this;

  final _visited = <String>{};
  final _directMain = <String>{};
  final _directDev = <String>{};
  final _directOverridden = <String>{};

  /// Records the dependencies of [pubspec] and recurses into its members.
  ///
  /// Each directory is visited at most once, keyed by its resolved path.
  void visit(Directory directory, Pubspec pubspec) {
    if (!_visited.add(directory.resolveSymbolicLinksSync())) return;

    _directMain.addAll(pubspec.dependencies.keys);
    _directDev.addAll(pubspec.devDependencies.keys);
    _directOverridden.addAll(pubspec.dependencyOverrides.keys);

    for (final entry in pubspec.workspace ?? const <String>[]) {
      _visitEntry(directory, entry);
    }
  }

  /// Visits every member directory matched by a single `workspace:` [entry].
  void _visitEntry(Directory directory, String entry) {
    final isLiteral = !_globCharacters.hasMatch(entry);
    final memberDirectories = _expandMembers(
      directory,
      entry,
      isLiteral: isLiteral,
      logger: logger,
    );
    for (final memberDirectory in memberDirectories) {
      final memberPubspec = _parseMember(memberDirectory, isLiteral: isLiteral);
      if (memberPubspec != null) visit(memberDirectory, memberPubspec);
    }
  }

  /// Parses the member pubspec at [memberDirectory], warning when it is
  /// skipped.
  ///
  /// Glob-matched directories without a pubspec.yaml are skipped silently, so
  /// a common `packages/*` workspace does not warn for documentation or
  /// fixture folders sitting next to packages. Literal entries, and
  /// glob-matched directories whose pubspec.yaml is present but unparseable,
  /// keep the warning so real misconfigurations are still surfaced.
  Pubspec? _parseMember(Directory memberDirectory, {required bool isLiteral}) {
    final memberPubspec = _tryParsePubspecWithOverrides(memberDirectory);
    final memberPubspecFile = File(
      path.join(memberDirectory.path, _pubspecBasename),
    );
    if (memberPubspec == null &&
        (isLiteral || memberPubspecFile.existsSync())) {
      logger.warn(
        '''Skipping workspace member at ${memberDirectory.path}: missing or unparseable $_pubspecBasename.''',
      );
    }
    return memberPubspec;
  }

  /// Maps every collected name to its workspace-wide type.
  ///
  /// Builds highest precedence first so lower-precedence writes of the same
  /// name are no-ops: directMain > directDev > directOverridden.
  Map<String, PubspecDependencyType> classify() {
    final dependencies = <String, PubspecDependencyType>{};
    for (final (names, type) in [
      (_directMain, PubspecDependencyType.directMain),
      (_directDev, PubspecDependencyType.directDev),
      (_directOverridden, PubspecDependencyType.directOverridden),
    ]) {
      for (final name in names) {
        dependencies.putIfAbsent(name, () => type);
      }
    }
    return dependencies;
  }
}
