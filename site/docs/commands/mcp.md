---
sidebar_position: 4
---

# MCP Server

Start the MCP (Model Context Protocol) server for AI assistant integration with `very_good mcp`.

:::warning
This command relies on the [Dart MCP Server](https://docs.flutter.dev/ai/mcp-server). This is an experimental package and may change or become unstable without notice. Use it with caution at your own risk.
:::

## Usage

```sh
very_good mcp [arguments]
-h, --help    Print this usage information.

Run "very_good help" to see global options.
```

The MCP server exposes Very Good CLI functionality through the [Model Context Protocol](https://modelcontextprotocol.io/), allowing AI assistants to interact with the CLI programmatically. This enables automated project creation, testing, and package management through MCP-compatible tools.

## Available Tools

The MCP server exposes the following tools to AI assistants:

### `create`

Create new Dart or Flutter projects from any of the available [templates](/docs/category/templates).

### `test`

Run tests with optional coverage and optimization. Supports both `dart test` and `flutter test` via a `dart` parameter.

See the [test command](/docs/commands/test) for more details.

### `packages_get`

Install or update Dart/Flutter package dependencies.

See the [get packages command](/docs/commands/get_pkgs) for more details.

### `packages_check_licenses`

Check packages for license compliance.

See the [check licenses command](/docs/commands/check_licenses) for more details.
