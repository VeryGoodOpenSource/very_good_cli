import 'dart:async';

import 'package:atmos_cli/src/commands/create/templates/templates.dart';
import 'package:atmos_cli/src/logger_extension.dart';
import 'package:mason/mason.dart';
import 'package:path/path.dart' as path;
import 'package:universal_io/io.dart';

/// {@template very_good_core_template}
/// A core Flutter app template customized for Avila Tek projects. Forked from
/// the `very_good_core` template.
/// {@endtemplate}
class AvilaTekCoreTemplate extends Template {
  /// {@macro very_good_core_template}
  AvilaTekCoreTemplate()
      : super(
          name: 'core',
          bundle: atmosCoreBundle,
          help: 'Generate an Avila Tek ⛰️ Flutter application.',
        );

  @override
  Future<void> onGenerateComplete(Logger logger, Directory outputDir) async {
    if (await installFlutterPackages(logger, outputDir)) {
      await applyDartFixes(logger, outputDir);
    }

    await _runSetupScript(logger, outputDir);

    _logSummary(logger, outputDir);
  }

  Future<void> _runSetupScript(Logger logger, Directory outputDir) async {
    const scriptName = 'setup.sh';

    final setupScriptPath = path.join(outputDir.path, scriptName);

    if (!File(setupScriptPath).existsSync()) {
      logger.err('The setup.sh script was not found at $setupScriptPath.');
      return;
    }

    try {
      // Asegurar permisos de ejecución para setup.sh
      final chmodResult = await Process.run(
        'chmod',
        ['+x', setupScriptPath],
        // workingDirectory: outputDir.path,
        runInShell: true,
      );

      if (chmodResult.exitCode != 0) {
        logger.err(
          // ignore: lines_longer_than_80_chars
          'Failed to set executable permissions for $scriptName:\n${chmodResult.stderr}',
        );
        return;
      }

      var process = await Process.start(
        'bash', // Comando para ejecutar scripts en bash
        [scriptName], // Ruta al script
        workingDirectory: outputDir.path, // Directorio de trabajo
        runInShell: true, // Habilitar ejecución en shell
        environment: {'FORCE_COLOR': 'true'}, // Forzar colores
        mode: ProcessStartMode.inheritStdio,
      );

      // Esperar a que el proceso termine
      final exitCode = await process.exitCode;

      if (exitCode != 0) {
        logger.err('Failed to execute $scriptName.');
      }
    } catch (e) {
      logger.err('An error occurred while executing $scriptName: $e');
    }
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
      ..created('Created an Avila Tek app! ⛰️')
      ..info(details);
  }
}
