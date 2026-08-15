import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:mason/mason.dart';
import 'package:meta/meta.dart';
import 'package:universal_io/io.dart';
import 'package:very_good_cli/src/cli/cli.dart';
import 'package:very_good_cli/src/workspace_matrix/workspace_matrix.dart';

/// Signature for resolving files changed against a git base ref.
typedef GitChangedFiles =
    Future<List<String>> Function({
      required String baseRef,
      required String cwd,
      required Logger logger,
    });

/// Signature for resolving affected workspace projects.
typedef ResolveAffectedWorkspaceProjects =
    List<WorkspaceProject> Function({
      required Directory rootDirectory,
      required List<String> changedFiles,
    });

/// {@template workspace_matrix_command}
/// `very_good workspace matrix` command.
/// {@endtemplate}
class WorkspaceMatrixCommand extends Command<int> {
  /// {@macro workspace_matrix_command}
  WorkspaceMatrixCommand({
    required this.logger,
    GitChangedFiles? gitChangedFiles,
    ResolveAffectedWorkspaceProjects? resolveAffectedProjects,
  }) : _gitChangedFiles = gitChangedFiles ?? _defaultGitChangedFiles,
       _resolveAffectedProjects =
           resolveAffectedProjects ?? resolveAffectedWorkspaceProjects {
    argParser.addOption(
      'base',
      help: 'Base git ref used for diffing changes (for example, origin/main).',
      valueHelp: 'ref',
    );
  }

  /// Logger used by this command.
  final Logger logger;
  final GitChangedFiles _gitChangedFiles;
  final ResolveAffectedWorkspaceProjects _resolveAffectedProjects;

  /// [ArgResults] which can be overridden for testing.
  @visibleForTesting
  ArgResults? argResultOverrides;

  ArgResults get _argResults => argResultOverrides ?? argResults!;

  @override
  String get description =>
      'Return a JSON list of affected projects in the current workspace.';

  @override
  String get invocation => 'very_good workspace matrix [arguments]';

  @override
  String get name => 'matrix';

  @override
  Future<int> run() async {
    if (_argResults.rest.isNotEmpty) {
      usageException('This command does not accept positional arguments.');
    }

    final baseRef = (_argResults['base'] as String?)?.trim();
    if (baseRef == null || baseRef.isEmpty) {
      usageException('Missing required option: --base <ref>.');
    }

    try {
      final cwd = Directory.current.path;
      final changedFiles = await _gitChangedFiles(
        baseRef: baseRef,
        cwd: cwd,
        logger: logger,
      );

      final affectedProjects = _resolveAffectedProjects(
        rootDirectory: Directory(cwd),
        changedFiles: changedFiles,
      );

      logger.info(
        jsonEncode(
          affectedProjects.map((project) => project.toJson()).toList(),
        ),
      );
      return ExitCode.success.code;
    } on UsageException {
      rethrow;
    } on Exception catch (error) {
      logger.err('$error');
      return ExitCode.unavailable.code;
    }
  }
}

Future<List<String>> _defaultGitChangedFiles({
  required String baseRef,
  required String cwd,
  required Logger logger,
}) {
  return Git.changedFiles(baseRef, cwd: cwd, logger: logger);
}
