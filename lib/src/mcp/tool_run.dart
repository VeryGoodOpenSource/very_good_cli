import 'dart:async';
import 'dart:convert';
import 'dart:io' show IOOverrides, IOSink, Stdout, StdoutException, stderr;

import 'package:dart_mcp/server.dart';
import 'package:mason/mason.dart' hide packageVersion;
import 'package:meta/meta.dart';
import 'package:very_good_cli/src/mcp/structured_tool_error.dart';

/// {@template tool_run}
/// A single in-process tool invocation run by the MCP server.
///
/// Owns the buffer that captures the command's output and turns the outcome
/// of the run into a [CallToolResult].
/// {@endtemplate}
class ToolRun {
  /// {@macro tool_run}
  new({
    required this.toolName,
    required this.commandString,
    required this.directory,
    required this.requestArguments,
  });

  /// The name of the MCP tool being run.
  final String toolName;

  /// The equivalent `very_good` command line, used for diagnostics.
  final String commandString;

  /// The working directory the command runs in, if any.
  final String? directory;

  /// The raw arguments of the MCP tool request, if any.
  final Map<String, Object?>? requestArguments;

  final StringBuffer _output = StringBuffer();

  String get _capturedOutput =>
      sanitizeCommandOutput(_output.toString()).trim();

  /// Runs [command] with `stdout`/`stderr` redirected into this run's buffer
  /// and returns its exit code.
  ///
  /// The [Logger] is built inside the zone because mason captures
  /// `IOOverrides.current` at construction time.
  Future<int> capture(Future<int> Function(Logger logger) command) {
    final sink = CapturingStdout(_output);
    return IOOverrides.runZoned(
      () => command(Logger()),
      stdout: () => sink,
      stderr: () => sink,
    );
  }

  /// Maps the command's [exitCode] to a success or failure result.
  CallToolResult resultFor(int exitCode) => exitCode == ExitCode.success.code
      ? _success()
      : failure(
          'failed with exit code $exitCode.',
          failureType: ToolFailureType.fromExitCode(exitCode),
        );

  CallToolResult _success() {
    final captured = _capturedOutput;
    return CallToolResult(
      content: [
        TextContent(text: '"$toolName" completed successfully.'),
        if (captured.isNotEmpty) TextContent(text: captured),
      ],
      isError: false,
    );
  }

  /// Builds a structured JSON failure result from [reason] and [failureType].
  ///
  /// The captured command output is surfaced as `partialResults` so any
  /// diagnostics emitted before a failure or throw are preserved. A short
  /// human-readable summary is also logged to the real stderr (the stdio
  /// transport forbids non-JSON on stdout, so stderr is free for diagnostics).
  CallToolResult failure(
    String reason, {
    required ToolFailureType failureType,
    StackTrace? stackTrace,
  }) {
    final captured = _capturedOutput;
    stderr.writeln(
      '[very_good_mcp] "$toolName" ${failureType.name} error: $reason '
      '(command: $commandString)',
    );
    if (stackTrace != null) {
      stderr.writeln('[very_good_mcp] Stack trace: $stackTrace');
    }
    return StructuredToolError(
      toolName: toolName,
      reason: reason,
      failureType: failureType,
      commandString: commandString,
      directory: directory,
      attemptedArguments: requestArguments,
      capturedOutput: captured,
    ).toCallToolResult();
  }
}

/// A [Stdout] that captures everything written to it into a [StringBuffer]
/// instead of the real process stdout/stderr.
///
/// Used to redirect a command's in-process [Logger] output (which mason routes
/// through `stdout`/`stderr`, including progress spinners) away from the real
/// stdout shared with the MCP JSON-RPC stream. It reports no terminal so mason
/// emits plain, animation-free lines.
@visibleForTesting
class CapturingStdout implements Stdout {
  /// Creates a [CapturingStdout] that appends all writes to [_buffer].
  new(this._buffer);

  final StringBuffer _buffer;

  @override
  Encoding encoding = utf8;

  @override
  String lineTerminator = '\n';

  @override
  void write(Object? object) => _buffer.write(object ?? 'null');

  @override
  void writeln([Object? object = '']) => _buffer.writeln(object ?? '');

  @override
  void writeAll(Iterable<dynamic> objects, [String separator = '']) =>
      _buffer.writeAll(objects, separator);

  @override
  void writeCharCode(int charCode) => _buffer.writeCharCode(charCode);

  @override
  void add(List<int> data) {
    try {
      _buffer.write(encoding.decode(data));
    } on FormatException {
      _buffer.write(String.fromCharCodes(data));
    }
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {}

  @override
  Future<void> addStream(Stream<List<int>> stream) => stream.forEach(add);

  @override
  Future<void> flush() async {}

  @override
  Future<void> close() async {}

  @override
  Future<void> get done => Future<void>.value();

  @override
  bool get hasTerminal => false;

  @override
  bool get supportsAnsiEscapes => false;

  @override
  int get terminalColumns {
    throw const StdoutException('No terminal attached');
  }

  @override
  int get terminalLines {
    throw const StdoutException('No terminal attached');
  }

  @override
  IOSink get nonBlocking => this;
}

/// Matches a CSI ANSI escape sequence (colors, cursor moves, line erases).
final _ansiEscape = RegExp(r'\x1B\[[0-?]*[ -/]*[@-~]');

/// Renders raw captured command output as plain text for a tool result.
///
/// In-process commands (and the test subprocesses they reformat) animate
/// progress with ANSI escape sequences and carriage returns: a spinner redraws
/// a single line in place with `\r` and erases it with `\x1B[2K`. A terminal
/// resolves those to clean lines, but the raw bytes surfaced to an MCP client
/// collapse into one run-on line. This reproduces the terminal's settled view:
///
/// * strips ANSI escape sequences;
/// * normalizes `\r\n` to `\n`; and
/// * collapses carriage-return redraws to the text after the last `\r` on each
///   line (the final state the user would see), trimming trailing padding.
@visibleForTesting
String sanitizeCommandOutput(String raw) {
  return raw
      .replaceAll(_ansiEscape, '')
      .replaceAll('\r\n', '\n')
      .split('\n')
      .map((line) {
        final output = line.contains('\r') ? line.split('\r').last : line;
        return output.trimRight();
      })
      .join('\n');
}
