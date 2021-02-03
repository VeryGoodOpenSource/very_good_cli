# {{#titleCase}}{{project_name}}{{/titleCase}}

[![Very Good Ventures][logo]](very_good_ventures_link)

Developed with 💙 by [Very Good Ventures](very_good_ventures_link) 🦄

![coverage][coverage_badge]
[![style: very good analysis][very_good_analysis_badge]][very_good_analysis_link]

A Very Good Flutter Project created by the [Very Good Ventures Team](very_good_ventures_link).

---

## Getting Started

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

[coverage_badge]: coverage_badge.svg
[logo]: https://raw.githubusercontent.com/VeryGoodOpenSource/very_good_analysis/main/assets/vgv_logo.png
[very_good_analysis_badge]: https://img.shields.io/badge/style-very_good_analysis-B22C89.svg
[very_good_analysis_link]: https://pub.dev/packages/very_good_analysis
[very_good_ventures_link]: https://verygood.ventures
