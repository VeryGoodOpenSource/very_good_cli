import 'package:mason/mason.dart';
import 'package:test/test.dart';
import 'package:very_good_cli/src/mcp/mcp_command.dart';

void main() {
  group('MCPCommand', () {
    test('should have correct command name', () {
      final command = MCPCommand(logger: Logger());
      expect(command.name, 'mcp');
    });

    test('should have correct description', () {
      final command = MCPCommand(logger: Logger());
      expect(
        command.description,
        'Start the MCP '
        '(Model Context Protocol) server.',
      );
    });
  });
}
