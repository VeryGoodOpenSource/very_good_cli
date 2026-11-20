import 'dart:async';
import 'dart:io' show Directory, IOOverrides, ProcessSignal;

import 'package:dart_mcp/server.dart';
import 'package:mason/mason.dart' hide packageVersion;
import 'package:meta/meta.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:very_good_cli/src/cli/cli.dart';
import 'package:very_good_cli/src/command_runner.dart';
import 'package:very_good_cli/src/mcp/lock.dart';
import 'package:very_good_cli/src/mcp/structured_tool_error.dart';
import 'package:very_good_cli/src/mcp/tool_run.dart';
import 'package:very_good_cli/src/version.dart';

/// {@template command_runner_builder}
/// Builds a [VeryGoodCommandRunner] bound to the provided [logger].
///
/// A builder (rather than a prebuilt runner) is required so the runner — and
/// therefore its mason [Logger] — can be constructed *inside* the
/// [IOOverrides] zone that redirects `stdout`/`stderr`. mason captures
/// `IOOverrides.current` once, at [Logger] construction, so a runner built
/// outside the zone would still write to the real process stdout and corrupt
/// the MCP JSON-RPC stream.
/// {@endtemplate}
typedef CommandRunnerBuilder = VeryGoodCommandRunner Function({
  required Logger logger,
});

/// The default [CommandRunnerBuilder] used when none is injected.
@visibleForTesting
VeryGoodCommandRunner defaultCommandRunnerBuilder({required Logger logger}) =>
    VeryGoodCommandRunner(logger: logger);

/// {@template very_good_mcp_server}
/// MCP Server for Very Good CLI.
///
/// This server exposes Very Good CLI functionality through the
/// Model Context Protocol, allowing AI assistants to interact
/// with the CLI programmatically.
/// {@endtemplate}
final class VeryGoodMCPServer({
  required StreamChannel<String> channel,

  /// {@macro command_runner_builder}
  final CommandRunnerBuilder _commandRunnerBuilder =
      defaultCommandRunnerBuilder,
}) extends MCPServer with ToolsSupport {
  /// {@macro very_good_mcp_server}
  this
    : super.fromStreamChannel(
        channel,
        implementation: Implementation(
          name: 'very_good_cli',
          version: packageVersion,
        ),
        instructions:
            'Tools from Very Good CLI for Dart and Flutter projects: create a '
            'project from a template, run tests with coverage, install '
            'dependencies and check dependency licenses. Tool calls run one '
            'at a time. A relative "directory" resolves against the '
            'directory the server was started in. A failed call returns a '
            'JSON payload: read its "failureType" and "failureReason" to '
            'decide whether a retry can help, and its '
            '"alternativeApproaches" for what to try next.',
      );

  /// Serializes tool runs.
  ///
  /// [_runToolCommand] switches the process-global `Directory.current`, so tool
  /// runs must not overlap — the MCP transport can dispatch tool calls
  /// concurrently (pipelined requests), and overlapping runs would corrupt each
  /// other's working directory. The [Lock] keeps at most one run in flight.
  final _lock = Lock();

  @override
  FutureOr<InitializeResult> initialize(InitializeRequest request) async {
    final result = await super.initialize(request);

    _registerTools();

    return result;
  }

  /// Registers [tool] so that [handler] only runs with arguments that match
  /// the tool's input schema.
  ///
  /// Arguments that do not match are reported as a [StructuredToolError], like
  /// every other failure, instead of the plain text that the built-in
  /// validation of [registerTool] returns.
  void _registerTool(
    Tool tool,
    Future<CallToolResult> Function(Map<String, Object?> args) handler,
  ) {
    registerTool(tool, (request) {
      final args = request.arguments ?? const <String, Object?>{};
      final errors = tool.inputSchema.validate(args);
      if (errors.isEmpty) return handler(args);

      final details = errors.map((error) => error.toErrorString()).join('; ');
      return StructuredToolError(
        toolName: tool.name,
        reason: 'Invalid arguments: $details.',
        failureType: ToolFailureType.validation,
        failureReason: ToolFailureReason.invalidInput,
        attemptedArguments: args,
      ).toCallToolResult();
    }, validateArguments: false);
  }

  void _registerTools() {
    _registerTool(
      Tool(
        name: _createTool,
        description:
            'Create a new Dart or Flutter project from a Very Good template. '
            'Generates the project in "<output_directory>/<name>" and, for '
            'every template but docs_site, installs its dependencies. Fails '
            'instead of overwriting a file that already exists there with '
            'different content. Some arguments only apply to some '
            'templates; passing one to a template that does not accept it '
            'fails with a usage error.',
        annotations: ToolAnnotations(
          title: 'Create a Very Good project',
          readOnlyHint: false,
          destructiveHint: false,
          idempotentHint: false,
          openWorldHint: true,
        ),
        inputSchema: ObjectSchema(
          properties: {
            'subcommand': UntitledSingleSelectEnumSchema(
              description:
                  'The template to generate: flutter_app (Flutter '
                  'application), flutter_package, flutter_plugin (federated '
                  'plugin), flame_game, app_ui_package (Flutter UI package), '
                  'dart_package, dart_cli (Dart command-line application) or '
                  'docs_site (Docusaurus documentation site).',
              values: [
                'app_ui_package',
                'flame_game',
                'flutter_app',
                'flutter_package',
                'flutter_plugin',
                'dart_cli',
                'dart_package',
                'docs_site',
              ],
            ),
            'name': StringSchema(
              description:
                  'The project name, a valid Dart package name in snake_case '
                  '(e.g. "my_app").',
            ),
            'description': StringSchema(
              description:
                  'The project description. Defaults to "A Very Good Project '
                  'created by Very Good CLI.".',
            ),
            'org_name': StringSchema(
              description:
                  'The organization (e.g. "com.example.app"). Only for '
                  'flutter_app, flutter_plugin and flame_game, where it '
                  'defaults to "com.example.verygoodcore", and docs_site, '
                  'where it defaults to "my-org".',
            ),
            'output_directory': StringSchema(
              description:
                  'The directory to create the project folder in. Absolute, '
                  'or relative to the directory the server was started in, '
                  'which is the default.',
            ),
            'application_id': StringSchema(
              description:
                  'The bundle identifier on iOS or application id on Android '
                  '(e.g. "com.example.my_app"). Only for flutter_app. '
                  'Defaults to "<org_name>.<name>".',
            ),
            'platforms': ListSchema(
              description:
                  'The platforms to support (e.g. ["android", "ios"]). Only '
                  'for flutter_app, flame_game and flutter_plugin. "linux" '
                  'is only accepted by flutter_plugin. Defaults to every '
                  'platform the template supports.',
              items: UntitledSingleSelectEnumSchema(
                values: ['android', 'ios', 'web', 'macos', 'linux', 'windows'],
              ),
              uniqueItems: true,
            ),
            'publishable': BooleanSchema(
              description:
                  'Whether the project is intended to be published. Defaults '
                  'to false.',
            ),
            'workspace': BooleanSchema(
              description:
                  'Whether the project resolves its dependencies from a '
                  'parent Pub workspace. Ignored for docs_site.',
            ),
            'executable_name': StringSchema(
              description:
                  'The CLI executable name. Only for dart_cli. Defaults to '
                  'the project name.',
            ),
          },
          required: ['subcommand', 'name'],
          additionalProperties: false,
        ),
        outputSchema: toolOutputSchema,
      ),
      _handleCreate,
    );

    _registerTool(
      Tool(
        name: _testTool,
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
                  'combined with "recursive". Targeting specific paths '
                  'disables the test optimization step.',
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
                  '"directory". Cannot be combined with "paths", because '
                  'each package runs in its own working directory and a path '
                  'is only meaningful within one of them. Defaults to false.',
            ),
            'optimization': BooleanSchema(
              description:
                  'Whether to bundle the test files into a single entry '
                  'point so that they run faster. Disabled when "platform" '
                  'or "paths" is set. Tag a test file with '
                  '"skip_very_good_optimization" to leave it out. Defaults '
                  'to true.',
            ),
            'concurrency': IntegerSchema(
              description:
                  'The number of test suites to run at the same time. Set to '
                  '1 when "platform" is set. Defaults to 4.',
              minimum: 1,
            ),
            'tags': StringSchema(
              description:
                  'Run only the tests with the given tags (e.g. "unit").',
            ),
            'exclude_tags': StringSchema(
              description:
                  'Skip the tests with the given tags (e.g. "integration").',
            ),
            'exclude_coverage': StringSchema(description: excludeCoverageHelp),
            'min_coverage': NumberSchema(
              description:
                  'The minimum coverage percentage to require (e.g. 100). '
                  'Enables coverage collection. A lower coverage fails with '
                  'a "coverage_below_threshold" reason.',
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
                  'files instead of comparing against them. Defaults to '
                  'false.',
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
      ),
      _handleTest,
    );

    _registerTool(
      Tool(
        name: _packagesGetTool,
        description:
            'Install the dependencies of a Dart or Flutter package with "pub '
            'get". Use after creating a project or changing a pubspec.yaml.',
        annotations: ToolAnnotations(
          title: 'Get packages',
          readOnlyHint: false,
          destructiveHint: false,
          idempotentHint: true,
          openWorldHint: true,
        ),
        inputSchema: ObjectSchema(
          properties: {
            'directory': StringSchema(
              description:
                  'The package to install dependencies for. Absolute, or '
                  'relative to the directory the server was started in, '
                  'which is the default.',
            ),
            'recursive': BooleanSchema(
              description:
                  'Whether to install the dependencies of every package '
                  'nested under "directory", as in a monorepo. Defaults to '
                  'false.',
            ),
            'ignore': ListSchema(
              description:
                  'Names of the packages to skip in a recursive run (e.g. '
                  '["package_a", "package_b"]).',
              items: StringSchema(),
            ),
          },
          additionalProperties: false,
        ),
        outputSchema: toolOutputSchema,
      ),
      _handlePackagesGet,
    );

    _registerTool(
      Tool(
        name: _packagesCheckLicensesTool,
        description:
            'List the licenses of the dependencies of a Dart or Flutter '
            'package as SPDX identifiers (e.g. MIT, BSD-3-Clause), and fail '
            'when one is not in "allowed" or is in "forbidden". Reads '
            'pubspec.lock, so the dependencies must be installed first.',
        annotations: ToolAnnotations(
          title: 'Check package licenses',
          readOnlyHint: true,
          idempotentHint: true,
          openWorldHint: false,
        ),
        inputSchema: ObjectSchema(
          properties: {
            'directory': StringSchema(
              description:
                  'The package to check, holding a pubspec.lock. Absolute, '
                  'or relative to the directory the server was started in, '
                  'which is the default.',
            ),
            'dependency_type': ListSchema(
              description:
                  'The types of dependencies to check. Defaults to '
                  '["direct-main"].',
              items: UntitledSingleSelectEnumSchema(
                values: [
                  'direct-main',
                  'direct-dev',
                  'transitive',
                  'direct-overridden',
                ],
              ),
              uniqueItems: true,
            ),
            'allowed': ListSchema(
              description:
                  'The only SPDX licenses to accept (e.g. ["MIT", '
                  '"BSD-3-Clause"]). Cannot be combined with "forbidden".',
              items: StringSchema(),
            ),
            'forbidden': ListSchema(
              description:
                  'The SPDX licenses to reject (e.g. ["GPL-3.0-only"]). '
                  'Cannot be combined with "allowed".',
              items: StringSchema(),
            ),
            'skip_packages': ListSchema(
              description: 'Names of the packages to leave unchecked.',
              items: StringSchema(),
            ),
            'ignore_retrieval_failures': BooleanSchema(
              description:
                  'Whether to carry on when the license of a package cannot '
                  'be retrieved. Defaults to false.',
            ),
          },
          additionalProperties: false,
        ),
        outputSchema: toolOutputSchema,
      ),
      _handlePackagesCheckLicenses,
    );
  }

  static const _createTool = 'create';
  static const _testTool = 'test';
  static const _packagesGetTool = 'packages_get';
  static const _packagesCheckLicensesTool = 'packages_check_licenses';

  /// The `create` subcommands that define the `--workspace` flag.
  ///
  /// `docs_site` is intentionally excluded because it does not mix in the
  /// `Workspace` mixin and therefore rejects the flag.
  static const _workspaceSubcommands = {
    'app_ui_package',
    'flame_game',
    'flutter_app',
    'flutter_package',
    'flutter_plugin',
    'dart_cli',
    'dart_package',
  };

  List<String> _parseCreate(Map<String, Object?> args) {
    final subcommand = args['subcommand']! as String;
    final name = args['name']! as String;

    return [
      'create',
      subcommand,
      name,
      ..._option(args, 'description', '--desc'),
      ..._option(args, 'org_name', '--org-name'),
      ..._option(args, 'output_directory', '-o'),
      ..._option(args, 'application_id', '--application-id'),
      ..._multiOption(args, 'platforms', '--platforms'),
      ..._flag(args, 'publishable', '--publishable'),
      if (_workspaceSubcommands.contains(subcommand))
        ..._negatableFlag(args, 'workspace', 'workspace'),
      ..._option(args, 'executable_name', '--executable-name'),
    ];
  }

  List<String> _parseTest(Map<String, Object?> args) {
    final paths = args['paths'] as List<Object?>? ?? const [];

    // NOTE: 'directory' is intentionally not added here. It is applied as the
    // working directory in [_runToolCommand], not as a positional test target.
    // 'timeout_seconds' is also intentionally not forwarded as a flag: it is
    // enforced as a wall-clock budget in [_runToolCommand]. The `dart test`
    // subcommand would reject a `--timeout` flag, and `flutter test`'s own
    // per-test timeout does not fire when a test awaits a future that never
    // completes, which is the hang [timeout_seconds] exists to bound.
    return [
      ..._flag(args, 'dart', 'dart'),
      'test',
      ..._flag(args, 'coverage', '--coverage'),
      ..._flag(args, 'recursive', '-r'),
      ..._negatableFlag(args, 'optimization', 'optimization'),
      ..._option(args, 'concurrency', '-j'),
      ..._option(args, 'tags', '-t'),
      ..._option(args, 'exclude_coverage', '--exclude-coverage'),
      ..._option(args, 'exclude_tags', '-x'),
      ..._option(args, 'min_coverage', '--min-coverage'),
      ..._option(
        args,
        'test_randomize_ordering_seed',
        '--test-randomize-ordering-seed',
      ),
      ..._flag(args, 'update_goldens', '--update-goldens'),
      ..._multiOption(args, 'dart_define', '--dart-define'),
      ..._multiOption(args, 'dart_define_from_file', '--dart-define-from-file'),
      ..._option(args, 'platform', '--platform'),
      ..._flag(args, 'run_skipped', '--run-skipped'),
      // `--check-ignore` is only defined by `very_good dart test`.
      if (args['dart'] == true)
        ..._negatableFlag(args, 'check_ignore', 'check-ignore'),
      ..._flag(args, 'show_uncovered', '--show-uncovered'),
      // Positional test targets go last, after every option, so that they are
      // parsed as `rest` rather than as a value for the preceding option. The
      // `--` terminator keeps a target that begins with `-` from being read as
      // an option; the parser strips it back out of `rest`, so the test command
      // sees the paths and nothing else.
      if (paths.isNotEmpty) ...['--', ...paths.cast<String>()],
    ];
  }

  /// Returns `[flag]` when `args[key]` is `true`, else nothing.
  static List<String> _flag(
    Map<String, Object?> args,
    String key,
    String flag,
  ) => args[key] == true ? [flag] : const [];

  /// Returns `[--name]` when `args[key]` is `true`, `[--no-name]` when it is
  /// `false`, and nothing when it is not set.
  static List<String> _negatableFlag(
    Map<String, Object?> args,
    String key,
    String name,
  ) => switch (args[key]) {
    true => ['--$name'],
    false => ['--no-$name'],
    _ => const [],
  };

  /// Returns `[option, value]` when `args[key]` is set, else nothing.
  static List<String> _option(
    Map<String, Object?> args,
    String key,
    String option,
  ) => switch (args[key]) {
    final value? => [option, '$value'],
    null => const [],
  };

  /// Returns `[option, value]` for each value of the `args[key]` list.
  static List<String> _multiOption(
    Map<String, Object?> args,
    String key,
    String option,
  ) => [
    for (final value in args[key] as List<Object?>? ?? const []) ...[
      option,
      '$value',
    ],
  ];

  // NOTE: for every tool but `create`, 'directory' is applied as the working
  // directory in [_runToolCommand], not as a positional argument.
  List<String> _parsePackagesGet(Map<String, Object?> args) => [
    'packages',
    'get',
    ..._flag(args, 'recursive', '--recursive'),
    ..._multiOption(args, 'ignore', '--ignore'),
  ];

  List<String> _parsePackagesCheckLicenses(Map<String, Object?> args) => [
    'packages',
    'check',
    'licenses',
    ..._flag(args, 'ignore_retrieval_failures', '--ignore-retrieval-failures'),
    ..._multiOption(args, 'dependency_type', '--dependency-type'),
    ..._multiOption(args, 'allowed', '--allowed'),
    ..._multiOption(args, 'forbidden', '--forbidden'),
    ..._multiOption(args, 'skip_packages', '--skip-packages'),
  ];

  Future<CallToolResult> _handleCreate(Map<String, Object?> args) =>
      _runToolCommand(
        _parseCreate(args),
        toolName: _createTool,
        requestArguments: args,
      );

  Future<CallToolResult> _handleTest(Map<String, Object?> args) {
    if (args['check_ignore'] == true && args['dart'] != true) {
      return Future.value(
        StructuredToolError(
          toolName: _testTool,
          reason:
              '"check_ignore" is only supported by the Dart test runner and '
              'requires "dart": true. Flutter\'s test command does not accept '
              '--check-ignore; omit the argument or set "check_ignore": false '
              'for Flutter runs.',
          failureType: ToolFailureType.validation,
          failureReason: ToolFailureReason.invalidInput,
          attemptedArguments: args,
        ).toCallToolResult(),
      );
    }
    final timeoutSeconds = (args['timeout_seconds'] as num?)?.toInt();
    return _runToolCommand(
      _parseTest(args),
      toolName: _testTool,
      directory: args['directory'] as String?,
      requestArguments: args,
      timeout: timeoutSeconds != null
          ? Duration(seconds: timeoutSeconds)
          : null,
    );
  }

  Future<CallToolResult> _handlePackagesGet(Map<String, Object?> args) =>
      _runToolCommand(
        _parsePackagesGet(args),
        toolName: _packagesGetTool,
        directory: args['directory'] as String?,
        requestArguments: args,
      );

  Future<CallToolResult> _handlePackagesCheckLicenses(
    Map<String, Object?> args,
  ) => _runToolCommand(
    _parsePackagesCheckLicenses(args),
    toolName: _packagesCheckLicensesTool,
    directory: args['directory'] as String?,
    requestArguments: args,
  );

  /// Runs a CLI command in-process and returns a [CallToolResult].
  ///
  /// The command is executed inside an [IOOverrides] zone that:
  ///
  /// * redirects `stdout`/`stderr` into a buffer, so the command's mason
  ///   [Logger] output (test results, compile errors, ...) is captured and
  ///   returned in the result instead of leaking onto the real process stdout,
  ///   which is shared with the MCP JSON-RPC stream (the stdio transport
  ///   requires the server MUST NOT write non-MCP content to stdout); and
  /// * sets the current directory to [directory] when provided, so in-process
  ///   commands that resolve their target from `Directory.current` run in the
  ///   right package (`directory` is the working directory, not a positional
  ///   argument).
  ///
  /// When [timeout] is provided, the command is additionally wrapped in a
  /// [ProcessSignalOverrides] zone and a budget timer. On expiry the server
  /// synthesizes a SIGINT through [ProcessSignalOverrides.addSIGINT]; the test
  /// runner's SIGINT handler cancels its subprocess subscription, which kills
  /// the `flutter_tester` process tree. The call then awaits the command's own
  /// unwind to completion before releasing the lock, so [Directory.current] is
  /// only restored once the hung subprocess is gone — a queued call cannot
  /// have its working directory clobbered by a run that was signalled but
  /// kept spawning subprocesses. A `timedOut` flag disambiguates the server's
  /// synthetic SIGINT from a user Ctrl+C (both complete the test command with
  /// [ExitCode.success]).
  ///
  /// See [ToolRun.capture] for why the [Logger] is built inside the zone.
  Future<CallToolResult> _runToolCommand(
    List<String> args, {
    required String toolName,
    String? directory,
    Map<String, Object?>? requestArguments,
    Duration? timeout,
  }) {
    return _lock.run(() async {
      final run = ToolRun(
        toolName: toolName,
        commandString: 'very_good ${args.join(' ')}',
        directory: directory,
        requestArguments: requestArguments,
      );

      // Apply [directory] as the real working directory for the duration of
      // the run, restoring it afterwards. The underlying commands resolve their
      // target package from the process current directory and spawn
      // subprocesses with it, so it must be the real cwd (not just an
      // IOOverrides override, which subprocesses do not honor).
      final previousDirectory = Directory.current;

      try {
        if (directory != null) Directory.current = directory;
        return await _runWithOptionalTimeout(run, args, timeout);
      } on Exception catch (e, stackTrace) {
        return run.resultForException(e, stackTrace);
      } finally {
        if (directory != null) Directory.current = previousDirectory;
      }
    });
  }

  Future<CallToolResult> _runWithOptionalTimeout(
    ToolRun run,
    List<String> args,
    Duration? timeout,
  ) async {
    if (timeout == null) {
      final exitCode = await run.capture(
        (logger) => _commandRunnerBuilder(logger: logger).run(args),
      );
      return run.resultFor(exitCode);
    }

    var timedOut = false;
    // `ProcessSignalOverrides` only inspects `sigintStream` for non-null to
    // decide whether to install the override; the stream itself is never
    // read because the server routes signals through `addSIGINT()`. An empty
    // stream is enough and leaves nothing to clean up.
    final exitCode = await ProcessSignalOverrides.runZoned(() async {
      final commandFuture = run.capture(
        (logger) => _commandRunnerBuilder(logger: logger).run(args),
      );
      final budget = Timer(timeout, () {
        timedOut = true;
        ProcessSignalOverrides.current?.addSIGINT();
      });
      try {
        return await commandFuture;
      } finally {
        budget.cancel();
      }
    }, sigintStream: const Stream<ProcessSignal>.empty());
    return timedOut ? run.resultForTimeout(timeout) : run.resultFor(exitCode);
  }
}
