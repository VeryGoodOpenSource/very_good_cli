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

A tool rejects arguments it does not define.

### `create`

Creates a new Dart or Flutter project from a template, in `<output_directory>/<name>`.

```json
{
  "tool": "create",
  "arguments": {
    "subcommand": "flutter_app | flutter_package | flutter_plugin | flame_game | dart_cli | dart_package | docs_site | app_ui_package",
    "name": "my_app",
    "description": "A Very Good Project created by Very Good CLI.",
    "org_name": "com.example.verygoodcore",
    "output_directory": "./",
    "application_id": "com.example.my_app",
    "platforms": ["android", "ios", "web", "macos", "linux", "windows"],
    "publishable": true,
    "workspace": false,
    "executable_name": "my_cli"
  }
}
```

`subcommand` and `name` are required. All other parameters are optional.

| Parameter | Applicable subcommands |
| --- | --- |
| `org_name` | `flutter_app`, `flutter_plugin`, `flame_game`, `docs_site` |
| `application_id` | `flutter_app` |
| `platforms` | `flutter_app`, `flame_game` (every platform but `linux`), `flutter_plugin` (every platform) |
| `workspace` | Every subcommand but `docs_site` |
| `executable_name` | `dart_cli` |

### `test`

Runs the tests of a Dart or Flutter package, optionally collecting coverage and enforcing a minimum.

```json
{
  "tool": "test",
  "arguments": {
    "directory": "./my_app",
    "paths": ["test/src/foo_test.dart", "test/widgets"],
    "dart": false,
    "coverage": true,
    "recursive": false,
    "workspace": false,
    "optimization": true,
    "exclude_optimization": ["test/integration/**"],
    "concurrency": 4,
    "min_coverage": 100,
    "show_uncovered": true,
    "check_ignore": true,
    "collect_coverage_from": "imports | all",
    "report_on": ["lib/src"],
    "tags": "unit",
    "exclude_tags": "integration",
    "exclude_coverage": "**/*.g.dart",
    "update_goldens": false,
    "fail_fast": false,
    "run_skipped": false,
    "platform": "chrome | vm | android | ios",
    "flavor": "development",
    "dart_define": ["foo=bar"],
    "dart_define_from_file": ["config.json"],
    "file_reporter": "json:reports/tests.json",
    "shard_index": 1,
    "total_shards": 3,
    "test_randomize_ordering_seed": "random",
    "timeout_seconds": 120
  }
}
```

All parameters are optional. The tool runs `flutter test` unless `dart` is `true`. When `timeout_seconds` is not specified, no timeout is applied.

`directory` selects the package to test; `paths` selects test files or directories *within* that package. To run another package's tests, point `directory` at it — putting a package path in `paths` runs the wrong thing, or nothing at all. Passing `paths` disables the test optimization step, and it cannot be combined with `recursive` or `workspace`, since each package in a multi-package run gets the same relative path and only one of them can resolve it. `recursive` runs every package nested under `directory`, while `workspace` runs every package of the Pub workspace rooted there; the two cannot be combined.

`fail_fast` stops the run at the first failing test, which shortens the loop while fixing a failing suite. `collect_coverage_from` defaults to `imports`, which only counts the files the tests import; `all` also counts the files no test imports, so they weigh against `min_coverage`. `report_on` restricts the coverage report to the given paths, and `exclude_optimization` keeps the matching test files out of the optimized bundle while still running them. `file_reporter` writes the test results to a file, as `<name>:<path>`.

`shard_index` and `total_shards` split the suite across runners and must be set together. Sharding requires the optimization, so it cannot be combined with `paths`, `platform`, `update_goldens` or `"optimization": false`, nor with `min_coverage`, since one shard covers a fraction of the code.

`check_ignore` only applies to Dart tests: `true` requires `"dart": true`. `dart_define`, `dart_define_from_file`, `flavor`, `update_goldens` and the `android` and `ios` platforms only apply to Flutter tests. Every other parameter applies to both runners.

### `packages_get`

Installs the dependencies of a Dart or Flutter package.

```json
{
  "tool": "packages_get",
  "arguments": {
    "directory": "./my_app",
    "recursive": true,
    "ignore": ["package1", "package2"]
  }
}
```

All parameters are optional.

### `packages_check_licenses`

Lists the licenses of the dependencies of a Dart or Flutter package, and fails when one is not allowed.

```json
{
  "tool": "packages_check_licenses",
  "arguments": {
    "directory": "./my_app",
    "dependency_type": ["direct-main", "direct-dev", "transitive", "direct-overridden"],
    "allowed": ["MIT", "BSD-3-Clause"],
    "skip_packages": ["package1"],
    "ignore_retrieval_failures": false,
    "reporter": "text | csv"
  }
}
```

All parameters are optional. `dependency_type` defaults to `["direct-main"]`. Pass `forbidden` instead of `allowed` to reject licenses; the two cannot be combined. `reporter` defaults to `text`; `csv` lists one package per row.

## Results

Every tool returns its result both as text and as [structured content](https://modelcontextprotocol.io/specification/2025-06-18/server/tools#structured-content) with a `status` of `success`, `failure` or `partial_failure`.

A tool call that fails returns `isError: true` with a single text content holding the same JSON payload, so an agent can pick a recovery strategy without parsing the command output. See [the hosted docs](https://cli.vgv.dev/docs/commands/mcp#results) for the payload fields, every `failureType`/`failureReason` pair with whether a retry can help, and example payloads.

[mcp_link]: https://modelcontextprotocol.io
