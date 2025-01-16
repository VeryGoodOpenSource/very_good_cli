[<img src="https://raw.githubusercontent.com/VeryGoodOpenSource/very_good_cli/main/site/static/img/cli_icon.svg" align="left" />](https://cli.vgv.dev/)

### Avila Tek Mobile Open Source (ATMOS) CLI
<br clear="left"/>

[![ci][ci_badge]][ci_link]
[![coverage][coverage_badge]][ci_link]
[![pub package][pub_badge]][pub_link]
[![style: very good analysis][very_good_analysis_badge]][very_good_analysis_link]
[![License: MIT][license_badge]][license_link]

---

Fork from `very_good_cli` with extra features for Avila Tek ⛰️ Mobile projects.


## Special features in `atmos_cli`

To this date, `atmos_cli` is almost identical to `very_good_cli`, but with the following extra features:

The only command that is modified from the original CLI tool is `atmos create flutter_app`.

First, it uses [atmos_core](https://github.com/andrespd99/atmos_templates/tree/main/atmos_core) template, a slightly different template from [very_good_core](https://github.com/VeryGoodOpenSource/very_good_templates/tree/main/very_good_core).

Second, it has an extended setup process that does the following things:
- Sets up FVM with the newest stable Flutter version.
- Runs `mason get` and generates the base bricks used in our projects: [`avilatek_readme`](https://brickhub.dev/bricks/avilatek_readme/0.1.0), [`avila_codemagic`](https://brickhub.dev/bricks/avila_codemagic/0.1.0), [`bootstrap_go_routes`](https://brickhub.dev/bricks/bootstrap_go_routes/0.1.1) and [`avila_themes`](https://brickhub.dev/bricks/avila_themes/0.1.0).
- Prompts the user to setup Firebase in the project. **This is the neatest feature in `atmos`!**. It will setup Firebase for all flavors (development, staging and production) for iOS and Android platforms. It also sets up the firebase config files in Dart, Android and iOS. In iOS, a config folder is created with every `GoogleService-Info.plist` file and adds a Build Phase script to use the correct file for each flavor. In Dart, it creates a `firebase_config.dart` file with the correct configuration for each flavor. This is a huge time saver for developers!
- Finally, adds needed dependencies and fixes dart analysis issues.


## Documentation 📝

For official documentation, please visit https://cli.vgv.dev.

## Quick Start 🚀

### Installing 🧑‍💻

```**sh**
dart pub global activate atmos_cli
```

Or install a [specific version](https://pub.dev/packages/very_good_cli/versions) using:

```sh
dart pub global activate atmos_cli <version>
```

If you haven't already, you might need to [set up your path][path_setup_link].

When that is not possible (eg: CI environments), run `atmos` commands via:

```sh
dart pub global run atmos_cli:atmos <command> <args>
```

### Commands ✨

### [`atmos create`](https://cli.vgv.dev/docs/category/templates)

Create a very good project in seconds based on the provided template. Each template has a corresponding sub-command (e.g.,`atmos create flutter_app` will generate a Flutter starter app).


```sh
Creates a new very good project in the specified directory.

Usage: atmos create <subcommand> <project-name> [arguments]
-h, --help    Print this usage information.

Available subcommands:
  dart_cli          Generate a Very Good Dart CLI application.
  dart_package      Generate a Very Good Dart package.
  docs_site         Generate a Very Good documentation site.
  flame_game        Generate a Very Good Flame game.
  flutter_app       Generate an **Avila Tek** Flutter application.
  flutter_package   Generate a Very Good Flutter package.
  flutter_plugin    Generate a Very Good Flutter plugin.

Run "atmos help" to see global options.
```

#### Usage

```sh
# Create a new Flutter app named my_app
atmos create flutter_app my_app

# Create a new Flutter app named my_app with a custom org
atmos create flutter_app my_app --desc "My new Flutter app" --org "com.custom.org"

# Create a new Flutter app named my_app with a custom application id
atmos create flutter_app my_app --desc "My new Flutter app" --application-id "com.custom.app.id"

# Create a new Flame game named my_game
atmos create flame_game my_game --desc "My new Flame game"

# Create a new Wear OS app named my_wear_app
atmos create flutter_app my_wear_app --desc "My new Wear OS app" --template wear

# Create a new Flutter package named my_flutter_package
atmos create flutter_package my_flutter_package --desc "My new Flutter package"

# Create a new Dart package named my_dart_package
atmos create dart_package my_dart_package --desc "My new Dart package"

# Create a new Dart package named my_dart_package that is publishable
atmos create dart_package my_dart_package --desc "My new Dart package" --publishable

# Create a new Dart CLI application named my_dart_cli
atmos create dart_cli my_dart_cli --desc "My new Dart CLI package"

# Create a new Dart CLI application named my_dart_cli with a custom executable name
atmos create dart_cli my_dart_cli --desc "My new Dart CLI package" --executable-name my_executable_name

# Create a new Flutter plugin named my_flutter_plugin (all platforms enabled)
atmos create flutter_plugin my_flutter_plugin --desc "My new Flutter plugin"

# Create a new Flutter plugin named my_flutter_plugin (some platforms only)
atmos create flutter_plugin my_flutter_plugin --desc "My new Flutter plugin" --platforms android,ios,macos

# Create a new docs site named my_docs_site
atmos create docs_site my_docs_site

```

---

### [`atmos test`](https://cli.vgv.dev/docs/commands/test)

Run tests in a Dart or Flutter project.

```sh
# Run all tests
atmos test

# Run all tests and collect coverage
atmos test --coverage

# Run all tests and enforce 100% coverage
atmos test --coverage --min-coverage 100

# Run only tests in ./some/other/directory
atmos test ./some/other/directory

# Run tests recursively
atmos test --recursive

# Run tests recursively (shorthand)
atmos test -r
```

### [`atmos packages get`](https://cli.vgv.dev/docs/commands/get_pkgs)

Get packages in a Dart or Flutter project.

```sh
# Install packages in the current directory
atmos packages get

# Install packages in ./some/other/directory
atmos packages get ./some/other/directory

# Install packages recursively
atmos packages get --recursive

# Install packages recursively (shorthand)
atmos packages get -r
```

### [`atmos packages check licenses`](https://cli.vgv.dev/docs/commands/check_licenses)

Check packages' licenses in a Dart or Flutter project.

```sh
# Check licenses in the current directory
atmos packages check licenses

# Only allow the use of certain licenses
atmos packages check licenses --allowed="MIT,BSD-3-Clause,BSD-2-Clause,Apache-2.0"

# Deny the use of certain licenses
atmos packages check licenses --forbidden="unknown"

# Check licenses for certain dependencies types
atmos packages check licenses --dependency-type="direct-main,transitive"
```

### [`atmos --help`](https://cli.vgv.dev/docs/overview)
****
See the complete list of commands and usage information.

```sh
🦄 A Very Good Command-Line Interface

Usage: atmos <command> [arguments]

Global options:
-h, --help            Print this usage information.
    --version         Print the current version.
    --[no-]verbose    Noisy logging, including all shell commands executed.

Available commands:
  create     atmos create <subcommand> <project-name> [arguments]
             Creates a new very good project in the specified directory.
  packages   Command for managing packages.
  test       Run tests in a Dart or Flutter project.
  update     Update Very Good CLI.

Run "atmos help <command>" for more information about a command.
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
[very_good_ventures_link]: https://verygood.ventures
[path_setup_link]: https://dart.dev/tools/pub/cmd/pub-global#running-a-script-from-your-path
