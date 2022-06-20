import 'package:mason/mason.dart';
import 'package:universal_io/io.dart';
import 'package:very_good_cli/src/cli/cli.dart';

/// Runs `flutter pub get` in the [outputDir].
Future<void> installDartPackages(
  Logger logger,
  Directory outputDir,
) async {
  final isFlutterInstalled = await Flutter.installed();
  if (isFlutterInstalled) {
    final installDependenciesProgress = logger.progress(
      'Running "flutter pub get" in ${outputDir.path}',
    );
    await Flutter.pubGet(cwd: outputDir.path);
    installDependenciesProgress.complete();
  }
}

/// Runs `flutter packages get` in the [outputDir].
Future<void> installFlutterPackages(
  Logger logger,
  Directory outputDir, {
  bool recursive = false,
}) async {
  final isFlutterInstalled = await Flutter.installed();
  if (isFlutterInstalled) {
    final installDependenciesProgress = logger.progress(
      'Running "flutter packages get" in ${outputDir.path}',
    );
    await Flutter.packagesGet(cwd: outputDir.path, recursive: recursive);
    installDependenciesProgress.complete();
  }
}

/// Runs `dart fix --apply` in the [outputDir].
Future<void> applyDartFixes(
  Logger logger,
  Directory outputDir, {
  bool recursive = false,
}) async {
  final isDartInstalled = await Dart.installed();
  if (isDartInstalled) {
    final applyFixesProgress = logger.progress(
      'Running "dart fix --apply" in ${outputDir.path}',
    );
    await Dart.applyFixes(cwd: outputDir.path, recursive: recursive);
    applyFixesProgress.complete();
  }
}
