---
sidebar_position: 4
---

# MCP Server 🤖

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

## Configuration

import Tabs from '@theme/Tabs';
import TabItem from '@theme/TabItem';

<Tabs>
  <TabItem value="claude-desktop" label="Claude Desktop" default>

Add to `claude_desktop_config.json`:

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

  </TabItem>
  <TabItem value="claude-code" label="Claude Code">

Add to `.claude/settings.json`:

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

  </TabItem>
  <TabItem value="cursor" label="Cursor">

Add to `.cursor/mcp.json`:

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

  </TabItem>
  <TabItem value="vscode" label="VS Code / GitHub Copilot">

Add to `.vscode/mcp.json`:

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

  </TabItem>
  <TabItem value="windsurf" label="Windsurf">

Add to `~/.windsurf/mcp.json`:

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

  </TabItem>
  <TabItem value="antigravity" label="Antigravity">

Add to `~/.gemini/antigravity/mcp_config.json`:

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

  </TabItem>
</Tabs>

## Available Tools

The MCP server exposes the following tools to AI assistants:

### `create`

Create new Dart or Flutter projects from any of the available [templates](/docs/category/templates).

See the [create command](./create.md) for more details.

### `test`

Run tests with optional coverage and optimization. Supports both `dart test` and `flutter test` via a `dart` parameter.

See the [test command](./test.md) for more details.

### `packages_get`

Install or update Dart/Flutter package dependencies.

See the [get packages command](./get_pkgs.md) for more details.

### `packages_check_licenses`

Check packages for license compliance.

See the [check licenses command](./check_licenses.md) for more details.

## Failure Payloads

A tool call that fails returns `isError: true` with a single text content holding a JSON payload, so an agent can pick a recovery strategy without parsing the command output:

| Field                   | Description                                                                                   |
| ----------------------- | --------------------------------------------------------------------------------------------- |
| `status`                | `partial_failure` when the command printed output before failing, otherwise `failure`.        |
| `failureType`           | The bucket of the failure, which tells whether a retry can help.                              |
| `failureReason`         | The specific cause of the failure.                                                            |
| `attemptedAction`       | The `tool`, the `command` it ran, and the `directory` and `arguments` of the call when given. |
| `reason`                | A human-readable failure cause, such as `failed with exit code 70.`                           |
| `test`                  | `test` failures only: what the test run recorded. See [Test results](#test-results).          |
| `partialResults`        | The output the command printed before failing, when any.                                      |
| `alternativeApproaches` | Recovery suggestions for the `failureReason`.                                                 |

### Failure types and reasons

| `failureType` | `failureReason`            | Cause                                                                                           | Retry can help |
| ------------- | -------------------------- | ----------------------------------------------------------------------------------------------- | -------------- |
| `business`    | `test_failure`             | A test failed, or a test file failed to load. Takes precedence over `coverage_below_threshold`. | No             |
| `business`    | `coverage_below_threshold` | The tests passed, but their coverage is below `min_coverage`.                                   | No             |
| `business`    | `tool_crash`               | The command failed or threw without reporting a more specific cause.                            | Unlikely       |
| `transient`   | `tool_crash`               | The tool exited unexpectedly, left no coverage report behind, or hit a network error.           | Yes            |
| `validation`  | `invalid_input`            | An argument, or the project it points to, was invalid.                                          | No             |
| `validation`  | `usage_error`              | The command line built from the arguments was rejected.                                         | No             |
| `permission`  | `permission_denied`        | The process could not read or write a file it needed.                                           | No             |
| `timeout`     | `timeout`                  | The run exceeded `timeout_seconds` and was stopped.                                             | No             |

### Test results

A `test` failure carries a `test` object whenever the run recorded a result:

- `results`: the `passed`, `failed` and `skipped` test counts, the `durationMs` the tests ran for, and the `failingTests` with their `file`, `name` and a single-line `error`. A test file that failed to load is listed as `loading <file>`. Only the first 20 failing tests are listed; a reader can tell the list was capped by comparing its length against `failed`.
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
      ]
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
      "failingTests": []
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
      "failingTests": []
    }
  },
  "partialResults": "…",
  "alternativeApproaches": ["…"]
}
```
