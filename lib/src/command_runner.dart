import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:io/ansi.dart';
import 'package:io/io.dart';
import 'package:mason/mason.dart';
import 'package:usage/usage_io.dart';
import 'package:very_good_cli/src/commands/commands.dart';

import 'version.dart';

// The Google Analytics tracking ID.
const _gaTrackingId = 'UA-117465969-4';

// The Google Analytics Application Name.
const _gaAppName = 'very-good-cli';

/// {@template very_good_command_runner}
/// A [CommandRunner] for the Very Good CLI.
/// {@endtemplate}
class VeryGoodCommandRunner extends CommandRunner<int> {
  /// {@macro very_good_command_runner}
  VeryGoodCommandRunner({Analytics analytics, Logger logger})
      : _logger = logger ?? Logger(),
        _analytics =
            analytics ?? AnalyticsIO(_gaTrackingId, _gaAppName, packageVersion),
        super('very_good', '🦄 A Very Good Command Line Interface') {
    argParser
      ..addFlag(
        'version',
        negatable: false,
        help: 'Print the current version.',
      )
      ..addOption(
        'analytics',
        help: 'Anonymous usage statistics settings.',
        allowed: ['true', 'false'],
        allowedHelp: {
          'true': 'Enable anonymous usage statistics',
          'false': 'Disable anonymous usage statistics',
        },
      );
    addCommand(CreateCommand(analytics: _analytics, logger: logger));
  }

  /// Standard timeout duration for the CLI.
  static const timeout = Duration(milliseconds: 500);

  final Logger _logger;
  final Analytics _analytics;

  @override
  Future<int> run(Iterable<String> args) async {
    try {
      if (_analytics.firstRun) {
        final response = _logger.prompt(lightGray.wrap(
          '''+---------------------------------------------------+
|           Welcome to the Very Good CLI!           |
+---------------------------------------------------+
| We would like to collect anonymous                |
| usage statistics in order to improve the tool.    |
| Would you like to opt-into help us improve? [y/n] |
+---------------------------------------------------+\n''',
        ));
        final normalizedResponse = response.toLowerCase().trim();
        _analytics.enabled =
            normalizedResponse == 'y' || normalizedResponse == 'yes';
      }
      final _argResults = parse(args);
      return await runCommand(_argResults) ?? ExitCode.success.code;
    } on FormatException catch (e, stackTrace) {
      _logger
        ..err(e.message)
        ..err('$stackTrace')
        ..info('')
        ..info(usage);
      return ExitCode.usage.code;
    } on UsageException catch (e) {
      _logger
        ..err(e.message)
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
    if (topLevelResults['analytics'] != null) {
      final optIn = topLevelResults['analytics'] == 'true' ? true : false;
      _analytics.enabled = optIn;
      _logger.info('analytics ${_analytics.enabled ? 'enabled' : 'disabled'}.');
      return ExitCode.success.code;
    }
    return super.runCommand(topLevelResults);
  }
}
