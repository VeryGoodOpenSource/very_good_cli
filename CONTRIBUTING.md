# Contributing to Very Good CLI

First off, thanks for taking the time to contribute! 🎉👍

This project is opinionated and follows patterns and practices used by the team at [Very Good Ventures][very_good_ventures_link]. **At this time, we welcome bug tickets but will not be accepting feature requests because the roadmap and scope of this project is still being defined.** In addition, we understand that [Very Good Core][very_good_core_link] is basic and lacks many features that might be desirable in a starter application but this is a conscious decision made to keep the scope of [Very Good Core][very_good_core_link] focused to just foundational items. In the future, we may support additional, more feature-rich templates but at this time we would ask that issues be reserved for bugs only.

## Creating a Bug Report

We highly recommend [creating an issue][bug_report_link] if you have found a bug rather than immediately opening a pull request. This lets us reach an agreement on a fix before you put significant effort into a pull request. Please use the built-in [Bug Report][bug_report_link] template and provide as much information as possible including detailed reproduction steps. Once one of the package maintainers has reviewed the issue and an agreement is reached regarding the fix, a pull request can be created.

## Creating a Pull Request

Before creating a pull request please:

1. Fork the repository and create your branch from `main`.
1. Install all dependencies (`flutter packages get` or `pub get`).
1. Squash your commits and ensure you have a meaningful, [semantic][conventional_commits_link] commit message.
1. Add tests! Pull Requests without 100% test coverage will not be approved.
1. Ensure the existing test suite passes locally.
1. Format your code (`dart format .`).
1. Analyze your code (`dart analyze --fatal-infos --fatal-warnings .`).
1. Create the Pull Request.
1. Verify that all status checks are passing.

While the prerequisites above must be satisfied prior to having your
pull request reviewed, the reviewer(s) may ask you to complete additional
work, tests, or other changes before your pull request can be ultimately
accepted.

[conventional_commits_link]: https://www.conventionalcommits.org/en/v1.0.0
[bug_report_link]: https://github.com/VeryGoodOpenSource/very_good_cli/issues/new?assignees=&labels=bug&template=bug_report.md&title=fix%3A+
[very_good_core_link]: doc/very_good_core.md
[very_good_ventures_link]: https://verygood.ventures/?utm_source=github&utm_medium=banner&utm_campaign=CLI
