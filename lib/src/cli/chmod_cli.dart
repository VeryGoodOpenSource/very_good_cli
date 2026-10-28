part of 'cli.dart';

/// Chmod CLI
class Chmod {
  /// Marks the files at [paths] as executable.
  static Future<void> makeExecutable(
    List<String> paths, {
    required Logger logger,
  }) async {
    await _Cmd.run('chmod', ['+x', ...paths], logger: logger);
  }
}
