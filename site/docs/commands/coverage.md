---
sidebar_position: 1.5
---

# Coverage 📊

Merge the lcov reports of sharded or recursive test runs, and enforce a minimum
coverage on the result with `very_good coverage merge`.

## Usage

```sh
very_good coverage merge [lcov files or globs] [arguments]
-h, --help                Print this usage information.
-o, --output=<path>       The path to write the merged lcov report to.
                          (defaults to "coverage/lcov.info")
    --min-coverage        Whether to enforce a minimum coverage percentage.
    --exclude-coverage    A glob which will be used to exclude files that match from the coverage (e.g. '**/*.g.dart').
    --show-uncovered      Whether to show uncovered lines when coverage is below 100%.

Run "very_good help" to see global options.
```

## Merging reports

When you [shard your tests](test.md#sharding-tests-across-ci-runners) or run
them with `--recursive`, every shard or package writes its own
`coverage/lcov.info`. None of them reflects the whole suite, so
`very_good coverage merge` combines them into a single report and checks it the
same way `very_good test --min-coverage` does, with the same output and exit
code.

```sh
# Merge the reports downloaded from each shard
very_good coverage merge 'shards/*/lcov.info' --min-coverage 100

# Merge the reports of every package, after `very_good test -r --coverage`
very_good coverage merge

# Write the merged report somewhere else
very_good coverage merge 'shards/*/lcov.info' --output coverage/merged.info
```

Each argument is either the path to an lcov file or a glob, relative to the
current directory. The CLI expands globs itself, so quote them to get the same
result in bash, zsh, PowerShell, and `cmd`. Use `/` as the separator in globs,
on every platform. A glob that matches no file is an error. Globs skip the
same directories as `--recursive` (such as `build`, `.dart_tool`, and the
platform folders), with a warning; pass a report's path to merge it anyway.

Without arguments, the command looks for the `coverage/lcov.info` of every
package under the current directory, skipping those same directories.

Whether it was found or passed as an argument, a package's
`coverage/lcov.info` report has its source paths prefixed with the path of its
package, so `lib/main.dart` from two packages counts as two files. Other
reports, such as shards downloaded to `shards/1/lcov.info`, are merged as they
are. `exclude_coverage` globs match both the prefixed paths and the paths
within each package, so `lib/src/generated/**` still excludes those files in
every package. The `--output` report is never merged into itself; pass a
different `--output` when the root package has its own tests.

### How reports are merged

Reports are merged by source file:

- Hits are summed per line, per function, and per branch.
- The `LF`, `LH`, `FNF`, `FNH`, `BRF`, and `BRH` totals are recomputed from
  the merged hits.
- Separators in source paths become `/`, and absolute paths under the current
  directory become relative, so reports from Linux, macOS, and Windows runners
  merge together. Absolute paths outside of the current directory are kept as
  they are, with a warning.
- Files padded with 0% coverage by `--collect-coverage-from all` are covered by
  the hits of the other reports.
- Empty reports, such as the one a shard without tests writes, are accepted.

## Configuration

The command has no section of its own in
[`very_good.yaml`](../configuration.md). When a flag isn't passed, it reads the
`min_coverage`, `exclude_coverage`, and `show_uncovered` values from the
`test` section or, when it sets none of them, from the `dart.test` section. The
values of the two sections are never mixed. This lets the threshold you already
enforce in un-sharded runs apply to the merged report.

## Example CI workflow

The following GitHub Actions workflow runs the tests on 3 runners, then
enforces 100% coverage on the merged report:

```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        shard: [1, 2, 3]
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: dart pub global activate very_good_cli
      - run: very_good test --coverage --shard-index ${{ matrix.shard }} --total-shards 3
      - uses: actions/upload-artifact@v4
        with:
          name: coverage-${{ matrix.shard }}
          path: coverage/lcov.info

  coverage:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: dart-lang/setup-dart@v1
      - run: dart pub global activate very_good_cli
      - uses: actions/download-artifact@v4
        with:
          pattern: coverage-*
          path: shards
      - run: very_good coverage merge 'shards/*/lcov.info' --min-coverage 100
```

When the shards also run with `--recursive`, each shard leaves one report per
package. Merge them in the shard job first, so the uploaded report has its
source paths relative to the root, and enforce the threshold in the final job
only. Pass `--min-coverage 0` so that a `min_coverage` from `very_good.yaml`
isn't enforced on the partial report of a single shard:

```yaml
- run: very_good test -r --coverage --shard-index ${{ matrix.shard }} --total-shards 3
- run: very_good coverage merge --output shard.info --min-coverage 0
- uses: actions/upload-artifact@v4
  with:
    name: coverage-${{ matrix.shard }}
    path: shard.info
```

The final job then runs `very_good coverage merge 'shards/*/shard.info'`.
