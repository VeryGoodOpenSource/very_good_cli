---
sidebar_position: 3
---

# Syntax changes in 0.10.0 ⛷️

The syntax of the `very_good create` command changed in v0.10.0.

Previously, the `very_good_cli` would receive the template type via a `-t` flag. Now,`very_good_cli` receives sub-commands for each template. This makes it easier for us to support multiple templates and streamlines the command step for users.

Refer to the following examples to better understand the syntax changes:

#### Core template

The default template (core) is now under the sub-command flutter_app

```diff
- very_good create my_app --desc "My new Flutter app"
+ very_good create flutter_app my_app --desc "My new Flutter app"
```

#### Flame game template

```diff
- very_good create my_game -t flame_game --desc "My new Flame game"
+ very_good create flame_game my_game --desc "My new Flame game"
```

#### Flutter package

```diff
- very_good create my_flutter_package -t flutter_pkg --desc "My new Flutter package"

+ very_good create flutter_package my_flutter_package --desc "My new Flutter package"
+ very_good create flutter_pkg my_flutter_package --desc "My new Flutter package"
```

#### Dart package

```diff
- very_good create my_dart_package -t dart_pkg --desc "My new Dart package"

+ very_good create dart_package my_dart_package --desc "My new Dart package"
+ very_good create dart_pkg my_dart_package --desc "My new Dart package"
```

#### Dart CLI

```diff
- very_good create my_dart_cli -t dart_cli --desc "My new Dart CLI package"
+ very_good create dart_cli my_dart_cli --desc "My new Dart CLI package"
```

#### Flutter plugin

```diff
- very_good create my_flutter_plugin -t flutter_plugin --desc "My new Flutter plugin"
+ very_good create flutter_plugin my_flutter_plugin --desc "My new Flutter plugin"
```

We changed the way the plugin template receives supported platforms via the command line.

Previously, you would list which platforms **should not** be generated with the plugin template. Now, you should include the platforms that **should** be generated with the plugin template.

```diff
- very_good create my_flutter_plugin -t flutter_plugin --desc "My new Flutter plugin" --windows false --macos false --linux false

+ very_good create flutter_plugin my_flutter_plugin --desc "My new Flutter plugin" --platforms android,ios,web
+ very_good create flutter_plugin my_flutter_plugin --desc "My new Flutter plugin" --platforms=android,ios,web
+ very_good create flutter_plugin my_flutter_plugin --desc "My new Flutter plugin" --platforms android --platforms ios --platforms web
```

#### Docs site

```diff
- very_good create my_docs_site -t docs_site
+ very_good create docs_site my_docs_site
```
