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
  TestCommand({
    Logger? logger,
  }) : _logger = logger ?? Logger() {
    argParser
      ..addFlag(
        'recursive',
        abbr: 'r',
        help: 'Run tests recursively for all nested packages.',
        negatable: false,
      )
      ..addFlag(
        'coverage',
        help: 'Whether to collect coverage information.',
        negatable: false,
      )
      ..addOption(
        'min-coverage',
        help: 'Whether to enforce a minimum coverage percentage.',
      )
      ..addOption(
        'exclude-coverage',
        help: 'A glob which will be used to exclude files that match from the '
            'coverage.',
      )
      ..addOption(
        'exclude-tags',
        abbr: 'x',
        help: 'Run only tests that do not have the specified tags.',
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
    final targetPath = path.normalize(Directory.current.absolute.path);
    final pubspec = File(path.join(targetPath, 'pubspec.yaml'));

    if (!pubspec.existsSync()) {
      _logger.err(
        '''
Could not find a pubspec.yaml in $targetPath.
This command should be run from the root of your Flutter project.''',
      );
      return ExitCode.noInput.code;
    }

    final recursive = _argResults['recursive'] as bool;
    final collectCoverage = _argResults['coverage'] as bool;
    final minCoverage = double.tryParse(
      _argResults['min-coverage'] as String? ?? '',
    );
    final excludeTags = _argResults['exclude-tags'] as String?;
    final isFlutterInstalled = await Flutter.installed();
    final excludeFromCoverage = _argResults['exclude-coverage'] as String?;

    if (isFlutterInstalled) {
      try {
        await Flutter.test(
          optimizePerformance: _argResults.rest.isEmpty,
          recursive: recursive,
          progress: _logger.progress,
          stdout: _logger.write,
          stderr: _logger.err,
          collectCoverage: collectCoverage,
          minCoverage: minCoverage,
          excludeFromCoverage: excludeFromCoverage,
          arguments: [
            if (excludeTags != null) ...['-x', excludeTags],
            ..._argResults.rest,
          ],
        );
      } on MinCoverageNotMet catch (e) {
        _logger.err(
          '''Expected coverage >= ${minCoverage!.toStringAsFixed(2)}% but actual is ${e.coverage.toStringAsFixed(2)}%.''',
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
