import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:cli_completion/cli_completion.dart';
import 'package:mason/mason.dart' hide packageVersion;
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import 'package:pub_updater/pub_updater.dart';
import 'package:universal_io/io.dart';
import 'package:very_good_cli/src/commands/commands.dart';
import 'package:very_good_cli/src/logger_extension.dart';
import 'package:very_good_cli/src/version.dart';

/// The package name.
const packageName = 'very_good_cli';

/// {@template very_good_command_runner}
/// A [CommandRunner] for the Very Good CLI.
/// {@endtemplate}
class VeryGoodCommandRunner extends CompletionCommandRunner<int> {
  /// {@macro very_good_command_runner}
  VeryGoodCommandRunner({
    Logger? logger,
    PubUpdater? pubUpdater,
    Map<String, String>? environment,
  })  : _logger = logger ?? Logger(),
        _pubUpdater = pubUpdater ?? PubUpdater(),
        _environment = environment ?? Platform.environment,
        super('very_good', '🦄 A Very Good Command-Line Interface') {
    argParser
      ..addFlag(
        'version',
        negatable: false,
        help: 'Print the current version.',
      )
      ..addFlag(
        'verbose',
        help: 'Noisy logging, including all shell commands executed.',
      );
    addCommand(CreateCommand(logger: _logger));
    addCommand(PackagesCommand(logger: _logger));
    addCommand(TestCommand(logger: _logger));
    addCommand(UpdateCommand(logger: _logger, pubUpdater: pubUpdater));
  }

  /// Standard timeout duration for the CLI.
  static const timeout = Duration(milliseconds: 500);

  final Logger _logger;
  final PubUpdater _pubUpdater;

  /// Map of environments information.
  Map<String, String> get environment => environmentOverride ?? _environment;
  final Map<String, String> _environment;

  /// Boolean for checking if windows, which can be overridden for
  /// testing purposes.
  @visibleForTesting
  bool? isWindowsOverride;
  bool get _isWindows => isWindowsOverride ?? Platform.isWindows;

  @override
  void printUsage() => _logger.info(usage);

  @override
  Future<int> run(Iterable<String> args) async {
    try {
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

    int? exitCode = ExitCode.unavailable.code;
    if (topLevelResults['version'] == true) {
      _logger.info(packageVersion);
      exitCode = ExitCode.success.code;
    } else {
      exitCode = await super.runCommand(topLevelResults);
    }
    if (topLevelResults.command?.name != UpdateCommand.commandName) {
      await _checkForUpdates();
    }
    _showThankYou();
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

  void _showThankYou() {
    if (environment.containsKey('CI')) return;

    final versionFile = File(
      path.join(_configDir.path, 'version'),
    )..createSync(recursive: true);

    if (versionFile.readAsStringSync() == packageVersion) return;
    versionFile.writeAsStringSync(packageVersion);

    _logger.wrap(
      lightMagenta.wrap('''

Thank you for using Very Good Ventures open source tools!
Don't forget to fill out this form to get information on future updates and releases here: ${lightBlue.wrap(link(uri: Uri.parse('https://verygood.ventures/open-source/cli/subscribe-latest-tool-updates')))}'''),
      print: _logger.info,
    );
  }

  Directory get _configDir {
    if (_isWindows) {
      // Use localappdata on windows
      final localAppData = environment['LOCALAPPDATA']!;
      return Directory(path.join(localAppData, 'VeryGoodCLI'));
    } else {
      // Try using XDG config folder
      var dirPath = environment['XDG_CONFIG_HOME'];
      // Fallback to $HOME if not following XDG specification
      if (dirPath == null || dirPath.isEmpty) {
        dirPath = environment['HOME'];
      }
      return Directory(path.join(dirPath!, '.very_good_cli'));
    }
  }
}
