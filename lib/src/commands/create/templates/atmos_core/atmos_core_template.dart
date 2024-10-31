import 'package:mason/mason.dart';
import 'package:path/path.dart' as path;
import 'package:universal_io/io.dart';
import 'package:atmos_cli/src/commands/create/templates/templates.dart';
import 'package:atmos_cli/src/logger_extension.dart';

/// {@template very_good_core_template}
/// A core Flutter app template.
/// {@endtemplate}
class VeryGoodCoreTemplate extends Template {
  /// {@macro very_good_core_template}
  VeryGoodCoreTemplate()
      : super(
          name: 'core',
          bundle: atmosCoreBundle,
          help: 'Generate an Avila Tek Flutter application.',
        );

  @override
  Future<void> onGenerateComplete(Logger logger, Directory outputDir) async {
    if (await installFlutterPackages(logger, outputDir)) {
      await applyDartFixes(logger, outputDir);
    }
    _logSummary(logger, outputDir);
  }

  void _logSummary(Logger logger, Directory outputDir) {
    final relativePath = path.relative(
      outputDir.path,
      from: Directory.current.path,
    );

    final projectPath = relativePath;
    final projectPathLink =
        link(uri: Uri.parse(projectPath), message: projectPath);

    final readmePath = path.join(relativePath, 'README.md');
    final readmePathLink =
        link(uri: Uri.parse(readmePath), message: readmePath);

    final details = '''
  • To get started refer to $readmePathLink
  • Your project code is in $projectPathLink
''';

    logger
      ..info('\n')
      ..created('Created an Avila Tek App! ⛰️')
      ..info(details);
  }
}
