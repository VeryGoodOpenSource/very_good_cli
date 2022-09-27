# Loka Flutter CLI

[![Loka][logo]][loka_link]

Developed with 💙 by [Loka][loka_link]

[![ci][ci_badge]][ci_link]
[![coverage][coverage_badge]][ci_link]
[![style: very good analysis][loka_flutter_analysis_badge]][very_good_analysis_link]

---

Loka Command-Line Interface for Dart/Flutter.

## Installing

```sh
dart pub global activate -sgit https://github.com/LokaHQ/loka_flutter_cli
```

## Commands

### `loka_flutter create`

Create a project in seconds based on the provided template. The [Loka Core][loka_flutter_core_link] template is used by default.

![Loka Create][loka_flutter_create]

```sh
Creates a new project in the specified directory.

Usage: loka_flutter create <project name>
-h, --help                    Print this usage information.
-o, --output-directory        The desired output directory when creating a new project.
    --desc                    The description for this new project.
                              (defaults to "Project created by Loka CLI.")
    --executable-name         Used by the dart_cli template, the CLI executable name (defaults to the project name)
    --org-name                The organization for this new project.
                              (defaults to "com.example.lokacore")
-t, --template                The template used to generate this new project.

          [core] (default)    Generate a Loka Flutter application.
          [dart_cli]          Generate a Loka Dart CLI application.
          [dart_pkg]          Generate a reusable Dart package.
          [flutter_pkg]       Generate a reusable Flutter package.
          [flutter_plugin]    Generate a reusable Flutter plugin.

    --android                 The plugin supports the Android platform.
                              (defaults to "true")
    --ios                     The plugin supports the iOS platform.
                              (defaults to "true")
    --web                     The plugin supports the Web platform.
                              (defaults to "true")
    --linux                   The plugin supports the Linux platform.
                              (defaults to "true")
    --macos                   The plugin supports the macOS platform.
                              (defaults to "true")
    --windows                 The plugin supports the Windows platform.
                              (defaults to "true")
```

#### Usage

```sh
# Create a new Flutter app named my_app
loka_flutter create my_app --desc "My new Flutter app"

# Create a new Flutter app named my_app with a custom org
loka_flutter create my_app --desc "My new Flutter app" --org "com.custom.org"

# Create a new Flutter package named my_flutter_package
loka_flutter create my_flutter_package -t flutter_pkg --desc "My new Flutter package"

# Create a new Dart package named my_dart_package
loka_flutter create my_dart_package -t dart_pkg --desc "My new Dart package"

# Create a new Dart CLI application named my_dart_cli
loka_flutter create my_dart_cli -t dart_cli --desc "My new Dart CLI package"

# Create a new Dart CLI application named my_dart_cli with a custom executable name
loka_flutter create my_dart_cli -t dart_cli --desc "My new Dart CLI package" --executable-name my_executable_name

# Create a new Flutter plugin named my_flutter_plugin (all platforms enabled)
loka_flutter create my_flutter_plugin -t flutter_plugin --desc "My new Flutter plugin"

# Create a new Flutter plugin named my_flutter_plugin (some platforms disabled)
loka_flutter create my_flutter_plugin -t flutter_plugin --desc "My new Flutter plugin" --windows false --macos false --linux false
```

### What's Included in Loka Core? 📦

Out of the box, [Loka Core][loka_flutter_core_link] includes:

✅&nbsp; [Cross Platform Support][flutter_cross_platform_link] - Built-in support for iOS, Android, Web, and Windows (MacOS/Linux coming soon!)

✅&nbsp; [Build Flavors][flutter_flavors_link] - Multiple flavor support for development, staging, and production

✅&nbsp; [Internationalization Support][internationalization_link] - Internationalization support using synthetic code generation to streamline the development process

✅&nbsp; [Sound Null-Safety][null_safety_link] - No more null-dereference exceptions at runtime. Develop with a sound, static type system.

✅&nbsp; [Bloc][bloc_link] - Integrated bloc architecture for scalable, testable code which offers a clear separation between business logic and presentation

✅&nbsp; [Testing][testing_link] - Unit and Widget Tests with 100% line coverage (Integration Tests coming soon!)

✅&nbsp; [Logging][logging_link] - Built-in, extensible logging to capture uncaught Flutter and Dart Exceptions

✅&nbsp; [Very Good Analysis][very_good_analysis_link] - Strict Lint Rules which are used at [Loka][loka_link]

✅&nbsp; [Continuous Integration][github_actions_link] - Lint, format, test, and enforce code coverage using [GitHub Actions][github_actions_link]

---

### `loka_flutter packages get`

Get packages in a Dart or Flutter project.

```sh
# Install packages in the current directory
loka_flutter packages get

# Install packages in ./some/other/directory
loka_flutter packages get ./some/other/directory

# Install packages recursively
loka_flutter packages get --recursive

# Install packages recursively (shorthand)
loka_flutter packages get -r
```

#### Complete Usage

```sh
Get packages in a Dart or Flutter project.

Usage: loka_flutter packages get [arguments]
-h, --help         Print this usage information.
-r, --recursive    Install dependencies recursively for all nested packages.

Run "loka_flutter help" to see global options.
```

### `loka_flutter test`

Run tests in a Dart or Flutter project.

```sh
# Run all tests
loka_flutter test

# Run all tests and collect coverage
loka_flutter test --coverage

# Run all tests and enforce 100% coverage
loka_flutter test --coverage --min-coverage 100

# Run only tests in ./some/other/directory
loka_flutter test ./some/other/directory

# Run tests recursively
loka_flutter test --recursive

# Run tests recursively (shorthand)
loka_flutter test -r
```

#### Complete Usage

```sh
Run tests in a Dart or Flutter project.

Usage: loka_flutter test [arguments]
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

Run "loka_flutter help" to see global options.
```

### `loka_flutter --help`

See the complete list of commands and usage information.

```sh
 Loka Command-Line Interface

Usage: loka_flutter <command> [arguments]

Global options:
-h, --help           Print this usage information.
    --version        Print the current version.
    --analytics      Toggle anonymous usage statistics.

          [false]    Disable anonymous usage statistics
          [true]     Enable anonymous usage statistics

Available commands:
  create     loka_flutter create <output directory>
             Creates a new project in the specified directory.
  packages   Command for managing packages.
  test       Run tests in a Dart or Flutter project.

Run "loka_flutter help <command>" for more information about a command.
```

[bloc_link]: https://bloclibrary.dev
[ci_badge]: https://github.com/LokaHQ/loka_flutter_cli/workflows/loka_flutter_cli/badge.svg
[ci_link]: https://github.com/LokaHQ/loka_flutter_cli/actions
[coverage_badge]: https://raw.githubusercontent.com/LokaHQ/loka_flutter_cli/main/coverage_badge.svg
[flutter_cross_platform_link]: https://flutter.dev/docs/development/tools/sdk/release-notes/supported-platforms
[flutter_flavors_link]: https://flutter.dev/docs/deployment/flavors
[github_actions_link]: https://github.com/features/actions
[internationalization_link]: https://flutter.dev/docs/development/accessibility-and-localization/internationalization
[license_badge]: https://img.shields.io/badge/license-MIT-blue.svg
[license_link]: https://opensource.org/licenses/MIT
[logo]: https://loka.com/images/Loka-Blue-Logo.svg
[logging_link]: https://api.flutter.dev/flutter/dart-developer/log.html
[null_safety_link]: https://flutter.dev/docs/null-safety
[testing_link]: https://flutter.dev/docs/testing
[loka_flutter_analysis_badge]: https://img.shields.io/badge/style-very_good_analysis-B22C89.svg
[very_good_analysis_link]: https://pub.dev/packages/very_good_analysis
[loka_flutter_core_link]: doc/loka_flutter_core.md
[loka_flutter_create]: https://raw.githubusercontent.com/LokaHQ/loka_flutter_cli/main/doc/assets/loka_flutter_create.png
[loka_link]: https://loka.com/
