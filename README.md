# Very Good CLI

[![Very Good Ventures][logo]][very_good_ventures_link]

Developed with 💙 by [Very Good Ventures][very_good_ventures_link] 🦄

[![ci][ci_badge]][ci_link]
[![coverage][coverage_badge]][ci_link]
[![pub package][pub_badge]][pub_link]
[![style: very good analysis][very_good_analysis_badge]][very_good_analysis_link]
[![License: MIT][license_badge]][license_link]

---

A Very Good Command Line Interface for Dart.

## Installing

```sh
$ dart pub global activate very_good_cli
```

## Commands

### `$ very_good create`

Create a new very good flutter starter application in seconds based on [Very Good Core][very_good_core_link].

![Very Good Create][very_good_create]

#### Usage

```sh
Creates a new very good flutter project in the specified directory.

Usage: very_good create <output directory>
-h, --help            Print this usage information.
    --project-name    The project name for this new project. This must be a valid dart package name.
    --org-name        The organization for this new project.
                      (defaults to "com.example.verygoodcore")
-t, --template        The template to use to generate this new project.
```

### What's Included? 📦

Out of the box, [Very Good Core][very_good_core_link] includes:

✅&nbsp; [Cross Platform Support][flutter_cross_platform_link] - Built-in support for iOS, Android, and Web (Desktop coming soon!)

✅&nbsp; [Build Flavors][flutter_flavors_link] - Multiple flavor support for development, staging, and production

✅&nbsp; [Internationalization Support][internationalization_link] - Internationalization support using synthetic code generation to streamline the development process

✅&nbsp; [Sound Null-Safety][null_safety_link] - No more null-dereference exceptions at runtime. Develop with a sound, static type system.

✅&nbsp; [Bloc][bloc_link] - Integrated bloc architecture for scalable, testable code which offers a clear separation between business logic and presentation

✅&nbsp; [Testing][testing_link] - Unit and Widget Tests with 100% line coverage (Integration Tests coming soon!)

✅&nbsp; [Logging][logging_link] - Built-in, extensible logging to capture uncaught Flutter and Dart Exceptions

✅&nbsp; [Very Good Analysis][very_good_analysis_link] - Strict Lint Rules which are used at [Very Good Ventures][very_good_ventures_link]

✅&nbsp; [Continuous Integration][github_actions_link] - Lint, format, test, and enforce code coverage using [GitHub Actions][github_actions_link]

_\* Learn more at [Flutter Starter App: Very Good Core & CLI][very_good_cli_blog_link]_

---

### `$ very_good --help`

See the complete list of commands and usage information.

```sh
🦄 A Very Good Command Line Interface

Usage: very_good <command> [arguments]

Global options:
-h, --help           Print this usage information.
    --version        Print the current version.
    --analytics      Toggle anonymous usage statistics.

          [false]    Disable anonymous usage statistics
          [true]     Enable anonymous usage statistics

Available commands:
  create   very_good create <output directory>
           Creates a new very good flutter project in the specified directory.

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
[logging_link]: https://api.flutter.dev/flutter/dart-developer/log.html
[logo]: https://raw.githubusercontent.com/VeryGoodOpenSource/very_good_cli/main/doc/assets/vgv_logo.png
[null_safety_link]: https://flutter.dev/docs/null-safety
[pub_badge]: https://img.shields.io/pub/v/very_good_cli.svg
[pub_link]: https://pub.dartlang.org/packages/very_good_cli
[testing_link]: https://flutter.dev/docs/testing
[very_good_analysis_badge]: https://img.shields.io/badge/style-very_good_analysis-B22C89.svg
[very_good_analysis_link]: https://pub.dev/packages/very_good_analysis
[very_good_cli_blog_link]: https://verygood.ventures/blog/flutter-starter-app-very-good-core-cli?utm_source=github&utm_medium=banner&utm_campaign=CLIblog
[very_good_core_link]: doc/very_good_core.md
[very_good_create]: https://raw.githubusercontent.com/VeryGoodOpenSource/very_good_cli/main/doc/assets/very_good_create.gif
[very_good_ventures_link]: https://verygood.ventures/?utm_source=github&utm_medium=banner&utm_campaign=CLI
