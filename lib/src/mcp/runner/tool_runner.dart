import 'dart:async';
import 'dart:io' show Directory, IOOverrides, ProcessSignal;

import 'package:dart_mcp/server.dart';
import 'package:mason/mason.dart';
import 'package:meta/meta.dart';
import 'package:very_good_cli/src/cli/cli.dart';
import 'package:very_good_cli/src/command_runner.dart';
import 'package:very_good_cli/src/mcp/runner/lock.dart';
import 'package:very_good_cli/src/mcp/runner/tool_run.dart';

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

/// {@template tool_runner}
/// Runs Very Good CLI commands in-process on behalf of the MCP tools, one at a
/// time, and turns each outcome into a [CallToolResult].
/// {@endtemplate}
class ToolRunner({
  /// {@macro command_runner_builder}
  final CommandRunnerBuilder _commandRunnerBuilder =
      defaultCommandRunnerBuilder,
}) {
  /// {@macro tool_runner}
  this;

  /// Serializes tool runs.
  ///
  /// [run] switches the process-global `Directory.current`, so tool
  /// runs must not overlap — the MCP transport can dispatch tool calls
  /// concurrently (pipelined requests), and overlapping runs would corrupt each
  /// other's working directory. The [Lock] keeps at most one run in flight.
  final _lock = Lock();

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
  Future<CallToolResult> run(
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
