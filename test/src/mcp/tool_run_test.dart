import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:very_good_cli/src/mcp/tool_run.dart';

void main() {
  group('CapturingStdout', () {
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

  group('sanitizeCommandOutput', () {
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
