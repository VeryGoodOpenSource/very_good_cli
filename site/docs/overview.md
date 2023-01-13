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
Very Good CLI requires Dart `">=2.13.0 <3.0.0"`
:::

## Installing

```sh
dart pub global activate very_good_cli
```

## Commands

### `very_good create`

Create a very good project in seconds based on the provided template. Each type of template is described by a sub-command. Ex: `very_good create flutter_app` to create flutter apps.

```sh
Creates a new very good project in the specified directory.

Usage: very_good create <subcommand> <project-name> [arguments]
-h, --help    Print this usage information.

Available subcommands:
  dart_cli          Creates a new very good Dart CLI in the specified directory.
  dart_package      Creates a new very good Dart package in the specified directory.
  docs_site         Creates a new very good docs site in the specified directory.
  flame_game        Creates a new very good Flame game in the specified directory.
  flutter_app       Creates a new very good Flutter app in the specified directory.
  flutter_package   Creates a new very good Flutter package in the specified directory.
  flutter_plugin    Creates a new very good federated Flutter plugin in the specified directory.

Run "very_good help" to see global options.
```

#### Syntax changes in 0.10.0

⚠️ The version 0.10.0 changed the syntax of the `very_good create` command. Learn about the changes [here][new_syntax_link].

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

[dart_sdk]: https://dart.dev/get-dart
[flutter_sdk]: https://docs.flutter.dev/get-started/install
[very_good_cli]: https://raw.githubusercontent.com/VeryGoodOpenSource/very_good_cli/main/doc/assets/very_good_create.gif
[new_syntax_link]: /docs/resources/syntax_changes_in_0_10_0
