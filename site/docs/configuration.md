---
sidebar_position: 3
---

# Configuration ⚙️

Very Good CLI reads a project-level configuration file, `very_good.yaml`, to
persist frequently used command-line arguments so that running the CLI locally
produces the same results as running it on CI.

## Where it lives

The `very_good.yaml` file sits at the root of your project. When you run a Very
Good CLI command, the CLI searches for `very_good.yaml` starting from the
current working directory and walks up through its ancestors. The closest file
wins; configuration from ancestor directories is not merged. When no file is
found, the CLI proceeds with an empty configuration.

This lets a single `very_good.yaml` at the repository root apply to commands
run from any nested package.

## Precedence

For any option, values are resolved in the following order, from highest
priority to lowest:

1. **Command line flag** — an argument passed explicitly on the command line.
2. **Configuration value** — the corresponding value from `very_good.yaml`.
3. **CLI default** — the default value baked into the CLI (or `null` if the
   option has no default).

This means every value in `very_good.yaml` can be overridden per-invocation on
the command line without editing the file.

## Schema

Each top-level key in `very_good.yaml` maps to a Very Good CLI command. Every
field mirrors a CLI flag using `snake_case` (e.g. `--min-coverage` becomes
`min_coverage`). Unrecognized keys cause the CLI to exit with a configuration
error.

```yaml
# very_good.yaml
test: {}
create: {}
dart:
  test: {}
packages:
  get: {}
  check:
    licenses: {}
```

### `test`

Defaults for [`very_good test`](commands/test.md).

```yaml
test:
  coverage: true
  optimization: false
  concurrency: 8
  tags: my-tag
  exclude_coverage: '**/*.g.dart'
  exclude_tags: skip
  min_coverage: 95
  show_uncovered: true
  collect_coverage_from: all # imports | all
  update_goldens: true
  fail_fast: true
  dart_define:
    - FOO=bar
    - X=42
  dart_define_from_file: defines.env
  platform: chrome
  report_on:
    - lib/
    - packages/foo/lib/
  run_skipped: true
  flavor: staging
  timeout: 30
  file_reporter: json:reports/tests.json
```

| Field                   | Type               | Notes                                                                         |
| ----------------------- | ------------------ | ----------------------------------------------------------------------------- |
| `coverage`              | `bool`             | Whether to collect coverage information.                                      |
| `optimization`          | `bool`             | Whether to apply optimizations for test performance.                          |
| `concurrency`           | `int`              | Positive integer. The number of concurrent test suites run.                   |
| `tags`                  | `string`           | Run only tests associated with the specified tags.                            |
| `exclude_coverage`      | `string`           | A glob that excludes matching files from coverage.                            |
| `exclude_tags`          | `string`           | Run only tests that do not have the specified tags.                           |
| `min_coverage`          | `number`           | Between `0` and `100`. Enforces a minimum coverage percentage.                |
| `show_uncovered`        | `bool`             | Whether to show uncovered lines when coverage is below 100%.                  |
| `collect_coverage_from` | `imports` \| `all` | Whether to collect coverage from imported files only or all files.            |
| `update_goldens`        | `bool`             | Whether `matchesGoldenFile()` calls should update the golden files.           |
| `fail_fast`             | `bool`             | Whether to stop running tests after the first failure.                        |
| `dart_define`           | `string` \| `list` | Additional `--dart-define` values.                                            |
| `dart_define_from_file` | `string` \| `list` | Paths of `.json` or `.env` files with `--dart-define-from-file` values.       |
| `platform`              | `string`           | The platform to run tests on (`chrome`, `vm`, `android`, `ios`).              |
| `report_on`             | `string` \| `list` | File paths to report coverage information to.                                 |
| `run_skipped`           | `bool`             | Whether to run skipped tests instead of skipping them.                        |
| `flavor`                | `string`           | The flavor to build for testing.                                              |
| `timeout`               | `int`              | Positive integer (seconds). Maximum time tests may run before being killed.   |
| `file_reporter`         | `string`           | Additional file reporter as `<name>:<path>` (e.g. `json:reports/tests.json`). |

### `create`

Defaults for [`very_good create`](commands/create.md).

```yaml
create:
  description: A configured project.
  org_name: com.very.good
  publishable: true
  template: my-template
  workspace: true
```

| Field         | Type     | Notes                                                              |
| ------------- | -------- | ------------------------------------------------------------------ |
| `description` | `string` | The description for the generated project.                         |
| `org_name`    | `string` | The organization for the generated project.                        |
| `publishable` | `bool`   | Whether the generated project is intended to be published.         |
| `template`    | `string` | The template used to generate the project.                         |
| `workspace`   | `bool`   | Whether the project resolves dependencies from a parent workspace. |

### `dart.test`

Defaults for [`very_good dart test`](commands/test.md). The fields mirror
`test`, minus the Flutter-only flags (`update_goldens`, `flavor`, `timeout`,
`dart_define`, `dart_define_from_file`) plus `check_ignore`.

```yaml
dart:
  test:
    coverage: true
    optimization: false
    concurrency: 8
    tags: my-tag
    exclude_coverage: '**/*.g.dart'
    exclude_tags: skip
    min_coverage: 95
    show_uncovered: true
    collect_coverage_from: all # imports | all
    fail_fast: true
    platform: chrome
    report_on:
      - lib/
      - packages/foo/lib/
    run_skipped: true
    check_ignore: false
    file_reporter: json:reports/tests.json
```

| Field                   | Type               | Notes                                                                         |
| ----------------------- | ------------------ | ----------------------------------------------------------------------------- |
| `coverage`              | `bool`             | Whether to collect coverage information.                                      |
| `optimization`          | `bool`             | Whether to apply optimizations for test performance.                          |
| `concurrency`           | `int`              | Positive integer. The number of concurrent test suites run.                   |
| `tags`                  | `string`           | Run only tests associated with the specified tags.                            |
| `exclude_coverage`      | `string`           | A glob that excludes matching files from coverage.                            |
| `exclude_tags`          | `string`           | Run only tests that do not have the specified tags.                           |
| `min_coverage`          | `number`           | Between `0` and `100`. Enforces a minimum coverage percentage.                |
| `show_uncovered`        | `bool`             | Whether to show uncovered lines when coverage is below 100%.                  |
| `collect_coverage_from` | `imports` \| `all` | Whether to collect coverage from imported files only or all files.            |
| `fail_fast`             | `bool`             | Whether to stop running tests after the first failure.                        |
| `platform`              | `string`           | The platform to run tests on (`chrome`, `vm`).                                |
| `report_on`             | `string` \| `list` | File paths to report coverage information to.                                 |
| `run_skipped`           | `bool`             | Whether to run skipped tests instead of skipping them.                        |
| `check_ignore`          | `bool`             | Whether to respect coverage ignore comments (e.g. `// coverage:ignore-line`). |
| `file_reporter`         | `string`           | Additional file reporter as `<name>:<path>` (e.g. `json:reports/tests.json`). |

### `packages.get`

Defaults for [`very_good packages get`](commands/get_pkgs.md).

```yaml
packages:
  get:
    recursive: true
    ignore:
      - example
      - integration_test
```

| Field       | Type               | Notes                                                            |
| ----------- | ------------------ | ---------------------------------------------------------------- |
| `recursive` | `bool`             | Whether to install dependencies recursively for nested packages. |
| `ignore`    | `string` \| `list` | Packages to exclude from installing dependencies.                |

### `packages.check.licenses`

Defaults for [`very_good packages check licenses`](commands/check_licenses.md).

```yaml
packages:
  check:
    licenses:
      ignore_retrieval_failures: true
      dependency_type:
        - direct-main
        - direct-dev
      allowed:
        - MIT
        - BSD-3-Clause
      skip_packages:
        - very_good_analysis
      reporter: csv # text | csv
```

| Field                       | Type               | Notes                                                                          |
| --------------------------- | ------------------ | ------------------------------------------------------------------------------ |
| `ignore_retrieval_failures` | `bool`             | Whether to disregard licenses that failed to be retrieved.                     |
| `dependency_type`           | `string` \| `list` | One or more of `direct-main`, `direct-dev`, `direct-overridden`, `transitive`. |
| `allowed`                   | `string` \| `list` | Only allow the use of certain licenses.                                        |
| `forbidden`                 | `string` \| `list` | Deny the use of certain licenses. Cannot be combined with `allowed`.           |
| `skip_packages`             | `string` \| `list` | Packages to skip from having their licenses checked.                           |
| `reporter`                  | `text` \| `csv`    | The format used to list all licenses.                                          |

:::info
Options that accept a list also accept a single string. For example,
`ignore: example` is equivalent to `ignore: [example]`.
:::

## Example

A single `very_good.yaml` at the root of a repository can capture the defaults
for every Very Good CLI command used in that project:

```yaml
# very_good.yaml
create:
  org_name: com.very.good
  workspace: true

test:
  min_coverage: 100
  exclude_coverage: '**/*.g.dart'
  report_on:
    - lib/

dart:
  test:
    min_coverage: 100
    exclude_coverage: '**/*.g.dart'
    report_on:
      - lib/

packages:
  get:
    recursive: true
  check:
    licenses:
      dependency_type:
        - direct-main
        - transitive
      allowed:
        - MIT
        - BSD-3-Clause
      reporter: csv
```

With the file above, running `very_good test` behaves the same as running
`very_good test --min-coverage 100 --exclude-coverage '**/*.g.dart' --report-on lib/`.
Any command-line flag still takes precedence, so
`very_good test --min-coverage 90` lowers the coverage threshold for that
single run.
