import 'package:args/command_runner.dart';
import 'package:collection/collection.dart';
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

    // The coverage options all come from the first section that sets any of
    // them, so that a run never mixes the `test` and `dart.test` sections.
    final (configMinCoverage, configExcludeCoverage, configShowUncovered) =
        [
          (
            testConfig.minCoverage,
            testConfig.excludeCoverage,
            testConfig.showUncovered,
          ),
          (
            dartTestConfig.minCoverage,
            dartTestConfig.excludeCoverage,
            dartTestConfig.showUncovered,
          ),
        ].firstWhere(
          (section) => section != (null, null, null),
          orElse: () => (null, null, null),
        );

    final rawMinCoverage = argResults.resolve<String?>(
      'min-coverage',
      configMinCoverage,
    );
    final minCoverage = double.tryParse(rawMinCoverage ?? '');
    final excludeFromCoverage = argResults.resolve<String?>(
      'exclude-coverage',
      configExcludeCoverage,
    );
    final showUncovered = argResults.resolve<bool>(
      'show-uncovered',
      configShowUncovered,
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
      final paths = argResults.rest.isEmpty
          ? _discoverInputs(cwd: cwd, outputPath: outputPath)
          : _resolveInputs(argResults.rest, cwd: cwd, outputPath: outputPath);
      final inputs = {
        for (final path in paths) path: _packageOf(path, cwd: cwd),
      };
      final externalPaths = <String>{};
      final records = mergeLcovRecords([
        for (final MapEntry(key: path, value: packagePath) in inputs.entries)
          ...normalizeLcovRecords(
            _parse(path),
            packagePath: packagePath,
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

      final outputFile = File(outputPath);
      await outputFile.create(recursive: true);
      await outputFile.writeAsString(formatLcovRecords(records));
      _logger.info('Merged ${inputs.length} lcov report(s) into $output');

      if (minCoverage != null || showUncovered) {
        checkCoverage(
          CoverageMetrics.fromLcov(
            records,
            excludeFromCoverage: excludeFromCoverage,
            packagePaths: [
              for (final package in inputs.values.nonNulls)
                package.replaceAll(r'\', '/'),
            ],
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
      return handleMinCoverageNotMet(
        error,
        logger: _logger,
        minCoverage: minCoverage,
      );
    } on FileSystemException catch (error) {
      _logger.err('$error');
      return ExitCode.ioError.code;
    }

    return ExitCode.success.code;
  }

  /// The lcov reports to merge, as paths relative to [cwd].
  ///
  /// Each of [args] is a path to an lcov file or, when no such file exists, a
  /// glob relative to [cwd]. Expanding globs here, rather than relying on the
  /// shell, makes quoted patterns behave the same on every platform.
  ///
  /// Glob matches skip the report at [outputPath] and the reports in platform,
  /// build and tool directories, while an explicit path to them is merged, so
  /// that they can be merged on purpose.
  List<String> _resolveInputs(
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
        matches = expandLcovGlob(arg, cwd: cwd);
      } on FormatException catch (error) {
        throw _MergeError(
          'Invalid glob "$arg": ${error.message}',
          ExitCode.usage.code,
        );
      }

      final kept = _skip(
        _skipOutput(matches, cwd: cwd, outputPath: outputPath),
        where: isInIgnoredDirectory,
        warning: (skipped) =>
            'Skipping these reports matched by "$arg", since they are in '
            'platform, build or tool directories. Pass their paths to merge '
            'them too:\n'
            '${skipped.map((path) => '  - $path').join('\n')}',
      );
      if (kept.isEmpty) {
        throw _MergeError(
          'No lcov report found at "$arg".',
          ExitCode.noInput.code,
        );
      }
      paths.addAll(kept);
    }

    return paths.toList();
  }

  /// The `coverage/lcov.info` report of every package under [cwd].
  ///
  /// The report at [outputPath] is skipped.
  List<String> _discoverInputs({
    required String cwd,
    required String outputPath,
  }) {
    final inputs = _skipOutput(
      [
        for (final package in discoverLcovPackages(cwd))
          p.normalize(p.join(package, 'coverage', 'lcov.info')),
      ],
      cwd: cwd,
      outputPath: outputPath,
    );

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

  /// [paths], relative to [cwd], without the report at [outputPath].
  ///
  /// Such a report is likely a previous merge, so it is reported as skipped,
  /// since merging it again would count its hits twice.
  List<String> _skipOutput(
    List<String> paths, {
    required String cwd,
    required String outputPath,
  }) => _skip(
    paths,
    where: (path) => p.equals(p.join(cwd, path), outputPath),
    warning: (skipped) =>
        'Skipping ${skipped.join(', ')}, since it is the --output report. '
        'Pass a different --output to merge it too.',
  );

  /// [paths] without the ones matching [where], which are reported with the
  /// [warning] built from them.
  List<String> _skip(
    List<String> paths, {
    required bool Function(String path) where,
    required String Function(List<String> skipped) warning,
  }) {
    final skipped = paths.where(where).toList();
    if (skipped.isNotEmpty) _logger.warn(warning(skipped));
    return paths.whereNot(where).toList();
  }

  /// The package directory, relative to [cwd], that the relative source paths
  /// of the report at [path] are rebased onto, so that the same `lib/a.dart`
  /// from two packages stays distinct.
  ///
  /// Only a package's `coverage/lcov.info` report, as left behind by
  /// `very_good test --coverage`, is rebased.
  String? _packageOf(String path, {required String cwd}) {
    final package = p.dirname(p.dirname(path));
    final isPackageReport =
        p.equals(path, p.join(package, 'coverage', 'lcov.info')) &&
        File(p.join(cwd, package, 'pubspec.yaml')).existsSync();
    return isPackageReport ? package : null;
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

/// A failure that stops the merge, reported with [message] and [exitCode].
class _MergeError implements Exception {
  const new(this.message, this.exitCode);

  final String message;

  final int exitCode;
}
