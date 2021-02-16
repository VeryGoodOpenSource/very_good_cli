import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:io/io.dart';
import 'package:mason/mason.dart';
import 'package:very_good_cli/src/commands/commands.dart';

import 'version.dart';

/// {@template very_good_command_runner}
/// A [CommandRunner] for the Very Good CLI.
/// {@endtemplate}
class VeryGoodCommandRunner extends CommandRunner<int> {
  /// {@macro very_good_command_runner}
  VeryGoodCommandRunner({Logger logger})
      : _logger = logger ?? Logger(),
        super('very_good', '🦄 A Very Good Command Line Interface') {
    argParser.addFlag(
      'version',
      negatable: false,
      help: 'Print the current version.',
    );
    addCommand(CreateCommand(logger: logger));
  }

  final Logger _logger;

  @override
  Future<int> run(Iterable<String> args) async {
    try {
      final _argResults = parse(args);
      return await runCommand(_argResults) ?? ExitCode.success.code;
    } on FormatException catch (e, stackTrace) {
      _logger
        ..err(e.message)
        ..err('$stackTrace')
        ..info('')
        ..info(usage);
      return ExitCode.usage.code;
    } on UsageException catch (e, stackTrace) {
      _logger
        ..err(e.message)
        ..err('$stackTrace')
        ..info('')
        ..info(usage);
      return ExitCode.usage.code;
    }
  }

  @override
  Future<int> runCommand(ArgResults topLevelResults) async {
    if (topLevelResults['version'] == true) {
      _logger.info('very_good version: $packageVersion');
      return ExitCode.success.code;
    }
    return super.runCommand(topLevelResults);
  }
}
