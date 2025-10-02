import 'dart:math';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:mason/mason.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import 'package:universal_io/io.dart';
import 'package:very_good_cli/src/cli/cli.dart';

/// Options for configuring the Flutter test command.
class FlutterTestOptions {
  FlutterTestOptions._({
    required this.concurrency,
    required this.collectCoverage,
    required this.minCoverage,
    required this.excludeTags,
    required this.tags,
    required this.excludeFromCoverage,
    required this.randomSeed,
    required this.optimizePerformance,
    required this.updateGoldens,
    required this.forceAnsi,
    required this.dartDefine,
    required this.dartDefineFromFile,
    required this.platform,
    required this.rest,
  });

  /// Parses [ArgResults] into a [FlutterTestOptions] instance.
  factory FlutterTestOptions.parse(ArgResults argResults) {
    final concurrency = argResults['concurrency'] as String;
    final collectCoverage = argResults['coverage'] as bool;
    final minCoverage = double.tryParse(
      argResults['min-coverage'] as String? ?? '',
    );
    final excludeTags = argResults['exclude-tags'] as String?;
    final tags = argResults['tags'] as String?;
    final excludeFromCoverage = argResults['exclude-coverage'] as String?;
    final randomOrderingSeed =
        argResults['test-randomize-ordering-seed'] as String?;
    final randomSeed = randomOrderingSeed == 'random'
        ? Random().nextInt(4294967295).toString()
        : randomOrderingSeed;
    final optimizePerformance = argResults['optimization'] as bool;
    final updateGoldens = argResults['update-goldens'] as bool;
    final forceAnsi = argResults['force-ansi'] as bool?;
    final dartDefine = argResults['dart-define'] as List<String>?;
    final dartDefineFromFile =
        argResults['dart-define-from-file'] as List<String>?;
    final platform = argResults['platform'] as String?;
    final rest = argResults.rest;

    return FlutterTestOptions._(
      concurrency: concurrency,
      collectCoverage: collectCoverage,
      minCoverage: minCoverage,
      excludeTags: excludeTags,
      tags: tags,
      excludeFromCoverage: excludeFromCoverage,
      randomSeed: randomSeed,
      optimizePerformance: optimizePerformance,
      updateGoldens: updateGoldens,
      forceAnsi: forceAnsi,
      dartDefine: dartDefine,
      dartDefineFromFile: dartDefineFromFile,
      platform: platform,
      rest: rest,
    );
  }

  /// The number of concurrent test suites run.
  final String concurrency;

  /// Whether to collect coverage information.
  final bool collectCoverage;

  /// Whether to enforce a minimum coverage percentage.
  final double? minCoverage;

  /// Run only tests that do not have the specified tags.
  final String? excludeTags;

  /// Run only tests associated with the specified tags.
  final String? tags;

  /// A glob which will be used to exclude files that match from the coverage.
  final String? excludeFromCoverage;

  /// The seed to randomize the execution order of test cases within test files.
  final String? randomSeed;

  /// Whether to apply optimizations for test performance.
  final bool optimizePerformance;

  /// Whether "matchesGoldenFile()" calls within your test methods should update
  /// the golden files.
  final bool updateGoldens;

  /// Whether to force ansi output. If not specified, it will maintain the
  /// default behavior based on stdout and stderr.
  final bool? forceAnsi;

  /// Optional list of dart defines
  final List<String>? dartDefine;

  /// Optional list of dart define from files
  final List<String>? dartDefineFromFile;

  /// The platform to run tests on (e.g., 'chrome', 'vm', 'android', 'ios').
  final String? platform;

  /// The remaining arguments passed to the test command.
  final List<String> rest;
}

/// Signature for the [Flutter.installed] method.
typedef FlutterInstalledCommand =
    Future<bool> Function({required Logger logger});

/// Signature for the [Flutter.test] method.
typedef FlutterTestCommand =
    Future<List<int>> Function({
      required Logger logger,
      String cwd,
      bool recursive,
      bool collectCoverage,
      bool optimizePerformance,
      double? minCoverage,
      String? excludeFromCoverage,
      String? randomSeed,
      bool? forceAnsi,
      List<String>? arguments,
      void Function(String)? stdout,
      void Function(String)? stderr,
    });

/// {@template test_command}
/// `very_good test` command for running tests.
/// {@endtemplate}
class TestCommand extends Command<int> {
  /// {@macro test_command}
  TestCommand({
    required Logger logger,
    @visibleForTesting FlutterInstalledCommand? flutterInstalled,
    @visibleForTesting FlutterTestCommand? flutterTest,
  }) : _logger = logger,
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
        help:
            'Whether to apply optimizations for test performance. '
            'Automatically disabled when --platform is specified. '
            '''Add the `skip_very_good_optimization` tag to specific test files to disable them individually.''',
      )
      ..addOption(
        'concurrency',
        abbr: 'j',
        defaultsTo: '4',
        help:
            'The number of concurrent test suites run. '
            'Automatically set to 1 when --platform is specified.',
      )
      ..addOption(
        'tags',
        abbr: 't',
        help: 'Run only tests associated with the specified tags.',
      )
      ..addOption(
        'exclude-coverage',
        help:
            'A glob which will be used to exclude files that match from the '
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
        help:
            'The seed to randomize the execution order of test cases '
            'within test files.',
      )
      ..addFlag(
        'update-goldens',
        help:
            'Whether "matchesGoldenFile()" calls within your test methods '
            'should update the golden files.',
        negatable: false,
      )
      ..addFlag(
        'force-ansi',
        defaultsTo: null,
        help:
            'Whether to force ansi output. If not specified, '
            'it will maintain the default behavior based on stdout and stderr.',
        negatable: false,
      )
      ..addMultiOption(
        'dart-define',
        help:
            'Additional key-value pairs that will be available as constants '
            'from the String.fromEnvironment, bool.fromEnvironment, '
            'int.fromEnvironment, and double.fromEnvironment constructors. '
            'Multiple defines can be passed by repeating '
            '"--dart-define" multiple times.',
        valueHelp: 'foo=bar',
      )
      ..addMultiOption(
        'dart-define-from-file',
        help:
            'The path of a .json or .env file containing key-value pairs '
            'that will be available as environment variables. '
            'These can be accessed using the String.fromEnvironment, '
            'bool.fromEnvironment, and int.fromEnvironment constructors. '
            'Multiple defines can be passed by repeating '
            '"--dart-define-from-file" multiple times. '
            'Entries from "--dart-define" with identical keys take '
            'precedence over entries from these files.',
        valueHelp: 'use-define-config.json|.env',
      )
      ..addOption(
        'platform',
        help: 'The platform to run tests on. ',
        valueHelp: 'chrome|vm|android|ios',
      );
  }

  final Logger _logger;
  final FlutterInstalledCommand _flutterInstalled;
  final FlutterTestCommand _flutterTest;

  @override
  String get description =>
      'Run `flutter test` in a project. (Check '
      'very_good dart test for running `dart test` instead.)';

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
    final recursive = _argResults['recursive'] as bool;

    if (!recursive && !pubspec.existsSync()) {
      _logger.err('''
Could not find a pubspec.yaml in $targetPath.
This command should be run from the root of your Flutter project.''');
      return ExitCode.noInput.code;
    }

    final isFlutterInstalled = await _flutterInstalled(logger: _logger);

    final options = FlutterTestOptions.parse(_argResults);

    if (isFlutterInstalled) {
      try {
        final results = await _flutterTest(
          optimizePerformance:
              options.optimizePerformance &&
              !TestCLIRunner.isTargettingTestFiles(options.rest) &&
              !options.updateGoldens &&
              // Disabled optimization when platform is specified
              // https://github.com/VeryGoodOpenSource/very_good_cli/issues/1363
              options.platform == null,
          recursive: recursive,
          logger: _logger,
          stdout: _logger.write,
          stderr: _logger.err,
          collectCoverage:
              options.collectCoverage || options.minCoverage != null,
          minCoverage: options.minCoverage,
          excludeFromCoverage: options.excludeFromCoverage,
          randomSeed: options.randomSeed,
          forceAnsi: options.forceAnsi,
          arguments: [
            if (options.excludeTags != null) ...['-x', options.excludeTags!],
            if (options.tags != null) ...['-t', options.tags!],
            if (options.updateGoldens) '--update-goldens',
            if (options.platform != null) ...['--platform', options.platform!],
            if (options.dartDefine != null)
              for (final value in options.dartDefine!) '--dart-define=$value',
            if (options.dartDefineFromFile != null)
              for (final value in options.dartDefineFromFile!)
                '--dart-define-from-file=$value',
            if (options.platform == null) ...['-j', options.concurrency],
            '--no-pub',
            ...options.rest,
          ],
        );
        if (results.any((code) => code != ExitCode.success.code)) {
          return ExitCode.unavailable.code;
        }
      } on MinCoverageNotMet catch (e) {
        TestCLIRunner.handleMinCoverageNotMet(
          logger: _logger,
          minCoverage: options.minCoverage,
          e: e,
        );
        return ExitCode.unavailable.code;
      } on Exception catch (error) {
        _logger.err('$error');
        return ExitCode.unavailable.code;
      }
    }
    return ExitCode.success.code;
  }
}
