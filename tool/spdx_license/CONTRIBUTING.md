## 🦄 Contributing to the Very Good CLI SPDX License brick

First of all, thank you for taking the time to contribute! 🎉👍 Before you do, please carefully read this guide.

## Developing for Very Good CLI's SPDX License brick

To develop for Very Good CLI's SPDX License brick, you will also need to become familiar with our processes and conventions detailed [here](../../CONTRIBUTING.md).

💡 **Note**: The SPDX License brick is not published at [Brick Hub](brickhub.dev). It is not intended to be used by the general public. Instead, it has been designed to work closely with Very Good CLI.

### Setting up your local development environment

1. Install a valid [Dart SDK](https://dart.dev/get-dart) in your local environment. Compatible Dart SDK versions with the SPDX license brick can be found [here](https://github.com/VeryGoodOpenSource/very_good_cli/blob/main/tool/spdx_license/hooks/pubspec.yaml). If you have Flutter installed you likely have a valid Dart SDK version already installed.

2. Install [Mason](https://github.com/felangel/mason/tree/master/packages/mason_cli#installation) in your local environment:

```sh
# 🎯 Activate from https://pub.dev
dart pub global activate mason_cli
```

3. Get hooks' dependencies:

```sh
# 🪝 Get hooks' dependencies (from tool/spdx_license/hooks)
dart pub get
```

4. Run all hook's tests:

```sh
# 🧪 Test all hook's (from tool/spdx_license/hooks)
dart test
```

If some tests do not pass out of the box, please submit an [issue](https://github.com/VeryGoodOpenSource/very_good_cli/issues/new/choose).

4. Get all Mason bricks:

```sh
# 🗂 Gets all bricks in the nearest mason.yaml (from project root)
mason get
```

5. Generate a Dart SPDX License enumeration:

```sh
# ⚙️ Generate code using the spdx_license brick (from within project)
mason make spdx_license -o lib/src/pub_license/ --on-conflict=overwrite
```

If the licenses prompt is left empty the brick will fetch the [SPDX list](https://github.com/spdx/license-list-data/tree/main/json/details). Otherwise, the user specified licenses will be used and no SPDX List will be fetched.
