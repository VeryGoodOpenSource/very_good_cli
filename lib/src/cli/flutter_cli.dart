part of 'cli.dart';

/// This class facilitates overriding `ProcessSignal` related behavior.
/// It should be extended by another class in client code with overrides
/// that construct a custom implementation.
@visibleForTesting
abstract class ProcessSignalOverrides {
  static final _token = Object();
  StreamController<ProcessSignal>? _sigintStreamController;

  /// Returns the current [ProcessSignalOverrides] instance.
  ///
  /// This will return `null` if the current [Zone] does not contain
  /// any [ProcessSignalOverrides].
  ///
  /// See also:
  /// * [ProcessSignalOverrides.runZoned] to provide [ProcessSignalOverrides]
  /// in a fresh [Zone].
  static ProcessSignalOverrides? get current {
    return Zone.current[_token] as ProcessSignalOverrides?;
  }

  /// Runs [body] in a fresh [Zone] using the provided overrides.
  static R runZoned<R>(
    R Function() body, {
    Stream<ProcessSignal>? sigintStream,
  }) {
    final overrides = _ProcessSignalOverridesScope(sigintStream);
    return _asyncRunZoned(body, zoneValues: {_token: overrides});
  }

  /// Provides a custom [Stream] of [ProcessSignal.sigint] events.
  Stream<ProcessSignal>? get sigintWatch;

  /// Emits a [ProcessSignal.sigint] event on the [sigintWatch] stream.
  ///
  /// If no custom [sigintWatch] stream is provided, this method does nothing.
  void addSIGINT() {
    _sigintStreamController?.add(ProcessSignal.sigint);
  }
}

class _ProcessSignalOverridesScope extends ProcessSignalOverrides {
  new(Stream<ProcessSignal>? mockSigintStream) {
    if (mockSigintStream != null) {
      _sigintStreamController = StreamController<ProcessSignal>();
    }
  }

  @override
  Stream<ProcessSignal>? get sigintWatch {
    return _sigintStreamController?.stream;
  }
}

/// Thrown when `flutter pub get` is executed without a `pubspec.yaml`.
class PubspecNotFound implements Exception;

/// {@template coverage_metrics}
/// Aggregated coverage metrics computed from a list of LCOV records.
/// {@endtemplate}
class CoverageMetrics {
  /// {@macro coverage_metrics}
  @visibleForTesting
  const new({
    this.totalHits = 0,
    this.totalFound = 0,
    this.uncoveredLines = const {},
  });

  /// Generate coverage metrics from a list of lcov records.
  factory fromLcovRecords(List<Record> records, {String? excludeFromCoverage}) {
    final excludedGlobs = _parseGlobs(excludeFromCoverage);
    return records
        .whereNot((record) => _isExcluded(record.file, excludedGlobs))
        .fold(
          const CoverageMetrics(),
          (metrics, record) => metrics._add(record),
        );
  }

  /// Parses space-separated glob patterns, ignoring empty segments.
  static List<Glob> _parseGlobs(String? excludeFromCoverage) => [
    for (final pattern in (excludeFromCoverage ?? '').trim().split(' '))
      if (pattern.isNotEmpty) Glob(pattern),
  ];

  static bool _isExcluded(String? file, List<Glob> excludedGlobs) =>
      file != null && excludedGlobs.any((glob) => glob.matches(file));

  /// Line numbers in [record] that were instrumented but never hit.
  static List<int> _uncoveredLineNumbersOf(Record record) => [
    for (final detail in record.lines?.details ?? const <Never>[])
      if (detail.line case final line? when (detail.hit ?? 1) == 0) line,
  ];

  /// Returns new metrics with the counts and uncovered lines of [record].
  CoverageMetrics _add(Record record) {
    final lines = record.lines;
    return CoverageMetrics(
      totalFound: totalFound + (lines?.found ?? 0),
      totalHits: totalHits + (lines?.hit ?? 0),
      uncoveredLines: _uncoveredLinesWith(record),
    );
  }

  Map<String, List<int>> _uncoveredLinesWith(Record record) {
    final file = record.file;
    if (file == null) return uncoveredLines;

    final newLines = _uncoveredLineNumbersOf(record);
    return {
      ...uncoveredLines,
      if (newLines.isNotEmpty) file: [...?uncoveredLines[file], ...newLines],
    };
  }

  /// Total number of lines hit (covered) across all included files.
  final int totalHits;

  /// Total number of instrumented lines found across all included files.
  final int totalFound;

  /// Lines not covered.
  /// Keyed by file path, values are sorted line numbers.
  final Map<String, List<int>> uncoveredLines;

  /// Coverage percentage: [totalHits] / [totalFound] * 100.
  ///
  /// Returns `0` when [totalFound] is less than 1.
  double get percentage {
    return totalFound < 1 ? 0 : (totalHits / totalFound * 100);
  }
}

/// Flutter CLI
class Flutter {
  /// Determine whether flutter is installed.
  static Future<bool> installed({required Logger logger}) async {
    try {
      await _Cmd.run('flutter', ['--version'], logger: logger);
      return true;
    } on Exception catch (_) {
      return false;
    }
  }

  /// Install dart dependencies (`flutter pub get`).
  static Future<bool> pubGet({
    required Logger logger,
    String cwd = '.',
    bool recursive = false,
    Set<String> ignore = const {},
    Duration timeout = _pubGetTimeout,
  }) async {
    final initialCwd = cwd;

    final result = await _runCommand(
      cmd: (cwd) async {
        final relativePath = p.relative(cwd, from: initialCwd);
        final path = relativePath == '.'
            ? '.'
            : '.${p.context.separator}$relativePath';

        final installProgress = logger.progress(
          'Running "flutter pub get" in $path ',
        );

        try {
          await _verifyGitDependencies(cwd, logger: logger);
        } catch (_) {
          installProgress.fail();
          rethrow;
        }

        try {
          return await _Cmd.run(
            'flutter',
            ['pub', 'get', '--no-example'],
            workingDirectory: cwd,
            logger: logger,
            timeout: timeout,
          );
        } finally {
          installProgress.complete();
        }
      },
      cwd: cwd,
      recursive: recursive,
      ignore: ignore,
    );
    return result.every((e) => e.exitCode == ExitCode.success.code);
  }

  /// Run tests (`flutter test`).
  /// Returns a list of exit codes for each test process.
  static Future<List<int>> test({
    required Logger logger,
    String cwd = '.',
    bool recursive = false,
    bool collectCoverage = false,
    bool optimizePerformance = false,
    List<String>? excludeOptimization,
    Set<String> ignore = const {},
    double? minCoverage,
    bool showUncovered = false,
    String? excludeFromCoverage,
    CoverageCollectionMode collectCoverageFrom = CoverageCollectionMode.imports,
    String? randomSeed,
    bool? forceAnsi,
    List<String>? arguments,
    void Function(String)? stdout,
    void Function(String)? stderr,
    GeneratorBuilder buildGenerator = MasonGenerator.fromBundle,
    List<String>? reportOn,
    int? shardIndex,
    int? totalShards,
  }) {
    return TestCLIRunner.test(
      logger: logger,
      testType: TestRunType.flutter,
      cwd: cwd,
      recursive: recursive,
      collectCoverage: collectCoverage,
      optimizer: TestOptimizer(
        enabled: optimizePerformance,
        exclude: excludeOptimization,
        buildGenerator: buildGenerator,
        shardIndex: shardIndex,
        totalShards: totalShards,
      ),
      ignore: ignore,
      minCoverage: minCoverage,
      showUncovered: showUncovered,
      excludeFromCoverage: excludeFromCoverage,
      collectCoverageFrom: collectCoverageFrom,
      randomSeed: randomSeed,
      forceAnsi: forceAnsi,
      arguments: arguments,
      stdout: stdout,
      stderr: stderr,
      reportOn: reportOn,
    );
  }
}

/// Ensures all git dependencies are reachable for the pubspec
/// located in the [cwd].
///
/// If any git dependencies are unreachable,
/// an [UnreachableGitDependency] is thrown.
Future<void> _verifyGitDependencies(
  String cwd, {
  required Logger logger,
}) async {
  final pubspec = Pubspec.parse(
    await File(p.join(cwd, 'pubspec.yaml')).readAsString(),
  );

  final dependencies = pubspec.dependencies;
  final devDependencies = pubspec.devDependencies;
  final dependencyOverrides = pubspec.dependencyOverrides;
  final gitDependencies =
      [
            ...dependencies.entries,
            ...devDependencies.entries,
            ...dependencyOverrides.entries,
          ]
          .where((entry) => entry.value is GitDependency)
          .map((entry) => entry.value)
          .cast<GitDependency>()
          .toList();

  await Future.wait(
    gitDependencies.map(
      (dependency) => Git.reachable(dependency.url, logger: logger),
    ),
  );
}

/// Run a command on directories with a `pubspec.yaml`.
Future<List<T>> _runCommand<T>({
  required Future<T> Function(String cwd) cmd,
  required String cwd,
  required bool recursive,
  required Set<String> ignore,
}) async {
  if (!recursive) {
    final pubspec = File(p.join(cwd, 'pubspec.yaml'));
    if (!pubspec.existsSync()) throw PubspecNotFound();

    return [await cmd(cwd)];
  }

  final processes = _Cmd.runWhere<T>(
    run: (entity) => cmd(entity.parent.path),
    where: (entity) => !ignore.excludes(entity) && _isPubspec(entity),
    cwd: cwd,
  );

  if (processes.isEmpty) throw PubspecNotFound();

  final results = <T>[];
  for (final process in processes) {
    results.add(await process);
  }
  return results;
}

// The extension is intended to be unnamed, but it's not possible due to
// an issue with Dart SDK 2.18.0.
//
// Once the min Dart SDK is bumped, this extension can be unnamed again.
extension _TestEvent on TestEvent {
  bool shouldCancelTimer() {
    final event = this;
    if (event is MessageTestEvent) return true;
    if (event is ErrorTestEvent) return true;
    if (event is DoneTestEvent) return true;
    if (event is TestDoneEvent) return !event.hidden;
    return false;
  }
}

extension on Duration {
  String formatted() {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final twoDigitMinutes = twoDigits(inMinutes.remainder(60));
    final twoDigitSeconds = twoDigits(inSeconds.remainder(60));
    return darkGray.wrap('$twoDigitMinutes:$twoDigitSeconds')!;
  }
}

extension on int {
  String formatSuccess() {
    return this > 0 ? lightGreen.wrap('+$this')! : '';
  }

  String formatFailure() {
    return this > 0 ? lightRed.wrap('-$this')! : '';
  }

  String formatSkipped() {
    return this > 0 ? lightYellow.wrap('~$this')! : '';
  }
}

extension on String {
  String truncated(int maxLength) {
    if (length <= maxLength) return this;
    final truncated = substring(length - maxLength, length).trim();
    return '...$truncated';
  }

  String toSingleLine() {
    return replaceAll('\n', '').replaceAll(RegExp(r'\s\s+'), ' ');
  }
}
