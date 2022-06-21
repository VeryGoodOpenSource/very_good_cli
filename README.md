# Very Good CLI

[![Very Good Ventures][logo_white]][very_good_ventures_link_dark]
[![Very Good Ventures][logo_black]][very_good_ventures_link_light]

Developed with 💙 by [Very Good Ventures][very_good_ventures_link] 🦄

[![ci][ci_badge]][ci_link]
[![coverage][coverage_badge]][ci_link]
[![pub package][pub_badge]][pub_link]
[![style: very good analysis][very_good_analysis_badge]][very_good_analysis_link]
[![License: MIT][license_badge]][license_link]

---

A Very Good Command Line Interface for Dart.

## Installing

```sh
dart pub global activate very_good_cli
```

## Commands

### `very_good create`

Create a very good project in seconds based on the provided template. The [Very Good Core][very_good_core_link] template is used by default.

![Very Good Create][very_good_create]

```sh
Creates a new very good project in the specified directory.

Usage: very_good create <output directory>
-h, --help                    Print this usage information.
    --project-name            The project name for this new project. This must be a valid dart package name.
    --desc                    The description for this new project.
                              (defaults to "A Very Good Project created by Very Good CLI.")
    --executable-name         Used by the dart_cli template, the CLI executable name (defaults to the project name)
    --org-name                The organization for this new project.
                              (defaults to "com.example.verygoodcore")
-t, --template                The template used to generate this new project.

          [core] (default)    Generate a Very Good Flutter application.
          [dart_cli]          Generate a Very Good Dart CLI application.
          [dart_pkg]          Generate a reusable Dart package.
          [flutter_pkg]       Generate a reusable Flutter package.
          [flutter_plugin]    Generate a reusable Flutter federated plugin.
              --android       The plugin supports the Android platform.
              --ios           The plugin supports the iOS platform.
              --web           The plugin supports the Web platform.
              --linux         The plugin supports the Linux platform.
              --macos         The plugin supports the macOS platform.
              --windows       The plugin supports the Windows platform.
```

#### Usage

```sh
# Create a new Flutter app named my_app
very_good create my_app --desc "My new Flutter app"

# Create a new Flutter app named my_app with a custom org
very_good create my_app --desc "My new Flutter app" --org "com.custom.org"

# Create a new Flutter package named my_flutter_package
very_good create my_flutter_package -t flutter_pkg --desc "My new Flutter package"

# Create a new Dart package named my_dart_package
very_good create my_dart_package -t dart_pkg --desc "My new Dart package"

# Create a new Dart CLI application named my_dart_cli
very_good create my_dart_cli -t dart_cli --desc "My new Dart CLI package"

# Create a new Dart CLI application named my_dart_cli with a custom executable name
very_good create my_dart_cli -t dart_cli --desc "My new Dart CLI package" --executable-name my_executable_name

# Create a new Flutter plugin named my_flutter_plugin (all platforms enabled)
very_good create my_flutter_plugin -t flutter_plugin --desc "My new Flutter plugin"

# Create a new Flutter plugin named my_flutter_plugin (some platforms disabled)
very_good create my_flutter_plugin -t flutter_plugin --desc "My new Flutter plugin" --windows false --macos false --linux false
```

### What's Included in Very Good Core? 📦

Out of the box, [Very Good Core][very_good_core_link] includes:

✅&nbsp; [Cross Platform Support][flutter_cross_platform_link] - Built-in support for iOS, Android, Web, and Windows (MacOS/Linux coming soon!)

✅&nbsp; [Build Flavors][flutter_flavors_link] - Multiple flavor support for development, staging, and production

✅&nbsp; [Internationalization Support][internationalization_link] - Internationalization support using synthetic code generation to streamline the development process

✅&nbsp; [Sound Null-Safety][null_safety_link] - No more null-dereference exceptions at runtime. Develop with a sound, static type system.

✅&nbsp; [Bloc][bloc_link] - Integrated bloc architecture for scalable, testable code which offers a clear separation between business logic and presentation

✅&nbsp; [Testing][testing_link] - Unit and Widget Tests with 100% line coverage (Integration Tests coming soon!)

✅&nbsp; [Logging][logging_link] - Built-in, extensible logging to capture uncaught Flutter and Dart Exceptions

✅&nbsp; [Very Good Analysis][very_good_analysis_link] - Strict Lint Rules which are used at [Very Good Ventures][very_good_ventures_link]

✅&nbsp; [Continuous Integration][github_actions_link] - Lint, format, test, and enforce code coverage using [GitHub Actions][github_actions_link]

_\* Learn more at [Flutter Starter App: Very Good Core & CLI][very_good_cli_blog_link]_

---

### `very_good packages get`

Get packages in a Dart or Flutter project.

```sh
# Install packages in the current directory
very_good packages get

# Install packages in ./some/other/directory
very_good packages get ./some/other/directory

# Install packages recursively
very_good packages get --recursive

# Install packages recursively (shorthand)
very_good packages get -r
```

#### Complete Usage

```sh
Get packages in a Dart or Flutter project.

Usage: very_good packages get [arguments]
-h, --help         Print this usage information.
-r, --recursive    Install dependencies recursively for all nested packages.

Run "very_good help" to see global options.
```

### `very_good test`

Run tests in a Dart or Flutter project.

```sh
# Run all tests
very_good test

# Run all tests and collect coverage
very_good test --coverage

# Run all tests and enforce 100% coverage
very_good test --coverage --min-coverage 100

# Run only tests in ./some/other/directory
very_good test ./some/other/directory

# Run tests recursively
very_good test --recursive

# Run tests recursively (shorthand)
very_good test -r
```

#### Complete Usage

```sh
Run tests in a Dart or Flutter project.

Usage: very_good test [arguments]
-h, --help                            Print this usage information.
    --coverage                        Whether to collect coverage information.
-r, --recursive                       Run tests recursively for all nested packages.
    --[no-]optimization               Whether to apply optimizations for test performance.
                                      (defaults to on)
    --exclude-coverage                A glob which will be used to exclude files that match from the coverage.
-x, --exclude-tags                    Run only tests that do not have the specified tags.
    --min-coverage                    Whether to enforce a minimum coverage percentage.
    --test-randomize-ordering-seed    The seed to randomize the execution order of test cases within test files.
    --update-goldens                  Whether "matchesGoldenFile()" calls within your test methods should update the golden files.

Run "very_good help" to see global options.
```

### `very_good --help`

See the complete list of commands and usage information.

```sh
🦄 A Very Good Command Line Interface

Usage: very_good <command> [arguments]

Global options:
-h, --help           Print this usage information.
    --version        Print the current version.
    --analytics      Toggle anonymous usage statistics.

          [false]    Disable anonymous usage statistics
          [true]     Enable anonymous usage statistics

Available commands:
  create     very_good create <output directory>
             Creates a new very good project in the specified directory.
  packages   Command for managing packages.
  test       Run tests in a Dart or Flutter project.

Run "very_good help <command>" for more information about a command.
```

[bloc_link]: https://bloclibrary.dev
[ci_badge]: https://github.com/VeryGoodOpenSource/very_good_cli/workflows/very_good_cli/badge.svg
[ci_link]: https://github.com/VeryGoodOpenSource/very_good_cli/actions
[coverage_badge]: https://raw.githubusercontent.com/VeryGoodOpenSource/very_good_cli/main/coverage_badge.svg
[flutter_cross_platform_link]: https://flutter.dev/docs/development/tools/sdk/release-notes/supported-platforms
[flutter_flavors_link]: https://flutter.dev/docs/deployment/flavors
[github_actions_link]: https://github.com/features/actions
[internationalization_link]: https://flutter.dev/docs/development/accessibility-and-localization/internationalization
[license_badge]: https://img.shields.io/badge/license-MIT-blue.svg
[license_link]: https://opensource.org/licenses/MIT
[logo_black]: https://raw.githubusercontent.com/VGVentures/very_good_brand/main/styles/README/vgv_logo_black.png#gh-light-mode-only
[logo_white]: https://raw.githubusercontent.com/VGVentures/very_good_brand/main/styles/README/vgv_logo_white.png#gh-dark-mode-only
[logging_link]: https://api.flutter.dev/flutter/dart-developer/log.html
[null_safety_link]: https://flutter.dev/docs/null-safety
[pub_badge]: https://img.shields.io/pub/v/very_good_cli.svg
[pub_link]: https://pub.dartlang.org/packages/very_good_cli
[testing_link]: https://flutter.dev/docs/testing
[very_good_analysis_badge]: https://img.shields.io/badge/style-very_good_analysis-B22C89.svg
[very_good_analysis_link]: https://pub.dev/packages/very_good_analysis
[very_good_cli_blog_link]: https://verygood.ventures/blog/flutter-starter-app-very-good-core-cli?utm_source=github&utm_medium=banner&utm_campaign=CLIblog
[very_good_core_link]: doc/very_good_core.md
[very_good_create]: https://raw.githubusercontent.com/VeryGoodOpenSource/very_good_cli/main/doc/assets/very_good_create.gif
[very_good_ventures_link]: https://verygood.ventures/?utm_source=github&utm_medium=banner&utm_campaign=CLI
[very_good_ventures_link_dark]: https://verygood.ventures/?utm_source=github&utm_medium=banner&utm_campaign=CLI#gh-dark-mode-only
[very_good_ventures_link_light]: https://verygood.ventures/?utm_source=github&utm_medium=banner&utm_campaign=CLI#gh-light-mode-only
