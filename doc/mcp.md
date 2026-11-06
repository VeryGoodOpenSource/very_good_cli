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
    "subcommand": "flutter_app | flutter_package | flutter_plugin | flame_game | dart_cli | dart_package | docs_site | app_ui_package",
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
    "paths": ["test/src/foo_test.dart", "test/widgets"],
    "dart": false,
    "coverage": true,
    "recursive": false,
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
    "test_randomize_ordering_seed": "random",
    "timeout_seconds": 120
  }
}
```

All parameters are optional. When `optimization` is not specified, `--no-optimization` is applied by default. When `timeout_seconds` is not specified, no timeout is applied.

`directory` selects the package to test; `paths` selects test files or directories *within* that package. To run another package's tests, point `directory` at it — putting a package path in `paths` runs the wrong thing, or nothing at all. Passing `paths` disables the test optimization step, and it cannot be combined with `recursive`, since each package in a recursive run gets the same relative path and only one of them can resolve it.

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

## Failure Payloads

A tool call that fails returns `isError: true` with a single text content holding a JSON payload, so an agent can pick a recovery strategy without parsing the command output:

| Field | Description |
| --- | --- |
| `status` | `partial_failure` when the command printed output before failing, otherwise `failure`. |
| `failureType` | The bucket of the failure, which tells whether a retry can help. |
| `failureReason` | The specific cause of the failure. |
| `attemptedAction` | The `tool`, the `command` it ran, and the `directory` and `arguments` of the call when given. |
| `reason` | A human-readable failure cause, such as `failed with exit code 70.` |
| `test` | `test` failures only: what the test run recorded. See [Test results](#test-results). |
| `partialResults` | The output the command printed before failing, when any. |
| `alternativeApproaches` | Recovery suggestions for the `failureReason`. |

### Failure types and reasons

| `failureType` | `failureReason` | Cause | Retry can help |
| --- | --- | --- | --- |
| `business` | `test_failure` | A test failed, or a test file failed to load. Takes precedence over `coverage_below_threshold`. | No |
| `business` | `coverage_below_threshold` | The tests passed, but their coverage is below `min_coverage`. | No |
| `business` | `tool_crash` | The command failed or threw without reporting a more specific cause. | Unlikely |
| `transient` | `tool_crash` | The tool exited unexpectedly, left no coverage report behind, or hit a network error. | Yes |
| `validation` | `invalid_input` | An argument, or the project it points to, was invalid. | No |
| `validation` | `usage_error` | The command line built from the arguments was rejected. | No |
| `permission` | `permission_denied` | The process could not read or write a file it needed. | No |
| `timeout` | `timeout` | The run exceeded `timeout_seconds` and was stopped. | No |

### Test results

A `test` failure carries a `test` object whenever the run recorded a result:

- `results`: the `passed`, `failed` and `skipped` test counts, the `durationMs` the tests ran for, and the `failingTests` with their `file`, `name` and a single-line `error`. A test file that failed to load is listed as `loading <file>`. Only the first 20 failing tests are listed; `failingTestsTruncated` is `true` when more failed.
- `coverage`: for a `coverage_below_threshold` failure only, the `actual` and `required` coverage percentages and the `uncoveredLines` grouped per `file`. Only the first 20 lines of the first 20 files are listed; `uncoveredLinesTruncated` is `true` when lines were left out.

In a `recursive` run, counts and durations add up across packages, and file paths are relative to `directory`. A run stopped by `timeout_seconds` reports the tests that finished, with a `durationMs` of `0`.

A failing test:

```json
{
  "status": "partial_failure",
  "failureType": "business",
  "failureReason": "test_failure",
  "attemptedAction": { "tool": "test", "command": "very_good test" },
  "reason": "failed with exit code 70.",
  "test": {
    "results": {
      "passed": 1,
      "failed": 1,
      "skipped": 0,
      "durationMs": 1751,
      "failingTests": [
        {
          "file": "test/counter_test.dart",
          "name": "counter increments",
          "error": "Expected: <2> Actual: <1>"
        }
      ],
      "failingTestsTruncated": false
    }
  },
  "partialResults": "…",
  "alternativeApproaches": ["…"]
}
```

Unmet coverage:

```json
{
  "status": "partial_failure",
  "failureType": "business",
  "failureReason": "coverage_below_threshold",
  "attemptedAction": {
    "tool": "test",
    "command": "very_good test --coverage --min-coverage 100",
    "arguments": { "coverage": true, "min_coverage": "100" }
  },
  "reason": "failed with exit code 70.",
  "test": {
    "results": {
      "passed": 1,
      "failed": 0,
      "skipped": 0,
      "durationMs": 1508,
      "failingTests": [],
      "failingTestsTruncated": false
    },
    "coverage": {
      "actual": 33.33333333333333,
      "required": 100.0,
      "uncoveredLines": [{ "file": "lib/counter.dart", "lines": [7, 8] }],
      "uncoveredLinesTruncated": false
    }
  },
  "partialResults": "…",
  "alternativeApproaches": ["…"]
}
```

A crashed test tool, which reports no `test` results when no test ran:

```json
{
  "status": "partial_failure",
  "failureType": "transient",
  "failureReason": "tool_crash",
  "attemptedAction": {
    "tool": "test",
    "command": "very_good test --coverage",
    "arguments": { "coverage": true }
  },
  "reason": "failed with exit code 69.",
  "partialResults": "…\nThe test runner exited without writing the coverage of . It may have crashed; a retry may succeed.",
  "alternativeApproaches": ["…"]
}
```

A timeout, which carries the results recorded before the run was stopped:

```json
{
  "status": "partial_failure",
  "failureType": "timeout",
  "failureReason": "timeout",
  "attemptedAction": {
    "tool": "test",
    "command": "very_good test",
    "arguments": { "timeout_seconds": 120 }
  },
  "reason": "timed out after 120 seconds.",
  "test": {
    "results": {
      "passed": 12,
      "failed": 0,
      "skipped": 0,
      "durationMs": 0,
      "failingTests": [],
      "failingTestsTruncated": false
    }
  },
  "partialResults": "…",
  "alternativeApproaches": ["…"]
}
```

[mcp_link]: https://modelcontextprotocol.io
