import 'package:dart_mcp/server.dart';
import 'package:mocktail/mocktail.dart';
import 'package:very_good_cli/src/mcp/runner/tool_runner.dart';

/// A [ToolRunner] that records the command a tool asks it to run, instead of
/// running it.
class MockToolRunner extends Mock implements ToolRunner;

/// What a tool asked a [MockToolRunner] to run.
typedef RecordedRun = ({
  List<String> args,
  String toolName,
  String? directory,
  Map<String, Object?>? requestArguments,
  Duration? timeout,
});

/// The result a [MockToolRunner] answers with once stubbed by [stubRun].
final CallToolResult stubbedRunResult = CallToolResult(
  content: [TextContent(text: 'ran')],
);

/// Stubs every run of [runner] to answer with [stubbedRunResult].
void stubRun(MockToolRunner runner) {
  when(
    () => runner.run(
      any(),
      toolName: any(named: 'toolName'),
      directory: any(named: 'directory'),
      requestArguments: any(named: 'requestArguments'),
      timeout: any(named: 'timeout'),
    ),
  ).thenAnswer((_) async => stubbedRunResult);
}

/// Verifies that [runner] ran exactly one command, and returns it.
RecordedRun verifyRun(MockToolRunner runner) {
  final captured = verify(
    () => runner.run(
      captureAny(),
      toolName: captureAny(named: 'toolName'),
      directory: captureAny(named: 'directory'),
      requestArguments: captureAny(named: 'requestArguments'),
      timeout: captureAny(named: 'timeout'),
    ),
  ).captured;
  return (
    args: captured[0] as List<String>,
    toolName: captured[1] as String,
    directory: captured[2] as String?,
    requestArguments: captured[3] as Map<String, Object?>?,
    timeout: captured[4] as Duration?,
  );
}

/// Verifies that [runner] ran no command.
void verifyNoRun(MockToolRunner runner) {
  verifyNever(
    () => runner.run(
      any(),
      toolName: any(named: 'toolName'),
      directory: any(named: 'directory'),
      requestArguments: any(named: 'requestArguments'),
      timeout: any(named: 'timeout'),
    ),
  );
}
