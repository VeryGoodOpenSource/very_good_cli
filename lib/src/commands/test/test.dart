import 'dart:math';

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
typedef FlutterTestCommand = Future<List<int>> Function({
  String cwd,
  bool recursive,
  bool collectCoverage,
  bool optimizePerformance,
  double? minCoverage,
  String? excludeFromCoverage,
  String? randomSeed,
  List<String>? arguments,
  Logger? logger,
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
        'concurrency',
        abbr: 'j',
        defaultsTo: '4',
        help: 'The number of concurrent test suites run.',
      )
      ..addOption(
        'tags',
        abbr: 't',
        help: 'Run only tests associated with the specified tags.',
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
      )
      ..addOption(
        'test-randomize-ordering-seed',
        help: 'The seed to randomize the execution order of test cases '
            'within test files.',
      )
      ..addFlag(
        'update-goldens',
        help: 'Whether "matchesGoldenFile()" calls within your test methods '
            'should update the golden files.',
        negatable: false,
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

    final concurrency = _argResults['concurrency'] as String;
    final recursive = _argResults['recursive'] as bool;
    final collectCoverage = _argResults['coverage'] as bool;
    final minCoverage = double.tryParse(
      _argResults['min-coverage'] as String? ?? '',
    );
    final excludeTags = _argResults['exclude-tags'] as String?;
    final tags = _argResults['tags'] as String?;
    final isFlutterInstalled = await _flutterInstalled();
    final excludeFromCoverage = _argResults['exclude-coverage'] as String?;
    final randomOrderingSeed =
        _argResults['test-randomize-ordering-seed'] as String?;
    final randomSeed = randomOrderingSeed == 'random'
        ? Random().nextInt(4294967295).toString()
        : randomOrderingSeed;
    final optimizePerformance = _argResults['optimization'] as bool;
    final updateGoldens = _argResults['update-goldens'] as bool;

    if (isFlutterInstalled) {
      try {
        final results = await _flutterTest(
          optimizePerformance:
              optimizePerformance && _argResults.rest.isEmpty && !updateGoldens,
          recursive: recursive,
          logger: _logger,
          stdout: _logger.write,
          stderr: _logger.err,
          collectCoverage: collectCoverage || minCoverage != null,
          minCoverage: minCoverage,
          excludeFromCoverage: excludeFromCoverage,
          randomSeed: randomSeed,
          arguments: [
            if (excludeTags != null) ...['-x', excludeTags],
            if (tags != null) ...['-t', tags],
            if (updateGoldens) '--update-goldens',
            ...['-j', concurrency],
            '--no-pub',
            ..._argResults.rest,
          ],
        );
        if (results.any((code) => code != ExitCode.success.code)) {
          return ExitCode.unavailable.code;
        }
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
