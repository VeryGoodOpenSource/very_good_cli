import 'dart:async';

import 'package:dart_mcp/server.dart';
import 'package:mason/mason.dart' show ExitCode;
import 'package:mocktail/mocktail.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:test/test.dart';
import 'package:very_good_cli/src/mcp/mcp_command.dart';
import 'package:very_good_cli/src/mcp/mcp_server.dart';

class _MockChannelFactory extends Mock {
  StreamChannel<String> call();
}

class _MockServerFactory extends Mock {
  MCPServer call({
    required StreamChannel<String> channel,
  });
}

class _FakeStreamChannel extends Fake implements StreamChannel<String> {}

void main() {
  group('MCPCommand', () {
    late StreamChannelController<String> channelController;

    late _MockChannelFactory channelFactory;
    late _MockServerFactory serverFactory;

    late MCPServer server;

    setUp(() {
      channelController = StreamChannelController<String>();
      channelFactory = _MockChannelFactory();
      serverFactory = _MockServerFactory();

      server = VeryGoodMCPServer(
        channel: channelController.foreign,
      );

      when(() => channelFactory()).thenAnswer(
        (_) => channelController.foreign,
      );

      registerFallbackValue(StackTrace.current);
      registerFallbackValue(_FakeStreamChannel());

      when(
        () => serverFactory(
          channel: any(named: 'channel'),
        ),
      ).thenAnswer((_) => server);
    });

    test('should have correct command name', () {
      final command = MCPCommand(
        channelFactory: channelFactory.call,
        serverFactory: serverFactory.call,
      );
      expect(command.name, 'mcp');
    });

    test('should have correct description', () {
      final command = MCPCommand(
        channelFactory: channelFactory.call,
        serverFactory: serverFactory.call,
      );
      expect(
        command.description,
        '''
Start the MCP (Model Context Protocol) server. WARNING: This is an experimental package and may change or become unstable without notice. Use it with caution at your own risk.''',
      );
    });

    test('constructor uses default factories when not provided', () {
      final command = MCPCommand();

      expect(command, isA<MCPCommand>());
    });

    test('run() returns success exit code', () async {
      final command = MCPCommand(
        channelFactory: channelFactory.call,
        serverFactory: serverFactory.call,
      );

      final runFuture = command.run();

      await Future<void>.delayed(Duration.zero);

      await channelController.local.sink.close();

      final exitCode = await runFuture;

      expect(exitCode, ExitCode.success.code);

      verify(() => channelFactory()).called(1);
      verify(
        () => serverFactory(
          channel: channelController.foreign,
        ),
      ).called(1);
    });

    test('run() uses default channel factory when not provided', () async {
      final defaultFactoryChannelController = StreamChannelController<String>();

      when(
        () => serverFactory(
          channel: any(named: 'channel'),
        ),
      ).thenAnswer((invocation) {
        return VeryGoodMCPServer(
          channel: defaultFactoryChannelController.foreign,
        );
      });

      final command = MCPCommand(
        serverFactory: serverFactory.call,
      );

      final runFuture = command.run();

      await Future<void>.delayed(Duration.zero);

      await defaultFactoryChannelController.local.sink.close();

      final exitCode = await runFuture;
      expect(exitCode, ExitCode.success.code);

      verify(
        () => serverFactory(
          channel: any(named: 'channel'),
        ),
      ).called(1);

      verifyNever(channelFactory.call);
    });

    test(
      'run() returns software exit code when an exception occurs',
      () async {
        final exception = Exception('Something went wrong');
        when(() => channelFactory()).thenThrow(exception);

        final command = MCPCommand(
          channelFactory: channelFactory.call,
          serverFactory: serverFactory.call,
        );

        final exitCode = await command.run();

        expect(exitCode, ExitCode.software.code);

        verify(() => channelFactory()).called(1);
        verifyNever(
          () => serverFactory(
            channel: any(named: 'channel'),
          ),
        );
      },
    );
  });
}
