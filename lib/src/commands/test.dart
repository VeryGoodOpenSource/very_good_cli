import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:mason/mason.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import 'package:universal_io/io.dart';
import 'package:very_good_cli/src/cli/cli.dart';

/// {@template test_command}
/// `very_good test` command for running tests.
/// {@endtemplate}
class TestCommand extends Command<int> {
  /// {@macro test_command}
  TestCommand({Logger? logger}) : _logger = logger ?? Logger() {
    argParser
      ..addFlag(
        'recursive',
        abbr: 'r',
        help: 'Run tests recursively for all nested packages.',
        negatable: false,
      )
      ..addFlag(
        'coverage',
        help: 'Collects the code coverage during the test.',
        negatable: false,
      )
      ..addOption(
        'min-coverage',
        help: 'Sets the minimum acceptable coverage.',
      );
  }

  final Logger _logger;

  @override
  String get description => 'Run tests in a Dart or Flutter project.';

  @override
  String get name => 'test';

  /// [ArgResults] which can be overridden for testing.
  @visibleForTesting
  ArgResults? argResultOverrides;

  ArgResults get _argResults => argResultOverrides ?? argResults!;

  @override
  Future<int> run() async {
    if (_argResults.rest.length > 1) {
      throw UsageException('Too many arguments', usage);
    }

    final recursive = _argResults['recursive'] as bool;
    final target = _argResults.rest.length == 1 ? _argResults.rest[0] : '.';
    final targetPath = path.normalize(Directory(target).absolute.path);
    final collectCoverage = _argResults['coverage'] as bool;
    final minCoverage = double.tryParse(
      _argResults['min-coverage'] as String? ?? '',
    );
    final isFlutterInstalled = await Flutter.installed();
    if (isFlutterInstalled) {
      try {
        await Flutter.test(
          cwd: targetPath,
          recursive: recursive,
          stdout: _logger.write,
          stderr: _logger.err,
          collectCoverage: collectCoverage,
          minCoverage: minCoverage,
        );
      } on PubspecNotFound catch (_) {
        _logger.err('Could not find a pubspec.yaml in $targetPath');
        return ExitCode.noInput.code;
      } on MinCoverageNotMet catch (e) {
        _logger.err(
          'Expected coverage >= "$minCoverage" but received "${e.coverage}".',
        );
        return ExitCode.unavailable.code;
      } catch (error) {
        _logger.err('$error');
        return ExitCode.unavailable.code;
      }
    }
    return ExitCode.success.code;
  }
}
