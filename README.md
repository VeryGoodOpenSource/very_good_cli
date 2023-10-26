[<img src="https://raw.githubusercontent.com/VeryGoodOpenSource/very_good_cli/main/site/static/img/cli_icon.svg" align="left" />](https://cli.vgv.dev/)

### Very Good CLI

<br clear="left"/>

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

Or install a [specific version](https://pub.dev/packages/very_good_cli/versions) using:

```sh
dart pub global activate very_good_cli <version>
```

If you haven't already, you might need to [set up your path][path_setup_link].

When that is not possible (eg: CI environments), run `very_good` commands via:

```sh
dart pub global run very_good_cli:very_good <command> <args>
```

### Commands ✨

### [`very_good create`](https://cli.vgv.dev/docs/category/templates)

Create a very good project in seconds based on the provided template. Each template has a corresponding sub-command (e.g.,`very_good create flutter_app` will generate a Flutter starter app).

![Very Good Create][very_good_create]

```sh
Creates a new very good project in the specified directory.

Usage: very_good create <subcommand> <project-name> [arguments]
-h, --help    Print this usage information.

Available subcommands:
  dart_cli          Generate a Very Good Dart CLI application.
  dart_package      Generate a Very Good Dart package.
  docs_site         Generate a Very Good documentation site.
  flame_game        Generate a Very Good Flame game.
  flutter_app       Generate a Very Good Flutter application.
  flutter_package   Generate a Very Good Flutter package.
  flutter_plugin    Generate a Very Good Flutter plugin.

Run "very_good help" to see global options.
```

#### Usage

```sh
# Create a new Flutter app named my_app
very_good create flutter_app my_app

# Create a new Flutter app named my_app with a custom org
very_good create flutter_app my_app --desc "My new Flutter app" --org "com.custom.org"

# Create a new Flutter app named my_app with a custom application id
very_good create flutter_app my_app --desc "My new Flutter app" --application-id "com.custom.app.id"

# Create a new Flame game named my_game
very_good create flame_game my_game --desc "My new Flame game"

# Create a new Wear OS app named my_wear_app
very_good create flutter_app my_wear_app --desc "My new Wear OS app" --template wear

# Create a new Flutter package named my_flutter_package
very_good create flutter_package my_flutter_package --desc "My new Flutter package"

# Create a new Dart package named my_dart_package
very_good create dart_package my_dart_package --desc "My new Dart package"

# Create a new Dart package named my_dart_package that is publishable
very_good create dart_package my_dart_package --desc "My new Dart package" --publishable

# Create a new Dart CLI application named my_dart_cli
very_good create dart_cli my_dart_cli --desc "My new Dart CLI package"

# Create a new Dart CLI application named my_dart_cli with a custom executable name
very_good create dart_cli my_dart_cli --desc "My new Dart CLI package" --executable-name my_executable_name

# Create a new Flutter plugin named my_flutter_plugin (all platforms enabled)
very_good create flutter_plugin my_flutter_plugin --desc "My new Flutter plugin"

# Create a new Flutter plugin named my_flutter_plugin (some platforms only)
very_good create flutter_plugin my_flutter_plugin --desc "My new Flutter plugin" --platforms android,ios,macos

# Create a new docs site named my_docs_site
very_good create docs_site my_docs_site

```

---

### [`very_good test`](https://cli.vgv.dev/docs/commands/test)

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

### [`very_good packages get`](https://cli.vgv.dev/docs/commands/get_pkgs)

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

### [`very_good packages check licenses`](https://cli.vgv.dev/docs/commands/check_licenses)

Check packages' licenses in a Dart or Flutter project.

```sh
# Check licenses in the current directory
very_good packages check licenses

# Only allow the use of certain licenses
very_good packages check licenses --allowed="MIT,BSD-3-Clause,BSD-2-Clause,Apache-2.0"

# Deny the use of certain licenses
very_good packages check licenses --forbidden="unknown"

# Check licenses for certain dependencies types
very_good packages check licenses --dependency-type="direct-main,transitive"
```

### [`very_good --help`](https://cli.vgv.dev/docs/overview)

See the complete list of commands and usage information.

```sh
🦄 A Very Good Command-Line Interface

Usage: very_good <command> [arguments]

Global options:
-h, --help            Print this usage information.
    --version         Print the current version.
    --[no-]verbose    Noisy logging, including all shell commands executed.

Available commands:
  create     very_good create <subcommand> <project-name> [arguments]
             Creates a new very good project in the specified directory.
  packages   Command for managing packages.
  test       Run tests in a Dart or Flutter project.
  update     Update Very Good CLI.

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
[cli_logo_icon]: https://raw.githubusercontent.com/VeryGoodOpenSource/very_good_cli/main/site/static/img/cli_icon.svg
[logging_link]: https://api.flutter.dev/flutter/dart-developer/log.html
[null_safety_link]: https://flutter.dev/docs/null-safety
[pub_badge]: https://img.shields.io/pub/v/very_good_cli.svg
[pub_link]: https://pub.dartlang.org/packages/very_good_cli
[testing_link]: https://flutter.dev/docs/testing
[very_good_analysis_badge]: https://img.shields.io/badge/style-very_good_analysis-B22C89.svg
[very_good_analysis_link]: https://pub.dev/packages/very_good_analysis
[very_good_core_link]: site/docs/templates/core.md
[new_syntax_link]: site/docs/resources/syntax_changes_in_0_10_0.md
[very_good_create]: https://raw.githubusercontent.com/VeryGoodOpenSource/very_good_cli/main/doc/assets/very_good_create.gif
[very_good_ventures_link]: https://verygood.ventures
[path_setup_link]: https://dart.dev/tools/pub/cmd/pub-global#running-a-script-from-your-path
