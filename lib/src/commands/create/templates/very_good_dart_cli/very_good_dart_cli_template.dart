import 'dart:io';

import 'package:mason_logger/mason_logger.dart';
import 'package:very_good_cli/src/commands/create/templates/templates.dart';

/// {@template dart_cli_template}
/// A Dart CLI application template.
/// {@endtemplate}
class VeryGoodDartCLITemplate extends Template {
  /// {@macro dart_cli_template}
  VeryGoodDartCLITemplate()
      : super(
          name: 'dart_cli',
          bundle: veryGoodDartCliBundle,
          help: 'Generate a Very Good Dart CLI application.',
        );

  @override
  Future<void> onGenerateComplete(Logger logger, Directory outputDir) async {
    await installDartPackages(logger, outputDir);
    await applyDartFixes(logger, outputDir);
    _logSummary(logger);
  }

  void _logSummary(Logger logger) {
    logger
      ..info('\n')
      ..alert('Created a Very Good Dart CLI application! 🦄')
      ..info('\n');
  }
}
