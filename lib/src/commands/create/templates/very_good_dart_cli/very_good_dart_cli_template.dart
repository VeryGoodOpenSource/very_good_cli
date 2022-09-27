import 'dart:io';

import 'package:loka_flutter_cli/src/commands/create/templates/templates.dart';
import 'package:loka_flutter_cli/src/logger_extension.dart';
import 'package:mason/mason.dart';

/// {@template dart_cli_template}
/// A Dart CLI application template.
/// {@endtemplate}
class VeryGoodDartCLITemplate extends Template {
  /// {@macro dart_cli_template}
  VeryGoodDartCLITemplate()
      : super(
          name: 'dart_cli',
          bundle: veryGoodDartCliBundle,
          help: 'Generate a Dart CLI application.',
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
      ..created('Created a Dart CLI application! ')
      ..info('\n');
  }
}
