import 'package:mason/mason.dart';
import 'package:universal_io/io.dart';
import 'package:very_good_cli/src/commands/create/templates/templates.dart';
import 'package:very_good_cli/src/logger_extension.dart';

/// {@template very_good_workspace_template}
/// A multi-package Dart/Flutter workspace template.
/// {@endtemplate}
class VeryGoodWorkspaceTemplate extends Template {
  /// {@macro very_good_workspace_template}
  VeryGoodWorkspaceTemplate()
    : super(
        name: 'workspace',
        bundle: veryGoodWorkspaceBundle,
        help: 'Generate a Very Good multi-package workspace.',
      );

  @override
  Future<void> onGenerateComplete(Logger logger, Directory outputDir) async {
    _logSummary(logger);
  }

  void _logSummary(Logger logger) {
    logger
      ..info('\n')
      ..created('Created a Very Good Workspace! 🦄')
      ..info('\n')
      ..info(
        'Add member packages from the workspace root with '
        '"very_good create <subcommand>" and they will be registered '
        'automatically.',
      )
      ..info('\n');
  }
}
