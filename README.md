[![Very Good CLI Logo][cli_logo_white]][cli_link_dark]
[![Very Good CLI Logo][cli_logo_black]][cli_link_light]

[![ci][ci_badge]][ci_link]
[![coverage][coverage_badge]][ci_link]
[![pub package][pub_badge]][pub_link]
[![style: very good analysis][very_good_analysis_badge]][very_good_analysis_link]
[![License: MIT][license_badge]][license_link]

---

A Very Good Command-Line Interface for Dart.

Developed with 💙 by [Very Good Ventures][very_good_ventures_link] 🦄

## Documentation 📝

For official documentation, please visit https://cli.vgv.dev.

## Quick Start 🚀

### Installing 🧑‍💻

```sh
dart pub global activate very_good_cli
```

### Commands ✨

### `very_good create`

Create a very good project in seconds based on the provided template. The [Very Good Core][very_good_core_link] template is used by default.

![Very Good Create][very_good_create]

```sh
Creates a new very good project in the specified directory.

Usage: very_good create <project name>
-h, --help                    Print this usage information.
-o, --output-directory        The desired output directory when creating a new project.
    --desc                    The description for this new project.
                              (defaults to "A Very Good Project created by Very Good CLI.")
    --executable-name         Used by the dart_cli template, the CLI executable name (defaults to the project name)
    --org-name                The organization for this new project.
                              (defaults to "com.example.verygoodcore")
-t, --template                The template used to generate this new project.

          [core] (default)    Generate a Very Good Flutter application.
          [dart_cli]          Generate a Very Good Dart CLI application.
          [dart_pkg]          Generate a reusable Dart package.
          [docs_site]         Generate a Very Good documentation site.
          [flame_game]        Generate a Very Good Flame game.
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
    --application-id          The bundle identifier on iOS or application id on Android. (defaults to <org-name>.<project-name>)
```

#### Usage

```sh
# Create a new Flutter app named my_app
very_good create my_app --desc "My new Flutter app"

# Create a new Flutter app named my_app with a custom org
very_good create my_app --desc "My new Flutter app" --org "com.custom.org"

# Create a new Flutter app named my_app with a custom application id
very_good create my_app --desc "My new Flutter app" --application-id "com.custom.app.id"

# Create a new Flame game named my_game
very_good create my_game -t flame_game --desc "My new Flame game"

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

# Create a new docs site named my_docs_site
very_good create my_docs_site -t docs_site
```

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

### `very_good --help`

See the complete list of commands and usage information.

```sh
🦄 A Very Good Command-Line Interface

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
[cli_logo_black]: https://raw.githubusercontent.com/VeryGoodOpenSource/very_good_cli/main/site/static/img/logo.svg#gh-light-mode-only
[cli_logo_white]: https://raw.githubusercontent.com/VeryGoodOpenSource/very_good_cli/main/site/static/img/logo_dark.svg#gh-dark-mode-only
[logging_link]: https://api.flutter.dev/flutter/dart-developer/log.html
[null_safety_link]: https://flutter.dev/docs/null-safety
[pub_badge]: https://img.shields.io/pub/v/very_good_cli.svg
[pub_link]: https://pub.dartlang.org/packages/very_good_cli
[testing_link]: https://flutter.dev/docs/testing
[very_good_analysis_badge]: https://img.shields.io/badge/style-very_good_analysis-B22C89.svg
[very_good_analysis_link]: https://pub.dev/packages/very_good_analysis
[very_good_core_link]: doc/very_good_core.md
[very_good_create]: https://raw.githubusercontent.com/VeryGoodOpenSource/very_good_cli/main/doc/assets/very_good_create.gif
[very_good_ventures_link]: https://verygood.ventures
[cli_link_dark]: https://github.com/VeryGoodOpenSource/very_good_cli#gh-dark-mode-only
[cli_link_light]: https://github.com/VeryGoodOpenSource/very_good_cli#gh-light-mode-only
