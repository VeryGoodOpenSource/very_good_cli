---
sidebar_position: 3
---

# Syntax changes in 0.10.0 ⛷️

The syntax of the `very_good create` command changed in v0.10.0.

Previously, the `very_good_cli` would receive the template type via a `-t` flag. Now,`very_good_cli` receives sub-commands for each template. This makes it easier for us to support multiple templates and streamlines the command step for users.

Comparisons between the previous and the current syntax:

#### Core template

The default template (core) is now under the sub-command flutter_app

```sh
# Before 0.10.0
very_good create my_app --desc "My new Flutter app"

# After 0.10.0
very_good create flutter_app my_app --desc "My new Flutter app"
```

#### Flame game template

```sh
# Before 0.10.0
very_good create my_game -t flame_game --desc "My new Flame game"

# After 0.10.0
very_good create flame_game my_game --desc "My new Flame game"
```

#### Flutter package

```sh
# Before 0.10.0
very_good create my_flutter_package -t flutter_pkg --desc "My new Flutter package"

# After 0.10.0
very_good create flutter_package my_flutter_package --desc "My new Flutter package"
```

#### Dart package

```sh
# Before 0.10.0
very_good create my_dart_package -t dart_pkg --desc "My new Dart package"

# After 0.10.0
very_good create dart_package my_dart_package --desc "My new Dart package"
# or
very_good create dart_pkg my_dart_package --desc "My new Dart package"
```

#### Dart CLI

```sh
# Before 0.10.0`
very_good create my_dart_cli -t dart_cli --desc "My new Dart CLI package"

# After 0.10.0
very_good create dart_cli my_dart_cli --desc "My new Dart CLI package"
```

#### Flutter plugin

```sh
# Before 0.10.0
very_good create my_flutter_plugin -t flutter_plugin --desc "My new Flutter plugin"

# After 0.10.0
very_good create flutter_plugin my_flutter_plugin --desc "My new Flutter plugin"
```

Flutter plugin changed the way it receives supported platforms.
Before, it was a series of options list which platforms **should not** be considered,
now it is a multi-option with the platforms that **should** be considered.

```sh
# Before 0.10.0
very_good create my_flutter_plugin -t flutter_plugin --desc "My new Flutter plugin" --windows false --macos false --linux false

# After 0.10.0
very_good create flutter_plugin my_flutter_plugin --desc "My new Flutter plugin" --platforms android,ios,web
# or
very_good create flutter_plugin my_flutter_plugin --desc "My new Flutter plugin" --platforms=android,ios,web
# or
very_good create flutter_plugin my_flutter_plugin --desc "My new Flutter plugin" --platforms android --platforms ios --platforms web
```

#### Docs site

```sh
# Before 0.10.0
very_good create my_docs_site -t docs_site

# After 0.10.0
very_good create docs_site my_docs_site
```
