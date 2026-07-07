part of 'cli.dart';

/// {@template unreachable_git_dependency}
/// Thrown when `flutter pub get` encounters an unreachable git dependency.
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
  ///
  /// The check honors `url.<base>.insteadOf` git config overrides by passing
  /// `--get-url` to `git ls-remote`, mirroring how the actual pull would
  /// resolve the remote.
  static Future<void> reachable(Uri remote, {required Logger logger}) async {
    try {
      await _Cmd.run('git', [
        'ls-remote',
        '--get-url',
        '$remote',
        '--exit-code',
      ], logger: logger);
    } on Exception catch (_) {
      throw UnreachableGitDependency(remote: remote);
    }
  }
}
