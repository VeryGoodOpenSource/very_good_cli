---
sidebar_position: 1
---

# Test 🧪

Run tests in a Dart or Flutter project with `very_good test`.

By default, this command will optimize your tests to run more efficiently by grouping them into a single entrypoint (see [this issue][cov_issue]).

## Usage

```sh
very_good test [arguments]
-h, --help                            Print this usage information.
    --coverage                        Whether to collect coverage information.
-r, --recursive                       Run tests recursively for all nested packages.
    --[no-]optimization               Whether to apply optimizations for test performance.
                                      (defaults to on)
-j, --concurrency                     The number of concurrent test suites run.
                                      (defaults to "4")
-t, --tags                            Run only tests associated with the specified tags.
    --exclude-coverage                A glob which will be used to exclude files that match from the coverage.
-x, --exclude-tags                    Run only tests that do not have the specified tags.
    --min-coverage                    Whether to enforce a minimum coverage percentage.
    --test-randomize-ordering-seed    The seed to randomize the execution order of test cases within test files.
    --update-goldens                  Whether "matchesGoldenFile()" calls within your test methods should update the golden files.
    --force-ansi                      Whether to force ansi output. If not specified, it will maintain the default behavior based on stdout and stderr.
    --dart-define=<foo=bar>           Additional key-value pairs that will be available as constants from the String.fromEnvironment, bool.fromEnvironment, int.fromEnvironment, and double.fromEnvironment constructors. Multiple defines can be passed by repeating "--dart-define" multiple times.

Run "very_good help" to see global options.
```

### Passing Flutter specific arguments

The `flutter test` command exposes more arguments than those available through `very_good test`. Despite this, you can use the argument terminator `--` to signify the end of `very_good test` command options and the beginning of `flutter test` command options; making all `flutter test` arguments available!

For example, if you wish to run `flutter test --no-track-widget-creation` you can simply use `very_good test -- --no-track-widget-creation`.

### Tests without pub install

Unlike `flutter test`, `very_good test` will always run your tests without installing the projects dependencies (i.e. `--no-pub` flag).

This is an optimization done by the CLI because dependency installation is usually run once after cloning the repository. Conversely, running tests locally is usually done many times and it's often unnecessary to re-install dependencies prior to each test run.

If you need to install dependencies before running the tests with `very_good_cli`, be sure to run `very_good packages get` first.

[cov_issue]: https://github.com/flutter/flutter/issues/90225
