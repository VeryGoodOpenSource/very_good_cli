import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:mason/mason.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import 'package:universal_io/io.dart';
import 'package:very_good_cli/src/cli/cli.dart';
import 'package:very_good_cli/src/very_good_config/very_good_config.dart';

/// Options for configuring the `very_good packages get` command.
class PackagesGetOptions {
  PackagesGetOptions._({required this.recursive, required this.ignore});

  /// Parses [ArgResults] into a [PackagesGetOptions] instance.
  ///
  /// When [config] is provided, its values are used as defaults for any
  /// option that was not explicitly parsed on the command line.
  factory PackagesGetOptions.parse(
    ArgResults argResults, {
    VeryGoodConfig config = VeryGoodConfig.empty,
  }) {
    final getConfig = config.packages.get;

    final recursive = argResults.resolve(
      'recursive',
      getConfig.recursive,
    );
    final ignore = argResults.resolve<List<String>>(
      'ignore',
      getConfig.ignore,
    );

    return PackagesGetOptions._(
      recursive: recursive,
      ignore: ignore.toSet(),
    );
  }

  /// Whether to install dependencies recursively for all nested packages.
  final bool recursive;

  /// Packages to exclude from installing dependencies.
  final Set<String> ignore;
}

/// {@template packages_get_command}
/// `very_good packages get` command for installing packages.
/// {@endtemplate}
class PackagesGetCommand extends Command<int> {
  /// {@macro packages_get_command}
  PackagesGetCommand({Logger? logger}) : _logger = logger ?? Logger() {
    argParser
      ..addFlag(
        'recursive',
        abbr: 'r',
        help: 'Install dependencies recursively for all nested packages.',
        negatable: false,
      )
      ..addMultiOption(
        'ignore',
        help: 'Exclude packages from installing dependencies.',
      );
  }

  final Logger _logger;

  @override
  String get description => 'Get packages in a Dart or Flutter project.';

  @override
  String get name => 'get';

  /// [ArgResults] which can be overridden for testing.
  @visibleForTesting
  ArgResults? argResultOverrides;

  ArgResults get _argResults => argResultOverrides ?? argResults!;

  @override
  Future<int> run() async {
    if (_argResults.rest.length > 1) {
      usageException('Too many arguments');
    }

    final target = _argResults.rest.length == 1 ? _argResults.rest[0] : '.';
    final targetPath = path.normalize(Directory(target).absolute.path);

    final config = VeryGoodConfig.load(Directory(targetPath), logger: _logger);
    if (config == null) return ExitCode.config.code;

    final options = PackagesGetOptions.parse(_argResults, config: config);

    final isFlutterInstalled = await Flutter.installed(logger: _logger);
    if (!isFlutterInstalled) {
      _logger.err(
        'Could not find Flutter SDK. '
        'Please ensure it is installed and added to your PATH. '
        'For troubleshooting, see https://docs.flutter.dev/install/troubleshoot',
      );
      return ExitCode.unavailable.code;
    }
    try {
      await Flutter.pubGet(
        cwd: targetPath,
        recursive: options.recursive,
        ignore: options.ignore,
        logger: _logger,
      );
    } on PubspecNotFound catch (_) {
      _logger.err('Could not find a pubspec.yaml in $targetPath');
      return ExitCode.noInput.code;
    } on Exception catch (error) {
      _logger.err('$error');
      return ExitCode.unavailable.code;
    }
    return ExitCode.success.code;
  }
}
