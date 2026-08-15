---
sidebar_position: 5
---

# Workspace Matrix 🧭

Generate a JSON list of affected projects in the current repository with `very_good workspace matrix`.

This command is designed for workspace-style repositories and CI matrix workflows.

## Usage

```sh
very_good workspace matrix [arguments]
-h, --help          Print this usage information.
    --base=<ref>    Base git ref used for diffing changes (for example, origin/main).

Run "very_good help" to see global options.
```

## Output format

The command writes a JSON array to stdout. Each entry has:

- `name`: package name from `pubspec.yaml`
- `path`: package path relative to the current directory

Example output:

```json
[
  {"name": "core_library_2", "path": "packages/core/core_library_2"},
  {"name": "feature_b", "path": "packages/features/feature_b"}
]
```

## How affected projects are resolved

A project is included when:

1. Files changed between `--base` and `HEAD` are inside the project directory, or
2. The project depends (directly or transitively) on a changed project through `path:` dependencies.

Both `dependencies` and `dev_dependencies` are considered.

## CI example

```sh
very_good workspace matrix --base origin/main
```

You can pass this JSON into a GitHub Actions matrix to run each affected package independently.
