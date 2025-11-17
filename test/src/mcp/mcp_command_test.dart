import 'dart:async';

import 'package:dart_mcp/server.dart';
import 'package:mason/mason.dart';
import 'package:mocktail/mocktail.dart';
// Note: stream_channel is a transitive dependency via dart_mcp
// ignore: depend_on_referenced_packages
import 'package:stream_channel/stream_channel.dart';
import 'package:test/test.dart';
import 'package:very_good_cli/src/mcp/mcp_command.dart';
import 'package:very_good_cli/src/mcp/mcp_server.dart';

class _MockLogger extends Mock implements Logger {}

class _MockChannelFactory extends Mock {
  StreamChannel<String> call();
}

class _MockServerFactory extends Mock {
  MCPServer call({
    required StreamChannel<String> channel,
    required Logger logger,
  });
}

class _FakeStreamChannel extends Fake implements StreamChannel<String> {}

class _FakeLogger extends Fake implements Logger {}

void main() {
  group('MCPCommand', () {
    late Logger logger;

    late StreamChannelController<String> channelController;

    late _MockChannelFactory channelFactory;
    late _MockServerFactory serverFactory;

    late MCPServer server;

    setUp(() {
      logger = _MockLogger();
      channelController = StreamChannelController<String>();
      channelFactory = _MockChannelFactory();
      serverFactory = _MockServerFactory();

      server = VeryGoodMCPServer(
        channel: channelController.foreign,
        logger: logger,
      );

      when(() => channelFactory()).thenAnswer(
        (_) => channelController.foreign,
      );

      registerFallbackValue(StackTrace.current);
      registerFallbackValue(_FakeStreamChannel());
      registerFallbackValue(_FakeLogger());

      when(
        () => serverFactory(
          channel: any(named: 'channel'),
          logger: any(named: 'logger'),
        ),
      ).thenAnswer((_) => server);

      when(() => logger.info(any())).thenAnswer((_) {});
      when(() => logger.err(any())).thenAnswer((_) {});
    });

    test('should have correct command name', () {
      final command = MCPCommand(
        logger: logger,
        channelFactory: channelFactory.call,
        serverFactory: serverFactory.call,
      );
      expect(command.name, 'mcp');
    });

    test('should have correct description', () {
      final command = MCPCommand(
        logger: logger,
        channelFactory: channelFactory.call,
        serverFactory: serverFactory.call,
      );
      expect(
        command.description,
        'Start the MCP '
        '(Model Context Protocol) server.',
      );
    });

    test('constructor uses default Logger when not provided', () {
      final command = MCPCommand(
        channelFactory: channelFactory.call,
        serverFactory: serverFactory.call,
      );

      expect(command, isA<MCPCommand>());
    });

    test('run() logs success messages and returns success exit code', () async {
      final command = MCPCommand(
        logger: logger,
        channelFactory: channelFactory.call,
        serverFactory: serverFactory.call,
      );

      final runFuture = command.run();

      await Future<void>.delayed(Duration.zero);

      await channelController.local.sink.close();

      final exitCode = await runFuture;

      expect(exitCode, ExitCode.success.code);

      verify(
        () => logger.info('Starting Very Good CLI MCP Server...'),
      ).called(1);
      verify(
        () => logger.info(
          'Server will listen on stdin/stdout for MCP protocol messages',
        ),
      ).called(1);
      verify(
        () => logger.info('MCP Server started successfully'),
      ).called(1);
      verify(() => logger.info('Available tools:')).called(1);
      verify(
        () => logger.info(
          '''
  - create: Create a very good Dart or Flutter project in seconds based on the provided template. Each template has a corresponding sub-command.''',
        ),
      ).called(1);
      verify(
        () => logger.info(
          '  - test: Run tests in a Dart or Flutter project.',
        ),
      ).called(1);
      verify(
        () => logger.info(
          '''
           - packages_get: Install or update Dart/Flutter package dependencies.
          Use after creating a project or modifying pubspec.yaml.
          Supports recursive installation and package exclusion.''',
        ),
      ).called(1);
      verify(
        () => logger.info(
          '''
  - packages_check: Verify package licenses for compliance and validation in a Dart or Flutter project.
            Identifies license types (MIT, BSD, Apache, etc.) for all 
            dependencies. Use to ensure license compatibility.''',
        ),
      ).called(1);

      verify(() => channelFactory()).called(1);
      verify(
        () => serverFactory(
          channel: channelController.foreign,
          logger: logger,
        ),
      ).called(1);
    });

    test('run() uses default channel factory when not provided', () async {
      final defaultFactoryChannelController = StreamChannelController<String>();

      when(
        () => serverFactory(
          channel: any(named: 'channel'),
          logger: logger,
        ),
      ).thenAnswer((invocation) {
        return VeryGoodMCPServer(
          channel: defaultFactoryChannelController.foreign,
          logger: logger,
        );
      });

      final command = MCPCommand(
        logger: logger,
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
          logger: logger,
        ),
      ).called(1);

      verifyNever(channelFactory.call);
    });

    test(
      '''run() logs error and returns software exit code when an exception occurs''',
      () async {
        final command = MCPCommand(
          logger: logger,
          channelFactory: channelFactory.call,
          serverFactory: serverFactory.call,
        );

        final exception = Exception('Something went wrong');
        when(
          () => logger.info('Starting Very Good CLI MCP Server...'),
        ).thenThrow(exception);

        final exitCode = await command.run();

        expect(exitCode, ExitCode.software.code);

        verify(
          () => logger.err('Failed to start MCP server: $exception'),
        ).called(1);

        verify(
          () => logger.err(any(that: startsWith('Stack trace:'))),
        ).called(1);

        verifyNever(() => channelFactory());
        verifyNever(
          () => serverFactory(
            channel: any(named: 'channel'),
            logger: any(named: 'logger'),
          ),
        );
      },
    );
  });
}
