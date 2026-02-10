# MCP Server 🤖

Very Good CLI includes an experimental [Model Context Protocol][mcp_link] (MCP) server that exposes CLI functionality as tools for AI agents and editors.

> **Warning**: This is an experimental feature and may change without notice.

## Quick Start 🚀

Start the MCP server:

```sh
# Listens on stdio using JSON-RPC 2.0
very_good mcp
```

### Client Configuration

**Claude Desktop** (`claude_desktop_config.json`):

```json
{
  "mcpServers": {
    "very_good_cli": {
      "command": "very_good",
      "args": ["mcp"]
    }
  }
}
```

**Claude Code** (`.claude/settings.json`):

```json
{
  "mcpServers": {
    "very_good_cli": {
      "command": "very_good",
      "args": ["mcp"]
    }
  }
}
```

**Cursor** (`.cursor/mcp.json`):

```json
{
  "mcpServers": {
    "very_good_cli": {
      "command": "very_good",
      "args": ["mcp"]
    }
  }
}
```

**VS Code / GitHub Copilot** (`.vscode/mcp.json`):

```json
{
  "servers": {
    "very_good_cli": {
      "command": "very_good",
      "args": ["mcp"],
      "type": "stdio"
    }
  }
}
```

**Windsurf** (`~/.windsurf/mcp.json`):

```json
{
  "mcpServers": {
    "very_good_cli": {
      "command": "very_good",
      "args": ["mcp"]
    }
  }
}
```

## Available Tools 🛠️

### `create`

Creates a new Dart or Flutter project from a template.

```json
{
  "tool": "create",
  "arguments": {
    "subcommand": "flutter_app | flutter_package | flutter_plugin | flame_game | dart_cli | dart_package | docs_site",
    "name": "my_app",
    "description": "A Very Good Project created by Very Good CLI.",
    "org_name": "com.example.verygoodcore",
    "output_directory": "./",
    "application_id": "com.example.my_app",
    "platforms": "android,ios,web,macos,linux,windows",
    "publishable": true,
    "executable-name": "my_cli",
    "template": "core | wear"
  }
}
```

`subcommand` and `name` are required. All other parameters are optional.

| Parameter | Applicable subcommands |
| --- | --- |
| `platforms` | `flutter_plugin` (all platforms), `flame_game` (android, ios only) |
| `publishable` | `flutter_package`, `dart_package` |
| `executable-name` | `dart_cli` |
| `template` | `flutter_app` (`core` or `wear`) |

### `test`

Runs tests in a Dart or Flutter project.

```json
{
  "tool": "test",
  "arguments": {
    "directory": "./my_app",
    "dart": false,
    "coverage": true,
    "recursive": true,
    "optimization": true,
    "concurrency": "4",
    "min_coverage": "100",
    "tags": "unit",
    "exclude_tags": "integration",
    "exclude_coverage": "**/*.g.dart",
    "update_goldens": false,
    "force_ansi": false,
    "platform": "chrome | vm | android | ios",
    "dart-define": "foo=bar",
    "dart-define-from-file": "config.json",
    "test_randomize_ordering_seed": "random"
  }
}
```

All parameters are optional. When `optimization` is not specified, `--no-optimization` is applied by default.

### `packages_get`

Installs or updates Dart/Flutter package dependencies.

```json
{
  "tool": "packages_get",
  "arguments": {
    "directory": "./my_app",
    "recursive": true,
    "ignore": "package1,package2"
  }
}
```

All parameters are optional.

### `packages_check_licenses`

Verifies package licenses for compliance.

```json
{
  "tool": "packages_check_licenses",
  "arguments": {
    "directory": "./my_app",
    "licenses": true
  }
}
```

All parameters are optional. `licenses` defaults to `true`.

[mcp_link]: https://modelcontextprotocol.io
