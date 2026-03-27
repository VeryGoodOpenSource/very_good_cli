---
sidebar_position: 0
---

# Create 🚀

Create a new Very Good project from a template with `very_good create`. Each
template type has a corresponding subcommand.

## Usage

```sh
Creates a new very good project in the specified directory.

Usage: very_good create <subcommand> <project-name> [arguments]
-h, --help    Print this usage information.

Available subcommands:
  app_ui_package    Generate a Very Good App UI package.
  dart_cli          Generate a Very Good Dart CLI application.
  dart_package      Generate a Very Good Dart package.
  docs_site         Generate a Very Good documentation site.
  flame_game        Generate a Very Good Flame game.
  flutter_app       Generate a Very Good Flutter application.
  flutter_package   Generate a Very Good Flutter package.
  flutter_plugin    Generate a Very Good Flutter plugin.

Run "very_good help" to see global options.
```

:::tip
Use `-o` or `--output-directory` to specify a custom output directory for the
generated project.
:::

## Creating in the current directory

Instead of specifying a project name, you can pass `.` to create the project
in your current directory. Very Good CLI derives the project name from your
current directory's basename.

For example, if your working directory is `/home/user/my_flutter_app`, the
following command creates a Flutter app named `my_flutter_app` in place:

```sh
# Create a Flutter app named after the current directory
very_good create flutter_app .
```

You can combine `.` with any other supported flags for that template:

```sh
# Create a Flutter app with a custom org name
very_good create flutter_app . --org "com.company"

# Create a Flutter app with a description
very_good create flutter_app . --desc "My production Flutter app"

# Create a publishable Dart package
very_good create dart_package . --desc "My Dart package" --publishable

# Create a Flutter plugin that supports specific platforms
very_good create flutter_plugin . --desc "My plugin" --platforms android,ios,web
```

This works with every template subcommand:

```sh
# Create a Dart package in the current directory
very_good create dart_package .

# Create a Dart CLI app in the current directory
very_good create dart_cli .

# Create a Flutter package in the current directory
very_good create flutter_package .

# Create an App UI package in the current directory
very_good create app_ui_package .

# Create a Flame game in the current directory
very_good create flame_game .

# Create a docs site in the current directory
very_good create docs_site .

# Create a Flutter plugin in the current directory
very_good create flutter_plugin .
```

:::note
You cannot combine `.` with `--output-directory`. Using both together produces
an error.
:::

## Available templates

Each subcommand maps to a specific project template. For detailed usage options
and examples, see the individual template pages:

- [Flutter Starter App](../templates/core.md) — `flutter_app`
- [Dart CLI](../templates/dart_cli.md) — `dart_cli`
- [Dart Package](../templates/dart_pkg.md) — `dart_package`
- [Flutter Package](../templates/flutter_pkg.md) — `flutter_package`
- [Flutter Federated Plugin](../templates/federated_plugin.md) — `flutter_plugin`
- [Flame Game](../templates/flame_game.md) — `flame_game`
- [App UI Package](../templates/app_ui_package.md) — `app_ui_package`
- [Docs Site](../templates/docs_site.md) — `docs_site`
