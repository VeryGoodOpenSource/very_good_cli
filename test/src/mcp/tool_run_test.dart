import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dart_mcp/server.dart';
import 'package:mason/mason.dart' show ExitCode;
import 'package:test/test.dart';
import 'package:very_good_cli/src/mcp/tool_run.dart';

void main() {
  group(ToolRun, () {
    late StringBuffer stderrBuffer;
    late ToolRun run;

    setUp(() {
      stderrBuffer = StringBuffer();
      run = ToolRun(
        toolName: 'test',
        commandString: 'very_good test',
        directory: '/tmp/project',
        requestArguments: {'dart': true},
      );
    });

    T withStderr<T>(T Function() body) =>
        IOOverrides.runZoned(body, stderr: () => CapturingStdout(stderrBuffer));

    String textOf(CallToolResult result, [int index = 0]) =>
        (result.content[index] as TextContent).text;

    Map<String, Object?> jsonOf(CallToolResult result) =>
        jsonDecode(textOf(result)) as Map<String, Object?>;

    group('capture', () {
      test('returns the exit code of the command', () async {
        final exitCode = await run.capture((_) async => 42);
        expect(exitCode, equals(42));
      });

      test('redirects stdout and logger output into the run', () async {
        await run.capture((logger) async {
          stdout.write('\x1B[31mfrom stdout\x1B[0m\n');
          logger.info('from logger');
          return ExitCode.success.code;
        });

        final result = run.resultFor(ExitCode.success.code);
        expect(textOf(result, 1), equals('from stdout\nfrom logger'));
      });
    });

    group('resultFor', () {
      test('returns a success result without output', () {
        final result = run.resultFor(ExitCode.success.code);

        expect(result.isError, isFalse);
        expect(result.content, hasLength(1));
        expect(textOf(result), equals('"test" completed successfully.'));
      });

      test('returns a structured failure for a non-zero exit code', () async {
        await run.capture((logger) async {
          logger.info('partial');
          return ExitCode.software.code;
        });

        final result = withStderr(() => run.resultFor(ExitCode.software.code));

        expect(result.isError, isTrue);
        expect(
          jsonOf(result),
          allOf(
            containsPair('status', 'partial_failure'),
            containsPair('failureType', 'business'),
            containsPair('reason', 'failed with exit code 70.'),
            containsPair('partialResults', 'partial'),
            containsPair('attemptedAction', {
              'tool': 'test',
              'command': 'very_good test',
              'directory': '/tmp/project',
              'arguments': {'dart': true},
            }),
          ),
        );
        expect(
          stderrBuffer.toString(),
          equals(
            '[very_good_mcp] "test" business error: '
            'failed with exit code 70. (command: very_good test)\n',
          ),
        );
      });
    });

    group('resultForException', () {
      test('maps a UsageException to a validation failure', () {
        final result = withStderr(
          () => run.resultForException(
            UsageException('bad flag', 'usage'),
            StackTrace.empty,
          ),
        );

        expect(
          jsonOf(result),
          allOf(
            containsPair('failureType', 'validation'),
            containsPair('reason', 'usage error: bad flag'),
          ),
        );
        expect(stderrBuffer.toString(), isNot(contains('Stack trace')));
      });

      test('maps any other exception to a transient failure', () {
        final stackTrace = StackTrace.current;
        final result = withStderr(
          () => run.resultForException(Exception('boom'), stackTrace),
        );

        expect(
          jsonOf(result),
          allOf(
            containsPair('failureType', 'transient'),
            containsPair('reason', 'threw an exception: Exception: boom'),
          ),
        );
        expect(
          stderrBuffer.toString(),
          contains('[very_good_mcp] Stack trace: $stackTrace'),
        );
      });
    });
  });

  group(CapturingStdout, () {
    late StringBuffer buffer;
    late CapturingStdout capturing;

    setUp(() {
      buffer = StringBuffer();
      capturing = CapturingStdout(buffer);
    });

    test('write/writeln/writeAll/writeCharCode append to the buffer', () {
      capturing
        ..write('a')
        ..write(null)
        ..writeln('b')
        ..writeln()
        ..writeAll(['c', 'd'], '-')
        ..writeCharCode(0x65); // 'e'
      expect(buffer.toString(), equals('anullb\n\nc-de'));
    });

    test('add decodes bytes with the current encoding', () {
      capturing.add(utf8.encode('héllo'));
      expect(buffer.toString(), equals('héllo'));
    });

    test('add falls back to char codes on malformed bytes', () {
      capturing.add([0xff, 0xfe]);
      expect(buffer.toString(), equals(String.fromCharCodes([0xff, 0xfe])));
    });

    test('addStream forwards all chunks', () async {
      await capturing.addStream(
        Stream.fromIterable([utf8.encode('x'), utf8.encode('y')]),
      );
      expect(buffer.toString(), equals('xy'));
    });

    test('reports no terminal and tolerates sink lifecycle calls', () async {
      expect(capturing.hasTerminal, isFalse);
      expect(capturing.supportsAnsiEscapes, isFalse);
      expect(capturing.nonBlocking, same(capturing));
      expect(capturing.encoding, equals(utf8));
      expect(capturing.lineTerminator, equals('\n'));
      expect(() => capturing.terminalColumns, throwsA(isA<StdoutException>()));
      expect(() => capturing.terminalLines, throwsA(isA<StdoutException>()));
      capturing.addError('ignored');
      await expectLater(capturing.flush(), completes);
      await expectLater(capturing.close(), completes);
      await expectLater(capturing.done, completes);
    });
  });

  group(sanitizeCommandOutput, () {
    test('strips ANSI escape sequences', () {
      expect(
        sanitizeCommandOutput('\x1B[31mred\x1B[0m and \x1B[1mbold\x1B[0m'),
        equals('red and bold'),
      );
    });

    test('normalizes CRLF to LF', () {
      expect(sanitizeCommandOutput('a\r\nb\r\nc'), equals('a\nb\nc'));
    });

    test('collapses carriage-return redraws to the settled text', () {
      // A spinner redrawing one line in place: erase + rewrite per tick.
      expect(
        sanitizeCommandOutput(
          '\r\x1B[2K00:01 +1\r\x1B[2K00:02 +5\r\x1B[2KAll tests passed!',
        ),
        equals('All tests passed!'),
      );
    });

    test('preserves genuine newlines while collapsing redraws per line', () {
      expect(
        sanitizeCommandOutput('compiling...\rdone\nAll tests passed!'),
        equals('done\nAll tests passed!'),
      );
    });

    test('trims trailing padding left by line erases', () {
      expect(sanitizeCommandOutput('result      '), equals('result'));
    });

    test('leaves plain multi-line output untouched', () {
      expect(sanitizeCommandOutput('line 1\nline 2'), equals('line 1\nline 2'));
    });
  });
}
