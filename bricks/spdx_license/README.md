# SPDX License

A generator that provides a Dart SPDX License enumeration used by the [`package:pub_license`](../../packages/pub_license/README.md).

This package should always match [PANA's](https://github.com/dart-lang/pana) license list; currently the list is deduced from the [SPDX Git Hub repository](https://github.com/dart-lang/pana/blob/master/third_party/spdx/update_licenses.dart).

💡 **Note**: The SPDX License brick is not published at [Brick Hub](brickhub.dev). It is not intended to be used by the general public. Instead, it has been designed to work closely with Very Good CLI's `package:pub_license` package.

## Usage

1. Install a valid [Dart SDK](https://dart.dev/get-dart) in your local environment. Compatible Dart SDK versions with test optimizer can be found [here](https://github.com/VeryGoodOpenSource/very_good_cli/blob/main/pubspec.yaml). If you have Flutter installed, you likely have a valid Dart SDK version already installed.

2. Install Mason's CLI:

```sh
# 🎯 Activate from https://pub.dev
dart pub global activate mason_cli
```

3. Get all Mason bricks:

```sh
# 🗂 Gets all bricks in the nearest mason.yaml (from project root)
mason get
```

4. Generate a Dart SPDX License enumeration:

```sh
# ⚙️ Generate code using the spdx_license brick (from packages/pub_license)
mason make spdx_license -o lib/gen/ --on-conflict=overwrite
```

If the licenses prompt is left empty the brick will fetch the SPDX List from Git Hub. Othwerise, the user specified licenses will be used and no SPDX List will be fetched.
