## 🦄 Welcome

Hello! If you’re interested in contributing to Very Good CLI's test optimizer you’re reading the right document. First of all, thank you for showing interest in contributing! Before you do so it is important to carefully read this [other file](../../CONTRIBUTING.md) and [this file](CONTRIBUTING.md) before contributing.

## Developing for Very Good CLI's test optimizer

To develop for Very Good CLI's test optimizer, you will need to become familiar with our processes and conventions detailed [here](../../CONTRIBUTING.md).

> **Note**: The test optimizer brick is not published at [Brick Hub](brickhub.dev). It is not intended to be used by the general public. Instead, it has been designed to work closely with Very Good CLI's `test` command.

## Setting up your local development environment

1. Install a valid [Dart SDK](https://dart.dev/get-dart) in your local environment. Compatible Dart SDK versions with test optimizer can be found [here](https://github.com/VeryGoodOpenSource/very_good_cli/blob/cdff842672a257a7ecb7bddee1fcee7e8f92df6a/bricks/test_optimizer/hooks/pubspec.yaml#L5). If you have Flutter installed you likely have a valid Dart SDK version already installed.

2. Install [Mason](https://github.com/felangel/mason/tree/master/packages/mason_cli#installation) in your local environment:

```sh
# 🎯 Activate from https://pub.dev
dart pub global activate mason_cli
```

3. Get all project dependencies:

```sh
# 📂 Get project dependencies recursively with Very Good CLI
very_good packages get -r

# Or get project dependencies manually
dart pub get && cd bricks/test_optimizer && dart pub get && cd ../../
```

4. Run all test optimizer tests:

```sh
# 🪝 Run test optimizer hook's unit test
cd bricks/test_optimizer/hooks && dart test && cd ../../../

# 💻 Run `very_good test` end to end tests
dart test test/src/commands/test/e2e/async_main_test.dart --run-skipped -t e2e &&
dart test test/src/commands/test/e2e/no_project_test.dart --run-skipped -t e2e
```

If not all test passed out of the box please submit an [issue](https://github.com/VeryGoodOpenSource/very_good_cli/issues/new/choose) so it can get fixed.

5. Install your own version of test optimizer in your local environment:

```sh
# 🧱 Adds test optimizer brick from path
mason add --global test_optimizer --path bricks/test_optimizer
```

Then, you can start using it:

```sh
# 🚀 Try test optimizer locally
mason make test_optimizer
```

6. If you want to run your test optimizer with Very Good CLI (like for example `very_good test`) locally then:

```sh
# 📦 Bundle test optimizer
tool/generate_test_optimizer_bundle.sh

# 💻 Install your own version of Very Good CLI in your local environment
dart pub global activate --source path .
```

> **Note**: After changing the test optimizer brick, make sure to always generate a new test optimizer bundle and commit this as part of your pull request.
