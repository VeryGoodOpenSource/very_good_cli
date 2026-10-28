import 'package:mason/mason.dart';
import 'package:path/path.dart' as p;
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
  if (!isDartInstalled) return false;

  return await Dart.pubGet(
    cwd: outputDir.path,
    recursive: recursive,
    logger: logger,
  );
}

/// Runs `flutter pub get` in the [outputDir].
///
/// Completes with `true` is the execution was successful, `false` otherwise.
Future<bool> installFlutterPackages(
  Logger logger,
  Directory outputDir, {
  bool recursive = false,
}) async {
  final isFlutterInstalled = await Flutter.installed(logger: logger);
  if (!isFlutterInstalled) return false;

  return await Flutter.pubGet(
    cwd: outputDir.path,
    recursive: recursive,
    logger: logger,
  );
}

/// Runs `dart run pigeon` for each platform directory that contains
/// a `pigeons/messages.dart` input file in the [outputDir].
///
/// This is a no-op if Dart is not installed or if no pigeon inputs are found,
/// which ensures backwards compatibility with template versions that do not
/// use Pigeon.
Future<void> generatePigeonCode(Logger logger, Directory outputDir) async {
  final isDartInstalled = await Dart.installed(logger: logger);
  if (!isDartInstalled) return;

  final pigeonDirs = outputDir.listSync().whereType<Directory>().where(
    (d) => File(p.join(d.path, 'pigeons', 'messages.dart')).existsSync(),
  );

  if (pigeonDirs.isEmpty) return;

  final progress = logger.progress(
    'Running "dart run pigeon" in ${outputDir.path}',
  );

  await Future.wait(
    pigeonDirs.map(
      (dir) => Dart.runPigeon(
        cwd: dir.path,
        logger: logger,
        input: 'pigeons/messages.dart',
      ),
    ),
  );

  progress.complete();
}

/// Runs `dart fix --apply` in the [outputDir].
Future<void> applyDartFixes(
  Logger logger,
  Directory outputDir, {
  bool recursive = false,
}) async {
  final isDartInstalled = await Dart.installed(logger: logger);
  if (!isDartInstalled) return;

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

/// Marks the Dart files in the `bin` directory of [outputDir] as executable,
/// so entrypoints with a `#!/usr/bin/env dart` shebang can be run directly.
///
/// Mason does not preserve file permissions, so this is done after
/// generation. This is a no-op on Windows or when there are no entrypoints.
Future<void> makeEntrypointsExecutable(
  Logger logger,
  Directory outputDir,
) async {
  if (Platform.isWindows) return;

  final binDirectory = Directory(p.join(outputDir.path, 'bin'));
  if (!binDirectory.existsSync()) return;

  final entrypoints = binDirectory
      .listSync()
      .whereType<File>()
      .where((file) => p.extension(file.path) == '.dart')
      .map((file) => file.path)
      .toList();
  if (entrypoints.isEmpty) return;

  await Chmod.makeExecutable(entrypoints, logger: logger);
}
