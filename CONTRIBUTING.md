# 🦄 Contributing to Very Good CLI

First of all, thank you for taking the time to contribute! 🎉👍 Before you do, please carefully read this guide.

## Understanding Very Good CLI

Very Good CLI allows you to generate scalable templates and use helpful commands. These functionalities have been decomposed into different repositories and packages.

Templates have their own repositories, if you want to contribute to them please refer to their repositories:

- [Dart CLI](https://github.com/VeryGoodOpenSource/very_good_dart_cli)
- [Dart Package](https://github.com/VeryGoodOpenSource/very_good_dart_package)
- [Docs Site](https://github.com/VeryGoodOpenSource/very_good_docs_site)
- [Flame Game](https://github.com/VeryGoodOpenSource/very_good_flame_game)
- [Flutter Starter App (Very Good Core)](https://github.com/VeryGoodOpenSource/very_good_core)
- [Flutter Package](https://github.com/VeryGoodOpenSource/very_good_flutter_package)
- [Flutter Plugin](https://github.com/VeryGoodOpenSource/very_good_flutter_plugin)
- [Flutter Wear OS App](https://github.com/VeryGoodOpenSource/very_good_wear_app)

If there are additional templates you'd like to see, open an issue and tell us!

💡 **Note**: Very Good CLI's completion functionality is powered by [CLI Completion](https://github.com/VeryGoodOpenSource/cli_completion) and its test command optimization is powered by [test optimizer](bricks/test_optimizer/README.md). If you want to contribute to either of those, please refer to their respective CONTRIBUTING files.

## Opening an issue

We highly recommend [creating an issue][bug_report_link] if you have found a bug, want to suggest a feature, or recommend a change. Please do not immediately open a pull request. Opening an issue first allows us to reach an agreement on a fix before you put significant effort into a pull request.

When reporting a bug, please use the built-in [Bug Report][bug_report_link] template and provide as much information as possible including detailed reproduction steps. Once one of the package maintainers has reviewed the issue and we reach an agreement on the fix, open a pull request.

## Developing for Very Good CLI

To develop for Very Good CLI you will need to become familiar with Very Good Ventures processes and conventions:

### Setting up your local development environment

1. Install a valid [Flutter SDK](https://docs.flutter.dev/get-started/install) in your local environment. Compatible Flutter SDK versions with Very Good CLI can be found [here](https://docs.flutter.dev/release/archive), ensure it has a Dart version compatible with [Very Good CLI's Dart version constraint](https://github.com/VeryGoodOpenSource/very_good_cli/blob/main/pubspec.yaml).

2. Install all Very Good CLI's dependencies:

```sh
# 📂 Get project dependencies recursively with Very Good CLI
very_good packages get -r

# Or get project dependencies manually
dart pub get && cd bricks/test_optimizer && dart pub get && cd ../../
```

3. Run all Very Good CLI tests:

```sh
# 🧪 Run Very Good CLI's unit test (from project root)
flutter test -x pull-request-only
```

If some tests do not pass out of the box, please submit an [issue](https://github.com/VeryGoodOpenSource/very_good_cli/issues/new/choose).

4. Install your own version of Very Good CLI in your local environment:

```sh
# 🚀 Activate your own local version of Very Good CLI
dart pub global activate --source path .
```

### Creating a Pull Request

Before creating a Pull Request please:

1. [Fork](https://docs.github.com/en/get-started/quickstart/contributing-to-projects) the [GitHub repository](https://github.com/VeryGoodOpenSource/very_good_cli) and create your branch from `main`:

```sh
# 🪵 Branch from `main`
git branch <branch-name>
git checkout <branch-name>
```

Where `<branch-name>` is an appropriate name describing your change.

2. Install dependencies:

```sh
# 📂 Get project dependencies recursively with Very Good CLI
very_good packages get -r

# Or get project dependencies manually
dart pub get && cd bricks/test_optimizer && dart pub get && cd ../../
```

3. Ensure you have a meaningful [semantic][conventional_commits_link] commit message.

4. Add tests! Pull Requests without 100% test coverage will **not** be merged. If you're unsure on how to do so watch our [Testing Fundamentals Course](https://www.youtube.com/watch?v=M_eZg-X789w&list=PLprI2satkVdFwpxo_bjFkCxXz5RluG8FY).

5. Ensure the existing test suite passes locally:

```sh
# 🧪 Run Very Good CLI's unit test (from project root)
flutter test -x pull-request-only
```

6. Format your code:

```sh
# 🧼 Run Dart's formatter
dart format lib test
```

7. Analyze your code:

```sh
# 🔍 Run Dart's analyzer
dart analyze --fatal-infos --fatal-warnings .
```

Some analysis issues may be fixed automatically with:

```sh
# Automatically fix analysis issues that have associated automated fixes
dart fix --apply
```

💡 **Note**: Our repositories use [Very Good Analysis](https://github.com/VeryGoodOpenSource/very_good_analysis).

8. Create the Pull Request with a meaningful description, linking to the original issue where possible.

9. Verify that all [status checks](https://github.com/VeryGoodOpenSource/very_good_cli/actions/) are passing for your Pull Request once they have been approved to run by a maintainer.

💡 **Note**: While the prerequisites above must be satisfied prior to having your pull request reviewed, the reviewer(s) may ask you to complete additional work, tests, or other changes before your pull request can be accepted.

[conventional_commits_link]: https://www.conventionalcommits.org/en/v1.0.0
[bug_report_link]: https://github.com/VeryGoodOpenSource/very_good_cli/issues/new?assignees=&labels=bug&template=bug_report.md&title=fix%3A+
[very_good_core_link]: doc/very_good_core.md
[very_good_ventures_link]: https://verygood.ventures/?utm_source=github&utm_medium=banner&utm_campaign=CLI