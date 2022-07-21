part of 'cli.dart';

/// {@template unreachable_git_dependency}
/// Thrown when `flutter packages get` or `flutter pub get`
/// encounters an unreachable git dependency.
/// {@endtemplate}
class UnreachableGitDependency implements Exception {
  /// {@macro unreachable_git_dependency}
  const UnreachableGitDependency({required this.remote});

  /// The associated git remote [Uri].
  final Uri remote;

  @override
  String toString() {
    return '''
$remote is unreachable.
Make sure the remote exists and you have the correct access rights.''';
  }
}

/// Git CLI
class Git {
  /// Determine whether the [remote] is reachable.
  static Future<void> reachable(
    Uri remote, {
    required Logger logger,
  }) async {
    try {
      await _Cmd.run(
        'git',
        ['ls-remote', '$remote', '--exit-code'],
        logger: logger,
      );
    } catch (_) {
      throw UnreachableGitDependency(remote: remote);
    }
  }
}
