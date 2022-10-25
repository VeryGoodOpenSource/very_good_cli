---
sidebar_position: 6
---

# Flutter Federated Plugin ⚙️

This template is for a plugin that follows the [federated plugin architecture][federated_plugin_docs].

## Available Platforms

```sh
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
```

## Usage

```sh
# Create a new Flutter plugin named my_flutter_plugin (all platforms enabled)
very_good create my_flutter_plugin -t flutter_plugin --desc "My new Flutter plugin"

# Create a new Flutter plugin named my_flutter_plugin (some platforms disabled)
very_good create my_flutter_plugin -t flutter_plugin --desc "My new Flutter plugin" --windows false --macos false --linux false
```

[federated_plugin_docs]: https://docs.flutter.dev/development/packages-and-plugins/developing-packages#federated-plugins
