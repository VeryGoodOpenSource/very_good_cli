import 'package:args/command_runner.dart';
import 'package:collection/collection.dart';
import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';
import 'package:mason/mason.dart';
import 'package:path/path.dart' as p;
import 'package:universal_io/io.dart';
import 'package:very_good_cli/src/cli/cli.dart';
import 'package:very_good_cli/src/very_good_config/very_good_config.dart';

/// {@template coverage_merge_command}
/// `very_good coverage merge` command for merging lcov reports.
///
/// Combines the reports of sharded (`--shard-index`/`--total-shards`) or
/// recursive (`--recursive`) test runs into a single report, then enforces
/// `--min-coverage` on it the same way `very_good test` does.
/// {@endtemplate}
class CoverageMergeCommand extends Command<int> {
  /// {@macro coverage_merge_command}
  new({required this._logger}) {
    argParser
      ..addOption(
        'output',
        abbr: 'o',
        defaultsTo: 'coverage/lcov.info',
        help: 'The path to write the merged lcov report to.',
        valueHelp: 'path',
      )
      ..addOption(
        'min-coverage',
        help: 'Whether to enforce a minimum coverage percentage.',
      )
      ..addOption(
        'exclude-coverage',
        help:
            'A glob which will be used to exclude files that match from the '
            "coverage (e.g. '**/*.g.dart').",
      )
      ..addFlag(
        'show-uncovered',
        help: 'Whether to show uncovered lines when coverage is below 100%.',
        negatable: false,
      );
  }

  final Logger _logger;

  @override
  String get description =>
      'Merge lcov reports, from sharded or recursive test runs, and check the '
      'merged coverage.';

  @override
  String get name => 'merge';

  @override
  String get invocation =>
      'very_good coverage merge [lcov files or globs] [arguments]';

  @override
  Future<int> run() async {
    final argResults = this.argResults!;
    final cwd = p.normalize(Directory.current.absolute.path);

    final config = VeryGoodConfig.load(Directory(cwd), logger: _logger);
    if (config == null) return ExitCode.config.code;
    final testConfig = config.test;
    final dartTestConfig = config.dart.test;

    final rawMinCoverage = argResults.resolve<String?>(
      'min-coverage',
      testConfig.minCoverage ?? dartTestConfig.minCoverage,
    );
    final minCoverage = double.tryParse(rawMinCoverage ?? '');
    final excludeFromCoverage = argResults.resolve<String?>(
      'exclude-coverage',
      testConfig.excludeCoverage ?? dartTestConfig.excludeCoverage,
    );
    final showUncovered = argResults.resolve<bool>(
      'show-uncovered',
      testConfig.showUncovered ?? dartTestConfig.showUncovered,
    );
    final output = p.normalize(argResults['output'] as String);

    try {
      if (rawMinCoverage != null && minCoverage == null) {
        throw _MergeError(
          '--min-coverage must be a number, but got "$rawMinCoverage".',
          ExitCode.usage.code,
        );
      }

      final outputPath = p.join(cwd, output);
      final inputs = argResults.rest.isEmpty
          ? _discoverInputs(cwd: cwd, outputPath: outputPath)
          : _resolveInputs(argResults.rest, cwd: cwd, outputPath: outputPath);
      final externalPaths = <String>{};
      final records = mergeLcovRecords([
        for (final input in inputs)
          ...normalizeLcovRecords(
            _parse(input.path),
            packagePath: input.packagePath,
            onExternalPath: externalPaths.add,
          ),
      ]);

      if (externalPaths.isNotEmpty) {
        _logger.warn(
          'These source paths are outside of $cwd and were kept as is, so '
          'they will not match the same files from other reports:\n'
          '${externalPaths.map((path) => '  - $path').join('\n')}',
        );
      }

      final outputFile = File(p.join(cwd, output));
      await outputFile.create(recursive: true);
      await outputFile.writeAsString(formatLcovRecords(records));
      _logger.info('Merged ${inputs.length} lcov report(s) into $output');

      if (minCoverage != null || showUncovered) {
        checkCoverage(
          CoverageMetrics.fromLcov(
            records,
            excludeFromCoverage: excludeFromCoverage,
          ),
          minCoverage: minCoverage,
          showUncovered: showUncovered,
          stdout: _logger.write,
        );
      }
    } on _MergeError catch (error) {
      _logger.err(error.message);
      return error.exitCode;
    } on MinCoverageNotMet catch (error) {
      return TestCLIRunner.handleMinCoverageNotMet(
        error,
        logger: _logger,
        minCoverage: minCoverage,
      );
    }

    return ExitCode.success.code;
  }

  /// The lcov reports to merge, as paths relative to [cwd], and the package
  /// directory their relative source paths should be rebased onto.
  ///
  /// Each of [args] is a path to an lcov file or, when no such file exists, a
  /// glob relative to [cwd]. Expanding globs here, rather than relying on the
  /// shell, makes quoted patterns behave the same on every platform.
  ///
  /// Glob matches skip the report at [outputPath], while an explicit path to
  /// it is merged, so that it can be overwritten on purpose.
  List<_MergeInput> _resolveInputs(
    List<String> args, {
    required String cwd,
    required String outputPath,
  }) {
    final paths = <String>{};
    for (final arg in args) {
      final file = File(p.join(cwd, arg));
      if (file.existsSync()) {
        paths.add(p.relative(file.path, from: cwd));
        continue;
      }

      final List<String> matches;
      try {
        matches = Glob(arg)
            .listSync(root: cwd)
            .whereType<File>()
            .map((file) => p.relative(file.path, from: cwd))
            .whereNot(
              (path) => _isOutput(path, cwd: cwd, outputPath: outputPath),
            )
            .sorted();
      } on FormatException catch (error) {
        throw _MergeError(
          'Invalid glob "$arg": ${error.message}',
          ExitCode.usage.code,
        );
      }

      if (matches.isEmpty) {
        throw _MergeError(
          'No lcov report found at "$arg".',
          ExitCode.noInput.code,
        );
      }
      paths.addAll(matches);
    }

    return [for (final path in paths) (path: path, packagePath: null)];
  }

  /// The `coverage/lcov.info` report of every package under [cwd], with their
  /// relative source paths rebased onto their package, so the same
  /// `lib/a.dart` from two packages stays distinct.
  ///
  /// The report at [outputPath] is skipped.
  List<_MergeInput> _discoverInputs({
    required String cwd,
    required String outputPath,
  }) {
    final inputs = <_MergeInput>[
      for (final package in discoverLcovPackages(cwd))
        if (p.normalize(p.join(package, 'coverage', 'lcov.info'))
            case final path
            when !_isOutput(path, cwd: cwd, outputPath: outputPath))
          (path: path, packagePath: package),
    ];

    if (inputs.isEmpty) {
      throw _MergeError(
        'No lcov reports found in $cwd. Run '
        '"very_good test --recursive --coverage" first, or pass the lcov files '
        'or globs to merge.',
        ExitCode.noInput.code,
      );
    }
    return inputs;
  }

  /// Whether [path], relative to [cwd], is the report at [outputPath].
  ///
  /// Such a report is likely a previous merge, so it is reported as skipped,
  /// since merging it again would count its hits twice.
  bool _isOutput(
    String path, {
    required String cwd,
    required String outputPath,
  }) {
    if (!p.equals(p.join(cwd, path), outputPath)) return false;
    _logger.warn(
      'Skipping $path, since it is the --output report. Pass a different '
      '--output to merge it too.',
    );
    return true;
  }

  List<LcovRecord> _parse(String path) {
    try {
      return parseLcov(File(path).readAsStringSync());
    } on FormatException catch (error) {
      throw _MergeError(
        'Could not parse the lcov report "$path": ${error.message}',
        ExitCode.data.code,
      );
    }
  }
}

/// An lcov report to merge, and the package directory its relative source
/// paths should be rebased onto, if any.
typedef _MergeInput = ({String path, String? packagePath});

/// A failure that stops the merge, reported with [message] and [exitCode].
class _MergeError implements Exception {
  const new(this.message, this.exitCode);

  final String message;

  final int exitCode;
}
