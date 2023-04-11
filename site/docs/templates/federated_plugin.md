---
sidebar_position: 7
---

# Flutter Federated Plugin ⚙️

This template is for a plugin that follows the [federated plugin architecture][federated_plugin_docs].

## Usage

```sh
# Create a new Flutter plugin named my_flutter_plugin (all platforms enabled)
very_good create flutter_plugin my_flutter_plugin --desc "My new Flutter plugin"
```

## Providing supported platforms

If you want your plugin to support only some platforms, pass the `platforms` option with a comma-separated list of the platforms you want to support.

If `platforms` is omitted, all platforms are enabled by default.

The values for platforms are: `android`, `ios`, `web`, `macos`, `linux`, and `windows`.

```sh
# Create a new Flutter plugin named my_flutter_plugin (supports only android, iOS and web)
very_good create flutter_plugin my_flutter_plugin --desc "My new Flutter plugin" --platforms android,ios,web
# or
very_good create flutter_plugin my_flutter_plugin --desc "My new Flutter plugin" --platforms=android,ios,web
# or
very_good create flutter_plugin my_flutter_plugin --desc "My new Flutter plugin" --platforms android --platforms ios --platforms web
```

[federated_plugin_docs]: https://docs.flutter.dev/development/packages-and-plugins/developing-packages#federated-plugins
