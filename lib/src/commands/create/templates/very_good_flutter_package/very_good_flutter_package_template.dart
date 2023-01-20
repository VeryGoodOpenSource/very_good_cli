import 'package:mason/mason.dart';
import 'package:universal_io/io.dart';
import 'package:very_good_cli/src/commands/create/templates/templates.dart';
import 'package:very_good_cli/src/logger_extension.dart';

/// {@template flutter_pkg_template}
/// A Flutter package template.
/// {@endtemplate}
class FlutterPkgTemplate extends Template {
  /// {@macro flutter_pkg_template}
  FlutterPkgTemplate()
      : super(
          name: 'flutter_pkg',
          bundle: veryGoodFlutterPackageBundle,
          help: 'Generate a Very Good Flutter package.',
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
      ..created('Created a Very Good Flutter Package! 🦄')
      ..info('\n');
  }
}
