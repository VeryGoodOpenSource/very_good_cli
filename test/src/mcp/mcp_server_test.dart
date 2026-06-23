import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dart_mcp/server.dart';
import 'package:mason/mason.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:test/test.dart';
import 'package:very_good_cli/src/command_runner.dart';
import 'package:very_good_cli/src/mcp/mcp_server.dart';

class _MockVeryGoodCommandRunner extends Mock
    implements VeryGoodCommandRunner {}

int _idCounter = 1;

String _jsonRpcRequest(String method, Map<String, dynamic> params) {
  final id = _idCounter++;
  return jsonEncode({
    'jsonrpc': '2.0',
    'method': method,
    'params': params,
    'id': id,
  });
}

// Helper function for params, as extension type is Map
// This helper casts the dynamic (which is really an extension type)
// to the expected Map type.
Map<String, Object?> _params(dynamic params) => params as Map<String, Object?>;

void main() {
  group('VeryGoodMCPServer', () {
    late VeryGoodCommandRunner mockCommandRunner;
    // The mason Logger the server constructs inside the IOOverrides zone and
    // passes to the builder. Captured here so tests can drive it directly.
    late Logger injectedLogger;
    late StreamChannelController<String> channelController;
    // ignore: unused_local_variable Server is not used directly, but needed to keep the channel open
    late VeryGoodMCPServer server;
    late Stream<Map<String, dynamic>> serverResponses;
    // A real directory used wherever the `directory` argument is applied as the
    // working directory (the server switches the real cwd, which must exist).
    late Directory tempDir;

    setUpAll(() {
      _idCounter = 1;
    });

    Future<Map<String, dynamic>> sendRequest(
      String method, [
      Map<String, Object?> params = const {},
    ]) async {
      final completer = Completer<Map<String, dynamic>>();
      // Get the ID that will be used for this request
      final requestId = _idCounter;

      final subscription = serverResponses.listen((response) {
        if (response['id'] == requestId) {
          completer.complete(response);
        }
      });

      // Send the request (which increments the counter)
      channelController.local.sink.add(
        _jsonRpcRequest(method, params as Map<String, dynamic>),
      );

      final response = await completer.future;
      await subscription.cancel();
      return response;
    }

    setUp(() async {
      mockCommandRunner = _MockVeryGoodCommandRunner();
      tempDir = Directory.systemTemp.createTempSync('vgmcp_test_');
      addTearDown(() => tempDir.deleteSync(recursive: true));
      channelController = StreamChannelController<String>();
      server = VeryGoodMCPServer(
        channel: channelController.foreign,
        commandRunnerBuilder: ({required logger}) {
          injectedLogger = logger;
          return mockCommandRunner;
        },
      );

      serverResponses = channelController.local.stream
          .map((event) => jsonDecode(event) as Map<String, dynamic>)
          .asBroadcastStream();

      registerFallbackValue(
        InitializeRequest(
          protocolVersion: ProtocolVersion.latestSupported,
          capabilities: ClientCapabilities(),
          clientInfo: Implementation(name: 'test', version: '1.0.0'),
        ),
      );
      registerFallbackValue(
        CallToolRequest(name: 'dummyTool', arguments: const {}),
      );

      when(
        () => mockCommandRunner.run(any()),
      ).thenAnswer((_) async => ExitCode.success.code);

      // This is the handshake that
      // MUST happen before any other requests, to fix the timeout.
      final initResponse = await sendRequest(
        InitializeRequest.methodName,
        // Use the helper to cast the extension type
        _params(
          InitializeRequest(
            protocolVersion: ProtocolVersion.latestSupported,
            capabilities: ClientCapabilities(),
            clientInfo: Implementation(name: 'test_client', version: '0.1.0'),
          ),
        ),
      );

      expect(
        initResponse['error'],
        isNull,
        reason: 'Server initialization failed',
      );
    });

    test('constructor uses default logger and runner if not provided', () {
      final defaultFactoryChannelController = StreamChannelController<String>();

      final defaultServer = VeryGoodMCPServer(
        channel: defaultFactoryChannelController.foreign,
      );
      expect(defaultServer, isA<VeryGoodMCPServer>());
    });

    test('initialize (via tools/list) registers all 4 tools', () async {
      // The server is ALREADY initialized in setUp.
      // We can just send a 'tools/list' request directly.
      final response = await sendRequest(ListToolsRequest.methodName);

      expect(response['error'], isNull);
      expect(response['result'], isA<Map<String, dynamic>>());

      final result = ListToolsResult.fromMap(
        response['result'] as Map<String, Object?>,
      );
      expect(result.tools.length, 4);
      expect(
        result.tools.map((t) => t.name),
        containsAll([
          'create',
          'test',
          'packages_get',
          'packages_check_licenses',
        ]),
      );
    });

    group('Tool: create', () {
      test('handles basic case', () async {
        final response = await sendRequest(
          CallToolRequest.methodName,
          _params(
            CallToolRequest(
              name: 'create',
              arguments: {'subcommand': 'flutter_app', 'name': 'my_app'},
            ),
          ),
        );

        expect(response['error'], isNull);
        final result = CallToolResult.fromMap(
          response['result'] as Map<String, Object?>,
        );
        expect(result.isError, isFalse);
        expect(
          (result.content.first as TextContent).text,
          '"create" completed successfully.',
        );

        final capturedArgs =
            verify(() => mockCommandRunner.run(captureAny())).captured.first
                as List<String>;
        expect(capturedArgs, ['create', 'flutter_app', 'my_app']);
      });

      test('handles all arguments', () async {
        await sendRequest(
          CallToolRequest.methodName,
          _params(
            CallToolRequest(
              name: 'create',
              arguments: {
                'subcommand': 'flutter_app',
                'name': 'my_app',
                'description': 'my_desc',
                'org_name': 'com.test',
                'output_directory': 'my_dir',
                'application_id': 'com.test.my_app',
                'platforms': 'ios,web',
                'publishable': true,
                'executable-name': 'my_cli',
                'template': 'core',
              },
            ),
          ),
        );

        final capturedArgs =
            verify(() => mockCommandRunner.run(captureAny())).captured.first
                as List<String>;
        expect(capturedArgs, [
          'create',
          'flutter_app',
          'my_app',
          '--desc',
          'my_desc',
          '--org-name',
          'com.test',
          '-o',
          'my_dir',
          '--application-id',
          'com.test.my_app',
          '--platforms',
          'ios,web',
          '--publishable',
          '--executable-name',
          'my_cli',
          '-t',
          'core',
        ]);
      });

      test('handles command runner failure', () async {
        when(
          () => mockCommandRunner.run(any()),
        ).thenAnswer((_) async => ExitCode.software.code);

        final response = await sendRequest(
          CallToolRequest.methodName,
          _params(
            CallToolRequest(
              name: 'create',
              arguments: {'subcommand': 'flutter_app', 'name': 'my_app'},
            ),
          ),
        );

        expect(response['error'], isNull);
        final result = CallToolResult.fromMap(
          response['result'] as Map<String, Object?>,
        );
        expect(result.isError, isTrue);
        expect(
          (result.content.first as TextContent).text,
          contains('"create" failed with exit code'),
        );
      });

      test('handles argument parsing exception', () async {
        // Missing 'name' argument
        final response = await sendRequest(
          CallToolRequest.methodName,
          _params(
            CallToolRequest(
              name: 'create',
              arguments: {'subcommand': 'flutter_app'},
            ),
          ),
        );

        // The handler's try/catch will catch this
        expect(response['error'], isNull);
        final result = CallToolResult.fromMap(
          response['result'] as Map<String, Object?>,
        );
        expect(result.isError, isTrue);
        expect(
          (result.content.first as TextContent).text,
          contains('Required property "name" is missing at path #root'),
        );
      });
    });

    group('Tool: test', () {
      test('handles default args (no flags added)', () async {
        await sendRequest(
          CallToolRequest.methodName,
          _params(CallToolRequest(name: 'test', arguments: {})),
        );

        final capturedArgs =
            verify(() => mockCommandRunner.run(captureAny())).captured.first
                as List<String>;
        expect(capturedArgs, ['test']);
      });

      test('passes --no-optimization when explicitly false', () async {
        await sendRequest(
          CallToolRequest.methodName,
          _params(
            CallToolRequest(name: 'test', arguments: {'optimization': false}),
          ),
        );

        final capturedArgs =
            verify(() => mockCommandRunner.run(captureAny())).captured.first
                as List<String>;
        expect(capturedArgs, ['test', '--no-optimization']);
      });

      test('handles all arguments', () async {
        await sendRequest(
          CallToolRequest.methodName,
          _params(
            CallToolRequest(
              name: 'test',
              arguments: {
                'dart': true,
                'coverage': true,
                'recursive': true,
                'optimization': true,
                'concurrency': '8',
                'tags': 'a,b',
                'exclude_coverage': '**/*.g.dart',
                'exclude_tags': 'c,d',
                'min_coverage': '90',
                'test_randomize_ordering_seed': '123',
                'update_goldens': true,
                'force_ansi': true,
                'dart-define': 'foo=bar',
                'dart-define-from-file': 'my_file.json',
                'platform': 'chrome',
                'run_skipped': true,
                'check_ignore': true,
                'timeout_seconds': 60,
              },
            ),
          ),
        );

        final capturedArgs =
            verify(() => mockCommandRunner.run(captureAny())).captured.first
                as List<String>;
        expect(capturedArgs, [
          'dart',
          'test',
          '--coverage',
          '-r',
          '-j',
          '8',
          '-t',
          'a,b',
          '--exclude-coverage',
          '**/*.g.dart',
          '-x',
          'c,d',
          '--min-coverage',
          '90',
          '--test-randomize-ordering-seed',
          '123',
          '--update-goldens',
          '--force-ansi',
          '--dart-define',
          'foo=bar',
          '--dart-define-from-file',
          'my_file.json',
          '--platform',
          'chrome',
          '--run-skipped',
          '--check-ignore',
          '--timeout',
          '60',
        ]);
      });

      test('does not pass directory as a positional argument', () async {
        await sendRequest(
          CallToolRequest.methodName,
          _params(
            CallToolRequest(
              name: 'test',
              arguments: {'directory': tempDir.path},
            ),
          ),
        );

        final capturedArgs =
            verify(() => mockCommandRunner.run(captureAny())).captured.first
                as List<String>;
        expect(capturedArgs, ['test']);
      });

      test('does not pass directory as a positional with dart flag', () async {
        await sendRequest(
          CallToolRequest.methodName,
          _params(
            CallToolRequest(
              name: 'test',
              arguments: {'directory': tempDir.path, 'dart': true},
            ),
          ),
        );

        final capturedArgs =
            verify(() => mockCommandRunner.run(captureAny())).captured.first
                as List<String>;
        expect(capturedArgs, ['dart', 'test']);
      });

      test('handles command failure', () async {
        when(
          () => mockCommandRunner.run(any()),
        ).thenAnswer((_) async => ExitCode.software.code);
        final response = await sendRequest(
          CallToolRequest.methodName,
          _params(CallToolRequest(name: 'test', arguments: {})),
        );

        expect(response['error'], isNull);
        final result = CallToolResult.fromMap(
          response['result'] as Map<String, Object?>,
        );
        expect(result.isError, isTrue);
        expect(
          (result.content.first as TextContent).text,
          contains('"test" failed with exit code'),
        );
      });

      test('passes --timeout when timeout_seconds is provided', () async {
        await sendRequest(
          CallToolRequest.methodName,
          _params(
            CallToolRequest(
              name: 'test',
              arguments: {'timeout_seconds': 120},
            ),
          ),
        );

        final capturedArgs =
            verify(() => mockCommandRunner.run(captureAny())).captured.first
                as List<String>;
        expect(capturedArgs, ['test', '--timeout', '120']);
      });
    });

    group('Tool: packages_get', () {
      test('handles basic case', () async {
        await sendRequest(
          CallToolRequest.methodName,
          _params(CallToolRequest(name: 'packages_get', arguments: {})),
        );

        final capturedArgs =
            verify(() => mockCommandRunner.run(captureAny())).captured.first
                as List<String>;
        expect(capturedArgs, ['packages', 'get']);
      });

      test('handles all arguments (with split "ignore")', () async {
        final tempDir = Directory.systemTemp.createTempSync('vgmcp_');
        addTearDown(() => tempDir.deleteSync(recursive: true));

        await sendRequest(
          CallToolRequest.methodName,
          _params(
            CallToolRequest(
              name: 'packages_get',
              arguments: {
                'directory': tempDir.path,
                'recursive': true,
                'ignore': 'pkg1, pkg2',
              },
            ),
          ),
        );

        final capturedArgs =
            verify(() => mockCommandRunner.run(captureAny())).captured.first
                as List<String>;
        expect(capturedArgs, [
          'packages',
          'get',
          '--recursive',
          '--ignore',
          'pkg1',
          '--ignore',
          'pkg2',
        ]);
      });
    });

    group('Tool: packages_check_licenses', () {
      test('handles basic case (licenses=true)', () async {
        final tempDir = Directory.systemTemp.createTempSync('vgmcp_');
        addTearDown(() => tempDir.deleteSync(recursive: true));

        await sendRequest(
          CallToolRequest.methodName,
          _params(
            CallToolRequest(
              name: 'packages_check_licenses',
              arguments: {'licenses': true, 'directory': tempDir.path},
            ),
          ),
        );

        final capturedArgs =
            verify(() => mockCommandRunner.run(captureAny())).captured.first
                as List<String>;
        expect(capturedArgs, ['packages', 'check', 'licenses']);
      });

      test('defaults to licenses=true if not provided', () async {
        final tempDir = Directory.systemTemp.createTempSync('vgmcp_');
        addTearDown(() => tempDir.deleteSync(recursive: true));

        await sendRequest(
          CallToolRequest.methodName,
          _params(
            CallToolRequest(
              name: 'packages_check_licenses',
              arguments: {'directory': tempDir.path},
            ),
          ),
        );

        final capturedArgs =
            verify(() => mockCommandRunner.run(captureAny())).captured.first
                as List<String>;
        expect(capturedArgs, ['packages', 'check', 'licenses']);
      });

      test('returns error if licenses=false', () async {
        final response = await sendRequest(
          CallToolRequest.methodName,
          _params(
            CallToolRequest(
              name: 'packages_check_licenses',
              arguments: {'licenses': false},
            ),
          ),
        );

        expect(response['error'], isNull);
        final result = CallToolResult.fromMap(
          response['result'] as Map<String, Object?>,
        );
        expect(result.isError, isTrue);
        expect(
          (result.content.first as TextContent).text,
          contains('No check specified'),
        );
        verifyNever(() => mockCommandRunner.run(any()));
      });
    });

    group('_runToolCommand error handling', () {
      test('handles UsageException with descriptive message', () async {
        final exception = UsageException('bad usage', 'usage string');
        when(() => mockCommandRunner.run(any())).thenThrow(exception);

        final response = await sendRequest(
          CallToolRequest.methodName,
          _params(
            CallToolRequest(
              name: 'create',
              arguments: {'subcommand': 'flutter_app', 'name': 'my_app'},
            ),
          ),
        );

        expect(response['error'], isNull);
        final result = CallToolResult.fromMap(
          response['result'] as Map<String, Object?>,
        );

        expect(result.isError, isTrue);
        final text = (result.content.first as TextContent).text;
        expect(text, contains('"create" usage error: bad usage'));
        expect(text, contains('Command: very_good'));
      });

      test('handles general Exception with descriptive message', () async {
        final exception = Exception('big bad');
        when(() => mockCommandRunner.run(any())).thenThrow(exception);

        final response = await sendRequest(
          CallToolRequest.methodName,
          _params(
            CallToolRequest(
              name: 'create',
              arguments: {'subcommand': 'flutter_app', 'name': 'my_app'},
            ),
          ),
        );

        expect(response['error'], isNull);
        final result = CallToolResult.fromMap(
          response['result'] as Map<String, Object?>,
        );

        expect(result.isError, isTrue);
        final text = (result.content.first as TextContent).text;
        expect(text, contains('"create" threw an exception'));
        expect(text, contains('big bad'));
        expect(text, contains('Command: very_good'));
      });
    });

    group('directory (working directory)', () {
      late Directory tempDir;
      late String originalCwd;

      setUp(() {
        originalCwd = Directory.current.path;
        tempDir = Directory.systemTemp.createTempSync('vgmcp_cwd_');
        addTearDown(() {
          // Always restore the cwd so a failure cannot leak into other tests.
          Directory.current = originalCwd;
          if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
        });
      });

      for (final toolName in const [
        'test',
        'packages_get',
        'packages_check_licenses',
      ]) {
        test('"$toolName" runs in the requested directory', () async {
          String? cwdDuringRun;
          when(() => mockCommandRunner.run(any())).thenAnswer((_) async {
            cwdDuringRun = Directory.current.resolveSymbolicLinksSync();
            return ExitCode.success.code;
          });

          final response = await sendRequest(
            CallToolRequest.methodName,
            _params(
              CallToolRequest(
                name: toolName,
                arguments: {'directory': tempDir.path},
              ),
            ),
          );

          final result = CallToolResult.fromMap(
            response['result'] as Map<String, Object?>,
          );
          expect(result.isError, isFalse);
          expect(cwdDuringRun, equals(tempDir.resolveSymbolicLinksSync()));
          // The working directory is restored after the command completes.
          expect(Directory.current.path, equals(originalCwd));
        });
      }
    });

    group('captured command output', () {
      test('includes captured output in a failure result', () async {
        when(() => mockCommandRunner.run(any())).thenAnswer((_) async {
          stdout.write('compile error: boom');
          stderr.write('stderr detail');
          return ExitCode.unavailable.code;
        });

        final response = await sendRequest(
          CallToolRequest.methodName,
          _params(CallToolRequest(name: 'test', arguments: {})),
        );

        final result = CallToolResult.fromMap(
          response['result'] as Map<String, Object?>,
        );
        expect(result.isError, isTrue);
        final text = (result.content.first as TextContent).text;
        expect(text, contains('"test" failed with exit code 69'));
        expect(text, contains('compile error: boom'));
        expect(text, contains('stderr detail'));
      });

      test('includes captured output in a success result', () async {
        when(() => mockCommandRunner.run(any())).thenAnswer((_) async {
          stdout.write('All tests passed!');
          return ExitCode.success.code;
        });

        final response = await sendRequest(
          CallToolRequest.methodName,
          _params(CallToolRequest(name: 'test', arguments: {})),
        );

        final result = CallToolResult.fromMap(
          response['result'] as Map<String, Object?>,
        );
        expect(result.isError, isFalse);
        expect(result.content, hasLength(2));
        expect(
          (result.content[0] as TextContent).text,
          equals('"test" completed successfully.'),
        );
        expect(
          (result.content[1] as TextContent).text,
          equals('All tests passed!'),
        );
      });

      test('routes the injected in-zone logger through the capture', () async {
        // The load-bearing invariant: a Logger constructed INSIDE the zone
        // writes through the capture override. Driving the injected logger
        // (not the dart:io globals) is what would fail if the Logger were
        // built outside the zone.
        when(() => mockCommandRunner.run(any())).thenAnswer((_) async {
          injectedLogger
            ..info('stdout via logger')
            ..err('stderr via logger');
          return ExitCode.unavailable.code;
        });

        final response = await sendRequest(
          CallToolRequest.methodName,
          _params(CallToolRequest(name: 'test', arguments: {})),
        );

        final result = CallToolResult.fromMap(
          response['result'] as Map<String, Object?>,
        );
        final text = (result.content.first as TextContent).text;
        expect(text, contains('stdout via logger'));
        expect(text, contains('stderr via logger'));
      });

      test('includes captured output when the run throws', () async {
        when(() => mockCommandRunner.run(any())).thenAnswer((_) async {
          stdout.write('partial output before crash');
          throw Exception('boom');
        });

        final response = await sendRequest(
          CallToolRequest.methodName,
          _params(CallToolRequest(name: 'test', arguments: {})),
        );

        final result = CallToolResult.fromMap(
          response['result'] as Map<String, Object?>,
        );
        expect(result.isError, isTrue);
        final text = (result.content.first as TextContent).text;
        expect(text, contains('"test" threw an exception'));
        expect(text, contains('partial output before crash'));
      });

      test('omits the output block when nothing was captured', () async {
        when(
          () => mockCommandRunner.run(any()),
        ).thenAnswer((_) async => ExitCode.success.code);

        final response = await sendRequest(
          CallToolRequest.methodName,
          _params(CallToolRequest(name: 'test', arguments: {})),
        );

        final result = CallToolResult.fromMap(
          response['result'] as Map<String, Object?>,
        );
        expect(result.content, hasLength(1));
        expect(
          (result.content.first as TextContent).text,
          equals('"test" completed successfully.'),
        );
      });
    });

    group('working directory', () {
      test(
        'serializes overlapping runs so each keeps its own directory',
        () async {
          final dirA = Directory.systemTemp.createTempSync('vgmcp_a_');
          final dirB = Directory.systemTemp.createTempSync('vgmcp_b_');
          addTearDown(() {
            dirA.deleteSync(recursive: true);
            dirB.deleteSync(recursive: true);
          });

          // For each run record (cwd at start, cwd after an async gap). With
          // serialization the cwd is stable within a run; without it, a sibling
          // run's Directory.current mutation would clobber it across the gap.
          final pairs = <List<String>>[];
          when(() => mockCommandRunner.run(any())).thenAnswer((_) async {
            final before = Directory.current.path;
            await Future<void>.delayed(const Duration(milliseconds: 20));
            final after = Directory.current.path;
            pairs.add([before, after]);
            return ExitCode.success.code;
          });

          await Future.wait([
            sendRequest(
              CallToolRequest.methodName,
              _params(
                CallToolRequest(
                  name: 'test',
                  arguments: {'directory': dirA.path},
                ),
              ),
            ),
            sendRequest(
              CallToolRequest.methodName,
              _params(
                CallToolRequest(
                  name: 'test',
                  arguments: {'directory': dirB.path},
                ),
              ),
            ),
          ]);

          expect(pairs, hasLength(2));
          for (final pair in pairs) {
            expect(
              pair[1],
              equals(pair[0]),
              reason: 'cwd must stay stable for the duration of a single run',
            );
          }
          expect(
            pairs
                .map((p) => Directory(p[0]).resolveSymbolicLinksSync())
                .toSet(),
            equals({
              dirA.resolveSymbolicLinksSync(),
              dirB.resolveSymbolicLinksSync(),
            }),
          );
        },
      );

      test('errors and restores cwd for a non-existent directory', () async {
        final before = Directory.current.path;
        final missing =
            '${Directory.systemTemp.path}/vgmcp_missing_dir_should_not_exist';

        final response = await sendRequest(
          CallToolRequest.methodName,
          _params(
            CallToolRequest(name: 'test', arguments: {'directory': missing}),
          ),
        );

        final result = CallToolResult.fromMap(
          response['result'] as Map<String, Object?>,
        );
        expect(result.isError, isTrue);
        // cwd switch failed before the run, so it was never executed...
        verifyNever(() => mockCommandRunner.run(any()));
        // ...and the process directory is unchanged.
        expect(Directory.current.path, equals(before));
      });
    });
  });

  group('defaultCommandRunnerBuilder', () {
    test('builds a VeryGoodCommandRunner', () {
      expect(
        defaultCommandRunnerBuilder(logger: Logger()),
        isA<VeryGoodCommandRunner>(),
      );
    });
  });

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
