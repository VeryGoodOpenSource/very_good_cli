import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:mason/mason.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import 'package:universal_io/io.dart';
import 'package:very_good_cli/src/cli/cli.dart';

/// Signature for the [Flutter.installed] method.
typedef FlutterInstalledCommand = Future<bool> Function();

/// Signature for the [Flutter.test] method.
typedef FlutterTestCommand = Future<void> Function({
  String cwd,
  bool recursive,
  bool collectCoverage,
  bool optimizePerformance,
  double? minCoverage,
  String? excludeFromCoverage,
  List<String>? arguments,
  void Function([String?]) Function(String message)? progress,
  void Function(String)? stdout,
  void Function(String)? stderr,
});

/// {@template test_command}
/// `very_good test` command for running tests.
/// {@endtemplate}
class TestCommand extends Command<int> {
  /// {@macro test_command}
  TestCommand({
    Logger? logger,
    FlutterInstalledCommand? flutterInstalled,
    FlutterTestCommand? flutterTest,
  })  : _logger = logger ?? Logger(),
        _flutterInstalled = flutterInstalled ?? Flutter.installed,
        _flutterTest = flutterTest ?? Flutter.test {
    argParser
      ..addFlag(
        'coverage',
        help: 'Whether to collect coverage information.',
        negatable: false,
      )
      ..addFlag(
        'recursive',
        abbr: 'r',
        help: 'Run tests recursively for all nested packages.',
        negatable: false,
      )
      ..addFlag(
        'optimization',
        defaultsTo: true,
        help: 'Whether to apply optimizations for test performance.',
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
      )
      ..addOption(
        'min-coverage',
        help: 'Whether to enforce a minimum coverage percentage.',
      );
  }

  final Logger _logger;
  final FlutterInstalledCommand _flutterInstalled;
  final FlutterTestCommand _flutterTest;

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
    final isFlutterInstalled = await _flutterInstalled();
    final excludeFromCoverage = _argResults['exclude-coverage'] as String?;
    final optimizePerformance = _argResults['optimization'] as bool;

    if (isFlutterInstalled) {
      try {
        await _flutterTest(
          optimizePerformance: optimizePerformance && _argResults.rest.isEmpty,
          recursive: recursive,
          progress: _logger.progress,
          stdout: _logger.write,
          stderr: _logger.err,
          collectCoverage: collectCoverage,
          minCoverage: minCoverage,
          excludeFromCoverage: excludeFromCoverage,
          arguments: [
            if (excludeTags != null) ...['-x', excludeTags],
            '--no-pub',
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
