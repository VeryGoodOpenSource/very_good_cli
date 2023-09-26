## 🦄 Contributing to the Very Good CLI SPDX License brick

First of all, thank you for taking the time to contribute! 🎉👍 Before you do, please carefully read this guide.

## Developing for Very Good CLI's SPDX License brick

To develop for Very Good CLI's SPDX License brick, you will also need to become familiar with our processes and conventions detailed [here](../../CONTRIBUTING.md).

💡 **Note**: The SPDX License brick is not published at [Brick Hub](brickhub.dev). It is not intended to be used by the general public. Instead, it has been designed to work closely with Very Good CLI's `package:pub_license` package.

### Setting up your local development environment

1. Install a valid [Dart SDK](https://dart.dev/get-dart) in your local environment. Compatible Dart SDK versions with test optimizer can be found [here](https://github.com/VeryGoodOpenSource/very_good_cli/blob/main/bricks/test_optimizer/hooks/pubspec.yaml). If you have Flutter installed you likely have a valid Dart SDK version already installed.

2. Install [Mason](https://github.com/felangel/mason/tree/master/packages/mason_cli#installation) in your local environment:

```sh
# 🎯 Activate from https://pub.dev
dart pub global activate mason_cli
```

3. Get hooks' dependencies:

```sh
# 🪝 Get hooks' dependencies (from bricks/test_optimizer/hooks)
dart pub get
```

4. Get all Mason bricks:

```sh
# 🗂 Gets all bricks in the nearest mason.yaml (from project root)
mason get
```

5. Generate a Dart SPDX License enumeration:

```sh
# ⚙️ Generate code using the spdx_license brick (from packages/pub_license)
mason make spdx_license -o lib/gen/ --on-conflict=overwrite
```

If the licenses prompt is left empty the brick will fetch the SPDX List from Git Hub. Othwerise, the user specified licenses will be used and no SPDX List will be fetched.
