# Very Good Core

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

_\*Very Good Core works on iOS, Android, and Web._

---

## What's Included? 📦

Out of the box, Very Good Core includes:

✅&nbsp; [Cross Platform Support][flutter_cross_platform_link] - Built-in support for iOS, Android, and Web (Desktop coming soon!)

✅&nbsp; [Build Flavors][flutter_flavors_link] - Multiple flavor support for development, staging, and production

✅&nbsp; [Internationalization Support][internationalization_link] - Internationalization support using synthetic code generation to streamline the development process

✅&nbsp; [Sound Null-Safety][null_safety_link] - No more null-dereference exceptions at runtime. Develop with a sound, static type system.

✅&nbsp; [Bloc][bloc_link] - Integrated bloc architecture for scalable, testable code which offers a clear separation between business logic and presentation

✅&nbsp; [Testing][testing_link] - Unit and Widget Tests with 100% line coverage (Integration Tests coming soon!)

✅&nbsp; [Logging][logging_link] - Built-in, extensible logging to capture uncaught Flutter and Dart Exceptions

✅&nbsp; [Very Good Analysis][very_good_analysis_link] - Strict Lint Rules which are used at [Very Good Ventures][very_good_ventures_link]

✅&nbsp; [Continuous Integration][github_actions_link] - Lint, format, test, and enforce code coverage using [GitHub Actions][github_actions_link]

---

## Working with Translations

This project relies on [flutter_localizations][flutter_localizations_link] and follows the [official internationalization guide for Flutter][internationalization_link].

### Adding Strings

1. To add a new localizable string, open the `app_en.arb` file at `lib/l10n/arb/app_en.arb`.

```arb
{
    "@@locale": "en",
    "counterAppBarTitle": "Counter",
    "@counterAppBarTitle": {
        "description": "Text shown in the AppBar of the Counter Page"
    }
}
```

2. Then add a new key/value and description

```arb
{
    "@@locale": "en",
    "counterAppBarTitle": "Counter",
    "@counterAppBarTitle": {
        "description": "Text shown in the AppBar of the Counter Page"
    },
    "helloWorld": "Hello World",
    "@helloWorld": {
        "description": "Hello World Text"
    }
}
```

3. Use the new string!

```dart
import 'package:very_good_core/l10n/l10n.dart';

@override
Widget build(BuildContext context) {
  final l10n = context.l10n;
  return Text(l10n.helloWorld);
}
```

### Adding Supported Locales

Update the `CFBundleLocalizations` array in the `Info.plist` at `ios/Runner/Info.plist` to include the new locale.

```xml
    ...

    <key>CFBundleLocalizations</key>
	<array>
		<string>en</string>
		<string>es</string>
	</array>

    ...
```

### Adding Translations

1. For each supported locale, add a new ARB file in `lib/l10n/arb`.

```
├── l10n
│   ├── arb
│   │   ├── app_en.arb
│   │   └── app_es.arb
```

2. Add the translated strings to each `.arb` file:

`app_en.arb`

```arb
{
    "@@locale": "en",
    "counterAppBarTitle": "Counter",
    "@counterAppBarTitle": {
        "description": "Text shown in the AppBar of the Counter Page"
    }
}
```

`app_es.arb`

```arb
{
    "@@locale": "es",
    "counterAppBarTitle": "Contador",
    "@counterAppBarTitle": {
        "description": "Texto mostrado en la AppBar de la página del contador"
    }
}
```

[bloc_link]: https://bloclibrary.dev
[coverage_badge]: coverage_badge.svg
[flutter_cross_platform_link]: https://flutter.dev/docs/development/tools/sdk/release-notes/supported-platforms
[flutter_flavors_link]: https://flutter.dev/docs/deployment/flavors
[flutter_localizations_link]: https://api.flutter.dev/flutter/flutter_localizations/flutter_localizations-library.html
[github_actions_link]: https://github.com/features/actions
[internationalization_link]: https://flutter.dev/docs/development/accessibility-and-localization/internationalization
[logo]: https://raw.githubusercontent.com/VeryGoodOpenSource/very_good_analysis/main/assets/vgv_logo.png
[logging_link]: https://api.flutter.dev/flutter/dart-developer/log.html
[null_safety_link]: https://flutter.dev/docs/null-safety
[testing_link]: https://flutter.dev/docs/testing
[very_good_analysis_badge]: https://img.shields.io/badge/style-very_good_analysis-B22C89.svg
[very_good_analysis_link]: https://pub.dev/packages/very_good_analysis
[very_good_ventures_link]: https://verygood.ventures
