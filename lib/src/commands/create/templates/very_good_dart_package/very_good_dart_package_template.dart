import 'package:mason/mason.dart';
import 'package:universal_io/io.dart';
import 'package:very_good_cli/src/commands/create/templates/templates.dart';
import 'package:very_good_cli/src/logger_extension.dart';

/// {@template dart_pkg_template}
/// A Dart package template.
/// {@endtemplate}
class DartPkgTemplate() extends Template {
  /// {@macro dart_pkg_template}
  this
    : super(
        name: 'dart_pkg',
        bundle: veryGoodDartPackageBundle,
        help: 'Generate a Very Good Dart package.',
      );

  /// `org_name` is not passed yet, so the copyright holder in `LICENSE`
  /// renders empty.
  @override
  Set<String> get defaultedVars => const {'org_name'};

  @override
  Future<void> onGenerateComplete(Logger logger, Directory outputDir) async {
    if (await installDartPackages(logger, outputDir)) {
      await applyDartFixes(logger, outputDir);
    }
    _logSummary(logger);
  }

  void _logSummary(Logger logger) {
    logger
      ..info('\n')
      ..created('Created a Very Good Dart Package! 🦄')
      ..info('\n');
  }
}
