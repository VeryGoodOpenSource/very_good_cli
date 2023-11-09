---
sidebar_position: 1
---

# Overview

Very Good CLI is a Command-Line Interface that enables you to generate VGV-opinionated templates and execute helpful commands.

![Very Good CLI][very_good_cli]

## Quick Start 🚀

### Prerequisites 📝

In order to use Very Good CLI you must have [Dart][dart_sdk] and [Flutter][flutter_sdk] installed on your machine.

:::info
Very Good CLI requires Dart `">=3.1.0 <4.0.0"`
:::

## Installing

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

## Commands

### `very_good create`

Create a very good project in seconds based on the provided template. Each template has a corresponding sub-command. Ex: `very_good create flutter_app` will generate a Flutter starter app.

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

### `very_good packages check licenses`

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

[dart_sdk]: https://dart.dev/get-dart
[flutter_sdk]: https://docs.flutter.dev/get-started/install
[very_good_cli]: https://raw.githubusercontent.com/VeryGoodOpenSource/very_good_cli/main/doc/assets/very_good_create.gif
[new_syntax_link]: /docs/resources/syntax_changes_in_0_10_0
[path_setup_link]: https://dart.dev/tools/pub/cmd/pub-global#running-a-script-from-your-path
