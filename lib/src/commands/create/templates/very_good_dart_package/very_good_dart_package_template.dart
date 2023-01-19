import 'package:mason/mason.dart';
import 'package:universal_io/io.dart';
import 'package:very_good_cli/src/commands/create/templates/templates.dart';
import 'package:very_good_cli/src/logger_extension.dart';

/// {@template dart_pkg_template}
/// A Dart package template.
/// {@endtemplate}
class DartPkgTemplate extends Template {
  /// {@macro dart_pkg_template}
  DartPkgTemplate()
      : super(
          name: 'dart_pkg',
          bundle: veryGoodDartPackageBundle,
          help: 'Generate a Very Good Dart package.',
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
      ..created('Created a Very Good Dart Package! 🦄')
      ..info('\n');
  }
}
