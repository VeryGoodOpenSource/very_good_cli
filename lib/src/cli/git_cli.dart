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
  /// Returns file paths changed from [baseRef] to `HEAD`.
  ///
  /// Paths are relative to [cwd].
  static Future<List<String>> changedFiles(
    String baseRef, {
    required Logger logger,
    String cwd = '.',
  }) async {
    final result = await _Cmd.run(
      'git',
      ['diff', '--name-only', '--relative', '$baseRef...HEAD'],
      logger: logger,
      workingDirectory: cwd,
    );

    final lines = result.stdout
        .toString()
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    return lines;
  }

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
