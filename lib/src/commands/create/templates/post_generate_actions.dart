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

  return Dart.pubGet(
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

  return Flutter.pubGet(
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
