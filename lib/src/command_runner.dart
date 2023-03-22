import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:cli_completion/cli_completion.dart';
import 'package:mason/mason.dart' hide packageVersion;
import 'package:pub_updater/pub_updater.dart';
import 'package:usage/usage_io.dart';
import 'package:very_good_cli/src/commands/commands.dart';
import 'package:very_good_cli/src/version.dart';

// The Google Analytics tracking ID.
const _gaTrackingId = 'UA-117465969-4';

// The Google Analytics Application Name.
const _gaAppName = 'very-good-cli';

/// The package name.
const packageName = 'very_good_cli';

/// {@template very_good_command_runner}
/// A [CommandRunner] for the Very Good CLI.
/// {@endtemplate}
class VeryGoodCommandRunner extends CompletionCommandRunner<int> {
  /// {@macro very_good_command_runner}
  VeryGoodCommandRunner({
    Analytics? analytics,
    Logger? logger,
    PubUpdater? pubUpdater,
  })  : _logger = logger ?? Logger(),
        _analytics =
            analytics ?? AnalyticsIO(_gaTrackingId, _gaAppName, packageVersion),
        _pubUpdater = pubUpdater ?? PubUpdater(),
        super('very_good', '🦄 A Very Good Command-Line Interface') {
    argParser
      ..addFlag(
        'version',
        negatable: false,
        help: 'Print the current version.',
      )
      ..addOption(
        'analytics',
        help: 'Toggle anonymous usage statistics.',
        allowed: ['true', 'false'],
        allowedHelp: {
          'true': 'Enable anonymous usage statistics',
          'false': 'Disable anonymous usage statistics',
        },
      )
      ..addFlag(
        'verbose',
        help: 'Noisy logging, including all shell commands executed.',
      );
    addCommand(CreateCommand(analytics: _analytics, logger: _logger));
    addCommand(PackagesCommand(logger: _logger));
    addCommand(TestCommand(logger: _logger));
    addCommand(UpdateCommand(logger: _logger, pubUpdater: pubUpdater));
  }

  /// Standard timeout duration for the CLI.
  static const timeout = Duration(milliseconds: 500);

  final Logger _logger;
  final Analytics _analytics;
  final PubUpdater _pubUpdater;

  @override
  void printUsage() => _logger.info(usage);

  @override
  Future<int> run(Iterable<String> args) async {
    try {
      if (_analytics.firstRun) {
        final response = _logger.prompt(
          lightGray.wrap(
            '''
+---------------------------------------------------+
|           Welcome to the Very Good CLI!           |
+---------------------------------------------------+
| We would like to collect anonymous                |
| usage statistics in order to improve the tool.    |
| Would you like to opt-into help us improve? [y/n] |
+---------------------------------------------------+\n''',
          ),
        );
        final normalizedResponse = response.toLowerCase().trim();
        _analytics.enabled =
            normalizedResponse == 'y' || normalizedResponse == 'yes';
      }
      final argResults = parse(args);

      if (argResults['verbose'] == true) {
        _logger.level = Level.verbose;
      }
      return await runCommand(argResults) ?? ExitCode.success.code;
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
        ..info(e.usage);
      return ExitCode.usage.code;
    }
  }

  @override
  Future<int?> runCommand(ArgResults topLevelResults) async {
    if (topLevelResults.command?.name == 'completion') {
      await super.runCommand(topLevelResults);
      return ExitCode.success.code;
    }

    _logger
      ..detail('Argument information:')
      ..detail('  Top level options:');
    for (final option in topLevelResults.options) {
      if (topLevelResults.wasParsed(option)) {
        _logger.detail('  - $option: ${topLevelResults[option]}');
      }
    }
    if (topLevelResults.command != null) {
      final commandResult = topLevelResults.command!;
      _logger
        ..detail('  Command: ${commandResult.name}')
        ..detail('    Command options:');
      for (final option in commandResult.options) {
        if (commandResult.wasParsed(option)) {
          _logger.detail('    - $option: ${commandResult[option]}');
        }
      }

      if (commandResult.command != null) {
        final subCommandResult = commandResult.command!;
        _logger.detail('    Command sub command: ${subCommandResult.name}');
      }
    }

    if (_analytics.enabled) {
      _logger.detail('Running with analytics enabled.');
    }

    int? exitCode = ExitCode.unavailable.code;
    if (topLevelResults['version'] == true) {
      _logger.info(packageVersion);
      exitCode = ExitCode.success.code;
    } else if (topLevelResults['analytics'] != null) {
      final optIn = topLevelResults['analytics'] == 'true';
      _analytics.enabled = optIn;
      _logger.info('analytics ${_analytics.enabled ? 'enabled' : 'disabled'}.');
      exitCode = ExitCode.success.code;
    } else {
      exitCode = await super.runCommand(topLevelResults);
    }
    if (topLevelResults.command?.name != UpdateCommand.commandName) {
      await _checkForUpdates();
    }
    return exitCode;
  }

  Future<void> _checkForUpdates() async {
    try {
      final latestVersion = await _pubUpdater.getLatestVersion(packageName);
      final isUpToDate = packageVersion == latestVersion;
      if (!isUpToDate) {
        _logger
          ..info('')
          ..info(
            '''
${lightYellow.wrap('Update available!')} ${lightCyan.wrap(packageVersion)} \u2192 ${lightCyan.wrap(latestVersion)}
${lightYellow.wrap('Changelog:')} ${lightCyan.wrap('https://github.com/verygoodopensource/very_good_cli/releases/tag/v$latestVersion')}
Run ${lightCyan.wrap('very_good update')} to update''',
          );
      }
    } catch (_) {}
  }
}
