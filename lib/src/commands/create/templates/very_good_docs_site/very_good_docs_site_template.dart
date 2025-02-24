import 'dart:io';

import 'package:mason/mason.dart';
import 'package:very_good_cli/src/commands/create/templates/templates.dart';
import 'package:very_good_cli/src/logger_extension.dart';

/// {@template docs_site_template}
/// A documentation site template.
/// {@endtemplate}
class VeryGoodDocsSiteTemplate extends Template {
  /// {@macro docs_site_template}
  VeryGoodDocsSiteTemplate()
    : super(
        name: 'docs_site',
        bundle: veryGoodDocsSiteBundle,
        help: 'Generate a Very Good documentation site.',
      );

  @override
  Future<void> onGenerateComplete(Logger logger, Directory outputDir) async {
    _logSummary(logger);
  }

  void _logSummary(Logger logger) {
    logger
      ..info('\n')
      ..created('Created a Very Good documentation site! 🦄')
      ..info('\n');
  }
}
