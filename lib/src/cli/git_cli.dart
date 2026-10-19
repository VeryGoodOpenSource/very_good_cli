part of 'cli.dart';

/// {@template unreachable_git_dependency}
/// Thrown when `flutter pub get` encounters an unreachable git dependency.
/// {@endtemplate}
class const UnreachableGitDependency({
  /// The associated git remote [Uri].
  required final Uri remote,
}) implements Exception {
  /// {@macro unreachable_git_dependency}
  this;

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
