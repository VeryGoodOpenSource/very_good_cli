import 'package:dart_mcp/server.dart';
import 'package:very_good_cli/src/cli/cli.dart';
import 'package:very_good_cli/src/mcp/runner/runner.dart';
import 'package:very_good_cli/src/mcp/tools/cli_arguments.dart';
import 'package:very_good_cli/src/mcp/tools/very_good_tool.dart';
import 'package:very_good_cli/src/very_good_config/very_good_config.dart';

/// {@template test_tool}
/// `test`: runs the tests of a package, by running `very_good test`, or
/// `very_good dart test` when `dart` is true.
/// {@endtemplate}
class TestTool(super.runner) extends VeryGoodTool {
  /// {@macro test_tool}
  this;

  /// The tool's name.
  static const name = 'test';

  @override
  Tool get definition => Tool(
    name: name,
    description:
        'Run the tests of a Dart or Flutter package, optionally '
        'collecting coverage and enforcing a minimum. Runs "flutter '
        'test" unless "dart" is true. A failure reports the failing '
        'tests and, when coverage is below "min_coverage", the uncovered '
        'lines. Writes "coverage/lcov.info" when coverage is collected.',
    annotations: ToolAnnotations(
      title: 'Run Dart or Flutter tests',
      readOnlyHint: false,
      destructiveHint: false,
      idempotentHint: true,
      openWorldHint: false,
    ),
    inputSchema: ObjectSchema(
      properties: {
        'directory': StringSchema(
          description:
              'The package to test. Absolute, or relative to the '
              'directory the server was started in, which is the '
              'default. A package path belongs here, not in "paths".',
        ),
        'paths': ListSchema(
          description:
              'Test files or directories to run, relative to the package '
              'selected by "directory" (e.g. '
              '["test/src/foo_test.dart", "test/widgets"]). These are '
              'targets inside that one package: to test a different '
              'package, set "directory" to it rather than putting its '
              'path here. When omitted, the whole suite runs. Cannot be '
              'combined with "recursive" or "workspace". Targeting '
              'specific paths disables the test optimization step.',
          items: StringSchema(),
        ),
        'dart': BooleanSchema(
          description:
              'Whether to run "dart test" instead of "flutter test". Set '
              'to true for a package that does not depend on Flutter. '
              'Defaults to false.',
        ),
        'coverage': BooleanSchema(
          description:
              'Whether to collect coverage into "coverage/lcov.info". '
              'Defaults to false.',
        ),
        'recursive': BooleanSchema(
          description:
              'Whether to run the tests of every package nested under '
              '"directory". Cannot be combined with "workspace", nor '
              'with "paths", because each package runs in its own '
              'working directory and a path is only meaningful within '
              'one of them. Defaults to false.',
        ),
        'workspace': BooleanSchema(
          description:
              'Whether to run the tests of every package of the Pub '
              'workspace rooted at "directory". Cannot be combined with '
              '"recursive" or "paths". For Dart and Flutter tests. '
              'Defaults to false.',
        ),
        'optimization': BooleanSchema(
          description:
              'Whether to bundle the test files into a single entry '
              'point so that they run faster. Disabled when "platform" '
              'or "paths" is set, or "update_goldens" is true. Tag a test '
              'file with "skip_very_good_optimization" to leave it out, '
              'or list it in "exclude_optimization". Defaults to true.',
        ),
        'exclude_optimization': ListSchema(
          description:
              'Globs of test files to keep out of the optimized bundle '
              '(e.g. ["test/integration/**"]). Excluded files still run, '
              'as their own test suites. For Dart and Flutter tests.',
          items: StringSchema(),
        ),
        'concurrency': IntegerSchema(
          description:
              'The number of test suites to run at the same time. Set to '
              '1 when "platform" is set. Defaults to 4.',
          minimum: 1,
        ),
        'tags': StringSchema(
          description: 'Run only the tests with the given tags (e.g. "unit").',
        ),
        'exclude_tags': StringSchema(
          description:
              'Skip the tests with the given tags (e.g. "integration").',
        ),
        'exclude_coverage': StringSchema(description: excludeCoverageHelp),
        'collect_coverage_from': UntitledSingleSelectEnumSchema(
          description:
              'Which files the coverage counts: "imports" for the files '
              'the tests import, or "all" for every file of the package, '
              'so that a file no test imports counts as uncovered '
              'against "min_coverage". For Dart and Flutter tests. '
              'Defaults to "imports".',
          values: collectCoverageFromAllowedValues,
        ),
        'report_on': ListSchema(
          description:
              'Paths, relative to the package, to restrict the coverage '
              'report to (e.g. ["lib/src"]). For Dart and Flutter tests. '
              'When omitted, the whole package is reported on.',
          items: StringSchema(),
        ),
        'min_coverage': NumberSchema(
          description:
              'The minimum coverage percentage to require (e.g. 100). '
              'Enables coverage collection. A lower coverage fails with '
              'a "coverage_below_threshold" reason. Cannot be combined '
              'with "total_shards".',
          minimum: 0,
          maximum: 100,
        ),
        'show_uncovered': BooleanSchema(
          description:
              'Whether to print the uncovered lines when coverage is '
              'below 100%. Enables coverage collection. Defaults to '
              'false.',
        ),
        'check_ignore': BooleanSchema(
          description:
              'Whether to respect coverage ignore comments (e.g. '
              '"// coverage:ignore-line"). Only for Dart tests: true '
              'requires "dart": true, and false has no effect on Flutter '
              'tests. Defaults to true.',
        ),
        'test_randomize_ordering_seed': StringSchema(
          description:
              'The seed to shuffle the order of the tests within each '
              'file: an integer, or "random" for a new seed on each run.',
        ),
        'update_goldens': BooleanSchema(
          description:
              'Whether "matchesGoldenFile()" calls overwrite the golden '
              'files instead of comparing against them. Only for Flutter '
              'tests. Defaults to false.',
        ),
        'fail_fast': BooleanSchema(
          description:
              'Whether to stop the run at the first failing test, which '
              'shortens the loop while fixing a failing suite. For Dart '
              'and Flutter tests. Defaults to false.',
        ),
        'flavor': StringSchema(
          description:
              'The app flavor to build for the tests, as defined by the '
              'platform-specific build setup: a product flavor of the '
              'Android Gradle scripts or a custom Xcode scheme. Only for '
              'Flutter tests.',
        ),
        'file_reporter': StringSchema(
          description:
              'An additional reporter that writes the test results to a '
              'file, as "<name>:<path>" (e.g. "json:reports/tests.json"). '
              'For Dart and Flutter tests.',
        ),
        'shard_index': IntegerSchema(
          description:
              'The 1-based index of the shard to run, to split the suite '
              'across runners. Must be set together with "total_shards" '
              'and be at most its value. For Dart and Flutter tests.',
          minimum: 1,
        ),
        'total_shards': IntegerSchema(
          description:
              'The number of shards to split the suite into, of which '
              'only the one at "shard_index" runs. Requires the '
              'optimization, so it cannot be combined with "paths", '
              '"platform", "update_goldens" or "optimization": false, '
              'nor with "min_coverage", since one shard covers a fraction '
              'of the code. For Dart and Flutter tests.',
          minimum: 1,
        ),
        'dart_define': ListSchema(
          description:
              'Key-value pairs made available to '
              'String.fromEnvironment, bool.fromEnvironment, '
              'int.fromEnvironment and double.fromEnvironment (e.g. '
              '["foo=bar"]). Only for Flutter tests.',
          items: StringSchema(),
        ),
        'dart_define_from_file': ListSchema(
          description:
              'Paths of .json or .env files holding key-value pairs made '
              'available like "dart_define" ones, which take precedence '
              'for an identical key. Only for Flutter tests.',
          items: StringSchema(),
        ),
        'platform': UntitledSingleSelectEnumSchema(
          description:
              'The platform to run the tests on. "android" and "ios" are '
              'only for Flutter tests.',
          values: ['chrome', 'vm', 'android', 'ios'],
        ),
        'run_skipped': BooleanSchema(
          description:
              'Whether to run skipped tests instead of skipping them. '
              'Defaults to false.',
        ),
        'timeout_seconds': IntegerSchema(
          description:
              'The longest the whole run may take, in seconds. When '
              'exceeded, the run is stopped and fails with a "timeout" '
              'reason that reports the tests that finished. Use it to '
              'bound tests that can hang forever, such as a '
              'tester.pumpAndSettle() without a timeout or a '
              'tester.runAsync() awaiting a future that never '
              'completes. Defaults to no timeout.',
          minimum: 1,
        ),
      },
      additionalProperties: false,
    ),
    outputSchema: toolOutputSchema,
  );

  @override
  Future<CallToolResult> run(Map<String, Object?> arguments) async {
    if (arguments['check_ignore'] == true && arguments['dart'] != true) {
      return invalidInput(
        '"check_ignore" is only supported by the Dart test runner and '
        'requires "dart": true. Flutter\'s test command does not accept '
        '--check-ignore; omit the argument or set "check_ignore": false '
        'for Flutter runs.',
        arguments,
      );
    }

    final timeoutSeconds = (arguments['timeout_seconds'] as num?)?.toInt();
    return await runner.run(
      _cliArguments(arguments),
      toolName: name,
      // The package to test is the working directory of the run, not a
      // positional test target.
      directory: arguments['directory'] as String?,
      requestArguments: arguments,
      // The budget is enforced by the runner rather than forwarded as a flag:
      // `dart test` would reject `--timeout`, and `flutter test`'s per-test
      // timeout does not fire when a test awaits a future that never
      // completes, which is the hang "timeout_seconds" exists to bound.
      timeout: timeoutSeconds == null
          ? null
          : Duration(seconds: timeoutSeconds),
    );
  }

  List<String> _cliArguments(Map<String, Object?> arguments) {
    final paths = arguments['paths'] as List<Object?>? ?? const [];

    return [
      ...arguments.flag('dart', 'dart'),
      'test',
      ...arguments.flag('coverage', '--coverage'),
      ...arguments.flag('recursive', '-r'),
      ...arguments.flag('workspace', '--workspace'),
      ...arguments.negatableFlag('optimization', 'optimization'),
      ...arguments.multiOption(
        'exclude_optimization',
        '--exclude-optimization',
      ),
      ...arguments.option('concurrency', '-j'),
      ...arguments.option('tags', '-t'),
      ...arguments.option('exclude_coverage', '--exclude-coverage'),
      ...arguments.option('collect_coverage_from', '--collect-coverage-from'),
      ...arguments.multiOption('report_on', '--report-on'),
      ...arguments.option('exclude_tags', '-x'),
      ...arguments.option('min_coverage', '--min-coverage'),
      ...arguments.option(
        'test_randomize_ordering_seed',
        '--test-randomize-ordering-seed',
      ),
      ...arguments.flag('update_goldens', '--update-goldens'),
      ...arguments.flag('fail_fast', '--fail-fast'),
      ...arguments.option('flavor', '--flavor'),
      ...arguments.option('file_reporter', '--file-reporter'),
      ...arguments.option('shard_index', '--shard-index'),
      ...arguments.option('total_shards', '--total-shards'),
      ...arguments.multiOption('dart_define', '--dart-define'),
      ...arguments.multiOption(
        'dart_define_from_file',
        '--dart-define-from-file',
      ),
      ...arguments.option('platform', '--platform'),
      ...arguments.flag('run_skipped', '--run-skipped'),
      // `--check-ignore` is only defined by `very_good dart test`.
      if (arguments['dart'] == true)
        ...arguments.negatableFlag('check_ignore', 'check-ignore'),
      ...arguments.flag('show_uncovered', '--show-uncovered'),
      // Positional test targets go last, after every option, so that they are
      // parsed as `rest` rather than as a value for the preceding option. The
      // `--` terminator keeps a target that begins with `-` from being read as
      // an option; the parser strips it back out of `rest`, so the test command
      // sees the paths and nothing else.
      if (paths.isNotEmpty) ...['--', ...paths.cast<String>()],
    ];
  }
}
