## 🦄 Contributing to the Very Good CLI test optimizer 

First of all, thank you for taking the time to contribute! 🎉👍 Before you do, please carefully read this guide.

## Developing for Very Good CLI's test optimizer

To develop for Very Good CLI's test optimizer, you will also need to become familiar with our processes and conventions detailed [here](../../CONTRIBUTING.md).

💡 **Note**: The test optimizer brick is not published at [Brick Hub](brickhub.dev). It is not intended to be used by the general public. Instead, it has been designed to work closely with Very Good CLI's `test` command.

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

4. Run all test optimizer tests:

```sh
# 🪝 Run test optimizer hooks' unit test (from bricks/test_optimizer/hooks)
dart test

# 💻 Run `very_good test` end to end tests (from e2e/)
dart test test/src/commands/test/async_main_test.dart &&
dart test test/src/commands/test/no_project_test.dart &&
dart test test/src/commands/test/spaced_golden_file_name.dart
```

If not all test passed out of the box please submit an [issue](https://github.com/VeryGoodOpenSource/very_good_cli/issues/new/choose) so it can get fixed.

5. Install your own version of test optimizer in your local environment:

```sh
# 🧱 Adds test optimizer brick from path (from bricks/test_optimizer)
mason add --global test_optimizer --path .
```

Then, you can start using it:

```sh
# 🚀 Try test optimizer locally
mason make test_optimizer
```

6. If you want to run your test optimizer with Very Good CLI (like for example `very_good test`) locally:

```sh
# 📦 Bundle test optimizer (from root)
tool/generate_test_optimizer_bundle.sh

# 💻 Install your own version of Very Good CLI in your local environment (from root)
dart pub global activate --source path .
```

💡 **Note**: After changing the test optimizer brick, make sure to always generate a new test optimizer bundle and commit this as part of your pull request.
