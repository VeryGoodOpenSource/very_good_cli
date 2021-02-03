# {{#titleCase}}{{project_name}}{{/titleCase}}

[![Very Good Ventures][logo]](very_good_ventures_link)

Developed with 💙 by [Very Good Ventures](very_good_ventures_link) 🦄

![coverage][coverage_badge]
[![style: very good analysis][very_good_analysis_badge]][very_good_analysis_link]

A Very Good Flutter Starter Project created by the [Very Good Ventures Team][very_good_ventures_link].

---

## Getting Started 🚀

This project contains 3 flavors:

- development
- staging
- production

To run the desired flavor either use the launch configuration in VSCode/Android Studio or use the following commands:

```sh
# Development
$ flutter run --flavor development --target lib/main_development.dart

# Staging
$ flutter run --flavor staging --target lib/main_staging.dart

# Production
$ flutter run --flavor production --target lib/main_production.dart
```

_\*{{#titleCase}}{{project_name}}{{/titleCase}} works on iOS, Android, and Web._

---

## What's Included? 📦

Out of the box, {{#titleCase}}{{project_name}}{{/titleCase}} includes:

✅&nbsp; [Cross Platform Support][flutter_cross_platform_link] - Built-in support for iOS, Android, and Web (Desktop coming soon!)

✅&nbsp; [Build Flavors][flutter_flavors_link] - Multiple flavor support for development, staging, and production

✅&nbsp; [Internationalization Support][internationalization_link] - Internationalization support using synthetic code generation to streamline the development process

✅&nbsp; [Sound Null-Safety][null_safety_link] - No more null-dereference exceptions at runtime. Develop with a sound, static type system.

✅&nbsp; [Bloc][bloc_link] - Integrated bloc architecture for scalable, testable code which offers a clear separation between business logic and presentation

✅&nbsp; [Testing][testing_link] - Unit and Widget Tests with 100% line coverage (Integration Tests coming soon!)

✅&nbsp; [Logging][logging_link] - Built-in, extensible logging to capture uncaught Flutter and Dart Exceptions

✅&nbsp; [Very Good Analysis][very_good_analysis_link] - Strict Lint Rules which are used at [Very Good Ventures][very_good_ventures_link]

✅&nbsp; [Continuous Integration][github_actions_link] - Lint, format, test, and enforce code coverage using [GitHub Actions][github_actions_link]

[bloc_link]: https://bloclibrary.dev
[coverage_badge]: coverage_badge.svg
[flutter_cross_platform_link]: https://flutter.dev/docs/development/tools/sdk/release-notes/supported-platforms
[flutter_flavors_link]: https://flutter.dev/docs/deployment/flavors
[github_actions_link]: https://github.com/features/actions
[internationalization_link]: https://flutter.dev/docs/development/accessibility-and-localization/internationalization
[logo]: https://raw.githubusercontent.com/VeryGoodOpenSource/very_good_analysis/main/assets/vgv_logo.png
[logging_link]: https://api.flutter.dev/flutter/dart-developer/log.html
[null_safety_link]: https://flutter.dev/docs/null-safety
[testing_link]: https://flutter.dev/docs/testing
[very_good_analysis_badge]: https://img.shields.io/badge/style-very_good_analysis-B22C89.svg
[very_good_analysis_link]: https://pub.dev/packages/very_good_analysis
[very_good_ventures_link]: https://verygood.ventures
