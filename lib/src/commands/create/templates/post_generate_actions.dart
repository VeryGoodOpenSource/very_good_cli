import 'package:mason/mason.dart';
import 'package:universal_io/io.dart';
import 'package:very_good_cli/src/cli/cli.dart';

/// Runs `dart pub get` in the [outputDir].
///
/// Completes with `true` is the execution was successful, `false` otherwise.
Future<bool> installDartPackages(
  Logger logger,
  Directory outputDir, {
  bool recursive = false,
}) async {
  final isDartInstalled = await Dart.installed(logger: logger);
  if (isDartInstalled) {
    return Dart.pubGet(
      cwd: outputDir.path,
      recursive: recursive,
      logger: logger,
    );
  }
  return false;
}

/// Runs `flutter pub get` in the [outputDir].
Future<bool> installFlutterPackages(
  Logger logger,
  Directory outputDir, {
  bool recursive = false,
}) async {
  final isFlutterInstalled = await Flutter.installed(logger: logger);
  if (isFlutterInstalled) {
    return Flutter.pubGet(
      cwd: outputDir.path,
      recursive: recursive,
      logger: logger,
    );
  }
  return false;
}

/// Runs `dart fix --apply` in the [outputDir].
Future<void> applyDartFixes(
  Logger logger,
  Directory outputDir, {
  bool recursive = false,
}) async {
  final isDartInstalled = await Dart.installed(logger: logger);
  if (isDartInstalled) {
    final applyFixesProgress = logger.progress(
      'Running "dart fix --apply" in ${outputDir.path}',
    );
    await Dart.applyFixes(
      cwd: outputDir.path,
      recursive: recursive,
      logger: logger,
    );
    applyFixesProgress.complete();
  }
}
