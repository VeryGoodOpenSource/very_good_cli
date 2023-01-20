import 'package:mason/mason.dart';
import 'package:universal_io/io.dart';
import 'package:very_good_cli/src/commands/create/templates/templates.dart';
import 'package:very_good_cli/src/logger_extension.dart';

/// {@template flutter_plugin_template}
/// A Flutter plugin template.
/// {@endtemplate}
class FlutterPluginTemplate extends Template {
  /// {@macro flutter_pkg_template}
  FlutterPluginTemplate()
      : super(
          name: 'flutter_plugin',
          bundle: veryGoodFlutterPluginBundle,
          help: 'Generate a Very Good Flutter plugin.',
        );

  @override
  Future<void> onGenerateComplete(Logger logger, Directory outputDir) async {
    await installFlutterPackages(logger, outputDir, recursive: true);
    await applyDartFixes(logger, outputDir, recursive: true);
    _logSummary(logger);
  }

  void _logSummary(Logger logger) {
    logger
      ..info('\n')
      ..created('Created a Very Good Flutter Plugin! 🦄')
      ..info('\n');
  }
}
