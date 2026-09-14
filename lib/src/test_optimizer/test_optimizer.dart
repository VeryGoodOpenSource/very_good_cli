/// Collapses a package's test files into one generated entrypoint,
/// `test/.test_optimizer.dart`, so the runner pays for a single VM start and
/// compilation instead of one per file.
///
/// The entrypoint is a build artifact, written before the run and deleted
/// after it. Results come back attributed to it, which
/// [TestOptimization.resolveReport] undoes before a user sees them.
library;

import 'package:glob/glob.dart';
import 'package:mason/mason.dart';
import 'package:path/path.dart' as p;
import 'package:universal_io/io.dart';
import 'package:very_good_cli/src/cli/templates/templates.dart';

/// A method which returns a [Future<MasonGenerator>] given a [MasonBundle].
typedef GeneratorBuilder = Future<MasonGenerator> Function(MasonBundle);

/// The name of the file the optimizer generates, inside a package's `test`
/// directory.
const testOptimizerFileName = '.test_optimizer.dart';

/// {@template invalid_optimization_glob}
/// Thrown when an exclude-optimization glob cannot be compiled.
///
/// Distinct from a plain [FormatException] so callers can tell a bad glob,
/// which the user must fix in `very_good.yaml` or on the command line, apart
/// from the malformed input a test run reports on its own.
/// {@endtemplate}
class InvalidOptimizationGlob extends FormatException {
  /// {@macro invalid_optimization_glob}
  const new(super.message);
}

extension on String {
  /// Compiles a single exclusion glob, matched in [p.posix] because test paths
  /// are always POSIX.
  Glob get toGlob {
    if (trim().isEmpty) {
      throw const InvalidOptimizationGlob(
        'Expected every exclude-optimization glob to be non-empty.',
      );
    }
    try {
      return Glob(this, context: p.posix, recursive: true);
    } on FormatException catch (error) {
      throw InvalidOptimizationGlob(
        'Invalid exclude-optimization glob `$this`: ${error.message}',
      );
    }
  }
}

/// {@template test_optimizer}
/// Collapses a package's test files into a single generated entrypoint so the
/// test runner compiles and loads one suite instead of one per file.
///
/// Configuration is per test run, while [apply] is per package, so a single
/// optimizer serves every package of a `--recursive` run.
/// {@endtemplate}
class TestOptimizer {
  /// {@macro test_optimizer}
  new({
    required bool enabled,
    List<String>? exclude,
    GeneratorBuilder buildGenerator = MasonGenerator.fromBundle,
  }) : this._(
         enabled,
         (exclude ?? const <String>[]).map((str) => str.toGlob).toList(),
         buildGenerator,
       );

  const new _(this._enabled, this._exclusions, this._buildGenerator);

  /// An optimizer that generates nothing and always yields
  /// [TestOptimization.none].
  const new disabled()
    : this._(false, const <Glob>[], MasonGenerator.fromBundle);

  final bool _enabled;
  final List<Glob> _exclusions;
  final GeneratorBuilder _buildGenerator;

  /// Generates the entrypoint for the package rooted at [packageRoot], which
  /// must be absolute: the brick's pre-gen hook resolves the package's `test`
  /// directory and `pubspec.yaml` from it.
  ///
  /// Returns [TestOptimization.none] when this optimizer is disabled, in which
  /// case nothing is written and [logger] is untouched.
  Future<TestOptimization> apply({
    required String packageRoot,
    required Logger logger,
  }) async {
    if (!_enabled) return TestOptimization.none;

    final progress = logger.progress('Optimizing tests');
    var vars = <String, dynamic>{'package-root': packageRoot};
    try {
      final generator = await _buildGenerator(testOptimizerBundle);
      await generator.hooks.preGen(
        vars: vars,
        onVarsChanged: (updated) => vars = updated,
        workingDirectory: packageRoot,
      );
      vars = _exclude(vars);
      await generator.generate(
        DirectoryGeneratorTarget(Directory(packageRoot)),
        vars: vars,
        fileConflictResolution: FileConflictResolution.overwrite,
      );
    } finally {
      progress.complete();
    }

    final tests = vars['tests'] as List<dynamic>?;
    final hasOptimizedTests = tests?.isNotEmpty ?? true;

    return TestOptimization._(
      hasOptimizedTests,
      packageRoot: packageRoot,
      serialTests: [
        ...?(vars['notOptimizedTests'] as List<dynamic>?)?.map(
          (test) => test.toString(),
        ),
      ],
    );
  }

  /// Moves every test matching [_exclusions] out of `vars['tests']` and into
  /// `vars['notOptimizedTests']`, so it runs as its own suite.
  ///
  /// [vars] comes from `bricks/test_optimizer/hooks/lib/pre_gen.dart`, which
  /// keeps the two lists disjoint. Globs are recursive and match each test's
  /// package relative POSIX path.
  Map<String, dynamic> _exclude(Map<String, dynamic> vars) {
    final tests = vars['tests'] as List<dynamic>?;
    if (_exclusions.isEmpty || tests == null) return vars;

    final notOptimizedTests = [...?vars['notOptimizedTests'] as List<dynamic>?];
    final optimizedTests = <dynamic>[];

    for (final test in tests) {
      final path = (test as Map<dynamic, dynamic>)['path'] as String;
      if (_exclusions.any((glob) => glob.matches('test/$path'))) {
        notOptimizedTests.add(path);
      } else {
        optimizedTests.add(test);
      }
    }

    return {
      ...vars,
      'tests': optimizedTests,
      'notOptimizedTests': notOptimizedTests,
    };
  }
}

/// {@template test_optimization}
/// The outcome of applying a [TestOptimizer] to a single package.
/// {@endtemplate}
class TestOptimization {
  const new _(
    this._hasOptimizedTests, {
    this.packageRoot,
    this.serialTests = const <String>[],
  });

  /// The outcome of a run in which nothing was optimized.
  static const none = TestOptimization._(false);

  /// Absolute path of the package the bundle was generated for, or `null` when
  /// nothing was generated.
  final String? packageRoot;

  /// Test files kept out of the bundle, which run as their own suites.
  final List<String> serialTests;

  final bool _hasOptimizedTests;

  /// The paths to append to the test runner's arguments, empty for [none].
  List<String> get testTargets {
    if (packageRoot == null) return const [];
    return [
      if (_hasOptimizedTests || serialTests.isEmpty)
        p.join('test', testOptimizerFileName),
      for (final test in serialTests) p.join('test', test),
    ];
  }

  /// Rewrites a location reported by the runner back onto the test file it came
  /// from, using [groupName], the outermost non-empty group of the test, which
  /// the bundle names after that file's path relative to `test`.
  ({String path, String name}) resolveReport({
    required String suitePath,
    required String testName,
    required String? groupName,
  }) {
    if (groupName == null || groupName.isEmpty) {
      return (path: suitePath, name: testName);
    }
    if (!suitePath.contains(testOptimizerFileName)) {
      return (path: suitePath, name: testName);
    }
    return (
      path: suitePath.replaceFirst(testOptimizerFileName, groupName),
      name: testName.replaceFirst(groupName, '').trim(),
    );
  }

  /// Deletes the generated bundle, if any.
  ///
  /// Never throws: this runs once the test run already has a result, and a
  /// leftover build artifact must not replace it. Both the run's completion
  /// and a `SIGINT` clean up, so losing the race to the other is expected.
  Future<void> cleanUp() async {
    final root = packageRoot;
    if (root == null) return;
    final bundle = File(p.join(root, 'test', testOptimizerFileName));
    try {
      await bundle.delete();
    } on FileSystemException {
      // The bundle is already gone, or cannot be removed.
    }
  }
}
