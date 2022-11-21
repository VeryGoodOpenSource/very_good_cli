# Very Good Core 🦄

[![Very Good Ventures][logo_white]][very_good_ventures_link_dark]
[![Very Good Ventures][logo_black]][very_good_ventures_link_light]

Developed with 💙 by [Very Good Ventures][very_good_ventures_link] 🦄

A Very Good Flutter Starter Project created by the [Very Good Ventures Team][very_good_ventures_link].

## Getting Started 🚀

**❗ In order to start using Very Good Core you must have the [Flutter SDK][flutter_install_link] installed on your machine.**

### Installation 💻

For first time users, start by installing the [Very Good CLI from pub.dev][very_good_cli_link].

```sh
dart pub global activate very_good_cli
```

### Create a new Flutter Project 🆕

Then, you can use the `very_good create` command just like you would `flutter create`

![Very Good Create][very_good_create]

**💡 Upon first use, you will be prompted about anonymous usage statistics. You can adjust these settings at any time via the `--analytics` flag**

```sh
# opt into anonymous usage statistics
very_good --analytics true

# opt out of anonymous usage statistics
very_good --analytics false
```

### Running the Project ⚡

Once you have finished running `very_good create` with the project directory of your choice, you can change directories into the new project directory and install the dependencies

```sh
cd my_app
flutter packages get
```

This project contains 3 flavors:

- development
- staging
- production

Each flavor has dedicated entry point (`main_development.dart`, `main_staging.dart`, `main_production.dart`) which can be used to setup, instantiate, and/or inject flavor-specific dependencies into the application.

For example:

- In `development` we might want to output logs to the console but in `staging` and `production` we might want to upload logs to [sentry.io][sentry_link] or [firebase analytics][firebase_analytics_link].
- We might want to configure an `ApiClient` or `DatabaseClient` to point to a different endpoint for each flavor.

To run the desired flavor either use the launch configuration in VSCode/Android Studio or use the following commands:

```sh
# Development
flutter run --flavor development --target lib/main_development.dart

# Staging
flutter run --flavor staging --target lib/main_staging.dart

# Production
flutter run --flavor production --target lib/main_production.dart
```

_\*Very Good Core works on iOS, Android, Web, and Windows._

Now your app is running 🎉

---

## Why Very Good Core? 🤔

We liked the simplicity and developer experience of running `flutter create` when getting started on a new project. We wanted to provide a similar experience with `very_good create` which built on top of `flutter create` and includes the core standards and best practices we use at [Very Good Ventures][very_good_ventures_link].

We built the CLI to be extensible so it could potentially support multiple commands and templates in the future.

## Project Structure and Architecture 🏗️

Although Very Good Core is fairly basic in terms of functionality, the architecture and project structure is intended to scale from a simple hobby project to a large production ready application.

A folder-by-feature project structure is used to maintain a modular project structure which helps the project scale as the number of features and/or developers increase. In Very Good Core there is only a single feature (`counter`) to start but that will quickly change as you build out your project. Each feature usually consists of a `view` and a `cubit` (or `bloc`). The view is responsible for holding the UI (`Widgets`) which the user sees and interacts with and the `cubit`/`bloc` is responsible for containing the business logic needed to manage the state of the feature. For more details [read our best practices for building scalable apps][scalable_best_practices_blog_link].

---

## Testing 🧪

Very Good Core ships with 100% code coverage. To learn more about why we believe 100% code coverage is important and other testing best practices [read our guide to Flutter testing][very_good_testing_blog_link].

### Running Tests 🧑‍🔬

To run all unit and widget tests use the following command:

```sh
flutter test --coverage --test-randomize-ordering-seed random
```

To view the generated coverage report you can use [lcov](https://github.com/linux-test-project/lcov).

```sh
# Generate Coverage Report
genhtml coverage/lcov.info -o coverage/

# Open Coverage Report
open coverage/index.html
```

---

## Working with Translations 🌐

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

3. Use the new string

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

---

## Continuous Integration 🤖

Very Good Core comes with a built-in [GitHub Actions workflow][github_actions_link] but you can also add your preferred CI/CD solution.

Out of the box, on each pull request and push, the CI `formats`, `lints`, and `tests` the code. This ensures the code remains consistent and behaves correctly as you add functionality or make changes. The project uses [Very Good Analysis][very_good_analysis_link] for a strict set of analysis options used by our team. Code coverage is enforced using the [Very Good Coverage GitHub Action][very_good_coverage_link].

---

## Updating App Icons 📱

When you create a new project, it has a default launcher icon. To customize this icon, you can do it by using the following steps for each platform.

### Android

1. Review the [Material Design product icons][material_design_product_icons] guidelines for icon design.

2. In the `[project]/android/app/src/main/res/` directory, place your icon files in folders named using [configuration qualifiers][android_configuration_qualifiers]. The default `mipmap-` folders demonstrate the correct naming convention.

3. In `AndroidManifest.xml`, update the [`application`][android_application_element] tag’s `android:icon` attribute to reference icons from the previous step (for example, `<application android:icon="@mipmap/ic_launcher" ...`).

4. To verify that the icon has been replaced, run your app and inspect the app icon in the Launcher.

### iOS

1. Review the [iOS App Icon guidelines][ios_app_icon_guidelines].

2. In the Xcode project navigator, select `Assets.xcassets` in the `Runner` folder. Update the placeholder icons with your own app icons.

3. Verify the icon has been replaced by running your app using `flutter run`.

[android_application_element]: https://developer.android.com/guide/topics/manifest/application-element
[android_configuration_qualifiers]: https://developer.android.com/guide/topics/resources/providing-resources#AlternativeResources
[firebase_analytics_link]: https://firebase.google.com/products/analytics
[flutter_install_link]: https://flutter.dev/docs/get-started/install
[flutter_localizations_link]: https://api.flutter.dev/flutter/flutter_localizations/flutter_localizations-library.html
[internationalization_link]: https://flutter.dev/docs/development/accessibility-and-localization/internationalization
[github_actions_link]: https://docs.github.com/en/actions/learn-github-actions
[ios_app_icon_guidelines]: https://developer.apple.com/design/human-interface-guidelines/ios/icons-and-images/app-icon/
[logo_black]: https://raw.githubusercontent.com/VGVentures/very_good_brand/main/styles/README/vgv_logo_black.png#gh-light-mode-only
[logo_white]: https://raw.githubusercontent.com/VGVentures/very_good_brand/main/styles/README/vgv_logo_white.png#gh-dark-mode-only
[material_design_product_icons]: https://material.io/design/iconography/
[scalable_best_practices_blog_link]: https://verygood.ventures/blog/scalable-best-practices?utm_source=github&utm_medium=banner&utm_campaign=CLI
[sentry_link]: https://sentry.io
[very_good_analysis_link]: https://pub.dev/packages/very_good_analysis
[very_good_core_link]: very_good_core.md
[very_good_coverage_link]: https://github.com/marketplace/actions/very-good-coverage
[very_good_cli_link]: https://pub.dev/packages/very_good_cli
[very_good_create]: https://raw.githubusercontent.com/VeryGoodOpenSource/very_good_cli/main/doc/assets/very_good_create.png
[very_good_testing_blog_link]: https://verygood.ventures/blog/guide-to-flutter-testing?utm_source=github&utm_medium=banner&utm_campaign=CLI
[very_good_ventures_link]: https://verygood.ventures/?utm_source=github&utm_medium=banner&utm_campaign=core
[very_good_ventures_link_dark]: https://verygood.ventures/?utm_source=github&utm_medium=banner&utm_campaign=core#gh-dark-mode-only
[very_good_ventures_link_light]: https://verygood.ventures/?utm_source=github&utm_medium=banner&utm_campaign=core#gh-light-mode-only
