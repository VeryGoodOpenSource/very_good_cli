import 'dart:io';

import 'package:mason/mason.dart';
import 'package:very_good_cli/src/commands/create/templates/templates.dart';
import 'package:very_good_cli/src/logger_extension.dart';

/// {@template wear_app_template}
/// A template for Wear OS apps.
/// {@endtemplate}
class VeryGoodWearAppTemplate extends Template {
  /// {@macro wear_app_template}
  VeryGoodWearAppTemplate()
      : super(
          name: 'wear',
          bundle: veryGoodWearAppBundle,
          help: 'Generate a Very Good Flutter Wear OS application.',
        );

  @override
  Future<void> onGenerateComplete(Logger logger, Directory outputDir) async {
    await installFlutterPackages(logger, outputDir);
    await applyDartFixes(logger, outputDir);
    _logSummary(logger);
  }

  void _logSummary(Logger logger) {
    logger
      ..info('\n')
      ..created('Created a Very Good Wear OS app! ⌚️🦄')
      ..info('\n');
  }
}
