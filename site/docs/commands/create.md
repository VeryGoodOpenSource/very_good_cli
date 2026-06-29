---
sidebar_position: 0
---

# Create 🚀

Create a new Very Good project from a template with `very_good create`. Each
template type has a corresponding subcommand.

## Usage

```sh
Creates a new Very Good project in the specified directory.

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
  workspace         Generate a Very Good multi-package workspace.

Run "very_good help" to see global options.
```

:::tip
Use `-o` or `--output-directory` to specify a custom output directory for the
generated project.
:::

## Creating in the current directory

Instead of specifying a project name, you can pass `.` to create the project
in your current directory. Very Good CLI derives the project name from your
current directory's basename. This works with every template subcommand.

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

:::note
You cannot combine `.` with `--output-directory`. Very Good CLI will exit with
an error if you specify both.
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

## Workspaces

`very_good create workspace <name>` scaffolds a multi-package
[pub workspace](https://dart.dev/tools/pub/workspaces) — a root `pubspec.yaml`
with a `workspace:` list plus `apps/` and `packages/` directories for its
members.

```sh
very_good create workspace my_workspace
```

Add members from inside the workspace with the `--workspace` flag. It registers
the new package in the root `workspace:` list and gives it
`resolution: workspace`, so a single `very_good packages get` at the root
resolves everything:

```sh
cd my_workspace
very_good create dart_package my_package -o packages --workspace
very_good create flutter_app  my_app     -o apps     --workspace
```

The `--workspace` / `--no-workspace` flag is available on every template
subcommand. It defaults to off and is a no-op when you are not inside a
workspace.
