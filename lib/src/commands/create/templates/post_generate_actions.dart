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
    final installDependenciesDone = logger
        .progress(
          'Running "flutter pub get" in ${outputDir.path}',
        )
        .complete;
    await Flutter.pubGet(cwd: outputDir.path);
    installDependenciesDone();
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
    final installDependenciesDone = logger
        .progress(
          'Running "flutter packages get" in ${outputDir.path}',
        )
        .complete;
    await Flutter.packagesGet(cwd: outputDir.path, recursive: recursive);
    installDependenciesDone();
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
    final applyFixesDone = logger
        .progress(
          'Running "dart fix --apply" in ${outputDir.path}',
        )
        .complete;
    await Dart.applyFixes(cwd: outputDir.path, recursive: recursive);
    applyFixesDone();
  }
}
