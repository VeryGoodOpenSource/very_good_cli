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

The `very_good create` command allows you to create a very good project in seconds based on the provided template. The [Flutter Starter App (core)][very_good_core_link] template is used by default.

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
    --publishable             Whether the generated project is intended to be published (Does not affect flutter application templates)
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
[very_good_core_link]: /docs/templates/core
[very_good_cli]: https://raw.githubusercontent.com/VeryGoodOpenSource/very_good_cli/main/doc/assets/very_good_create.gif
