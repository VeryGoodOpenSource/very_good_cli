---
sidebar_position: 4
---

# Dart CLI 💻

This template is for a Dart Command-Line Interface.

![Very Good Dart CLI][dart_cli]

## Usage

:::tip
Use `-o` or `--output-directory` to specify a custom output directory for the generated project.
:::

```sh
# Create a new Dart CLI application named my_dart_cli
very_good create dart_cli my_dart_cli --desc "My new Dart CLI package"

# Create a new Dart CLI application named my_dart_cli with a custom executable name
very_good create dart_cli my_dart_cli --desc "My new Dart CLI package" --executable-name my_executable_name

# Create a new Dart CLI application named my_dart_cli that is publishable
very_good create dart_cli my_dart_cli --desc "My new Dart CLI package" --publishable

# Create a new Dart CLI named with the name of the current directory
very_good create dart_cli . --desc "My new Dart CLI package"
```

[dart_cli]: /img/dart_cli_hero.png
