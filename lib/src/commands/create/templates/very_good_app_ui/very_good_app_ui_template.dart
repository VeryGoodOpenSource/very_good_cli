import 'package:mason/mason.dart';
import 'package:universal_io/io.dart';
import 'package:very_good_cli/src/commands/create/templates/templates.dart';
import 'package:very_good_cli/src/logger_extension.dart';

/// {@template app_ui_template}
/// A Flutter app UI package template.
/// {@endtemplate}
class AppUiTemplate extends Template {
  /// {@macro app_ui_template}
  AppUiTemplate()
    : super(
        name: 'app_ui',
        bundle: veryGoodAppUiBundle,
        help: 'Generate a Very Good App UI package.',
      );

  @override
  Future<void> onGenerateComplete(Logger logger, Directory outputDir) async {
    if (await installFlutterPackages(logger, outputDir)) {
      await applyDartFixes(logger, outputDir);
    }
    _logSummary(logger);
  }

  void _logSummary(Logger logger) {
    logger
      ..info('\n')
      ..created('Created a Very Good App UI Package! 🦄')
      ..info('\n');
  }
}
