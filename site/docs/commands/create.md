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

## Configuring defaults with `very_good.yaml`

To avoid repeating the same flags every time you scaffold a new project, you may create a `very_good.yaml` file at the root of your project. The `create` section accepts the same names as the CLI flags in snake_case (e.g. `--org-name` becomes `org_name`). Values from `very_good.yaml` are used as defaults; anything you pass on the command line takes precedence.

```yaml
# very_good.yaml
create:
  description: A Very Good project.
  org_name: com.very.good
  publishable: true
  template: core
  workspace: true
```

With the file above, running `very_good create flutter_app my_app` behaves the same as running `very_good create flutter_app my_app --desc 'A Very Good project.' --org-name com.very.good --publishable --template core`. You can still override any of these values on the command line, for example `very_good create flutter_app my_app --org-name com.example` to use a different org name for a single run.

The `very_good.yaml` file is looked up starting from the directory where the command runs and walking up through its ancestors. The closest file wins; configuration from ancestor directories is not merged. This lets a single `very_good.yaml` at the repository root apply to commands run from any nested package.

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
