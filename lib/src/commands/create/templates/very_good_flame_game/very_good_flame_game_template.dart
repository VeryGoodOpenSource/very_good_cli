import 'dart:io';

import 'package:mason/mason.dart';
import 'package:very_good_cli/src/commands/create/templates/templates.dart';
import 'package:very_good_cli/src/logger_extension.dart';

/// {@template flame_game_template}
/// A Flame Game template.
/// {@endtemplate}
class VeryGoodFlameGameTemplate extends Template {
  /// {@macro flame_game_template}
  VeryGoodFlameGameTemplate()
      : super(
          name: 'flame_game',
          bundle: veryGoodFlameGameBundle,
          help: 'Generate a Very Good Flame game.',
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
      ..created('Created a Very Good Game powered by Flame! 🔥🦄')
      ..info('\n');
  }
}
