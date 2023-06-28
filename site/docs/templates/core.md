---
sidebar_position: 1
---

# Flutter Starter App (Core) 🍎

This template is a Flutter starter application with VGV-opinionated best practices. It is the default template for the `very_good create flutter_app` command.

![Very Good Core][core_devices]

## Why Very Good Core?

We liked the [starter app][counter_app_link] provided by the `flutter create` command, but found ourselves making adjustments every time we started a project. To help streamline the process, we decided to create our own starter template with the core standards and best practices we use at [Very Good Ventures][vgv]. Similar to the Flutter Starter app, Very Good Core contains a basic counter app with some additional features for a more robust app foundation.

## App Features ✨

- **Multi-Platform Support** - Support for iOS, Android, Web, and Windows (macOS and Linux coming soon!)

- **Build Flavors** - Multiple flavor support for development, staging, and production

- **Internationalization Support** - Internationalization support using synthetic code generation to streamline the development process

- **Sound Null Safety** - No more null-dereference exceptions at runtime. Develop with a sound, static type system.

- **[Bloc][bloc_pub]** - Layered architecture with `bloc` for scalable, testable code which offers a clear separation between business logic and presentation

- **Testing** - Unit and widget tests with 100% line coverage (integration tests coming soon!)

- **Logging** - Extensible logging to capture uncaught Dart and Flutter exceptions

- **[Very Good Analysis][vga]** - Lint rules for Dart and Flutter used internally at Very Good Ventures

- **Continuous Integration** - Lint, format, test, and enforce code coverage using GitHub Actions

## Getting Started 🚀

:::info
In order to start using Very Good Core you must have the [Flutter SDK][flutter_install_link] installed on your machine.
:::

### Installation 💻

For first time users, start by installing the [Very Good CLI from pub.dev][cli_pub].

```sh
dart pub global activate very_good_cli
```

### Create a new Flutter Project 🆕

Then, you can use the `very_good create flutter_app` command just like you would `flutter create`. If desired, can specify a custom org name at time of generation with the `--org` flag.

```sh
# Create a new Flutter app named my_app
very_good create flutter_app my_app --desc "My new Flutter app"

# Create a new Flutter app named my_app with a custom org
very_good create flutter_app my_app --desc "My new Flutter app" --org "com.custom.org"
```

### Running the Project ⚡

Once you have finished running `very_good create` with the project directory of your choice, you can change directories into the new project directory and install the dependencies

```sh
cd my_app
flutter packages get
```

This project contains 3 flavors:

- Development
- Staging
- Production

Each flavor has dedicated entry point (`main_development.dart`, `main_staging.dart`, `main_production.dart`) which can be used to setup, instantiate, and inject flavor-specific dependencies into the application.

For example:

- In `development` we might want to output logs to the console but in `staging` and `production` we might want to upload logs to [sentry.io][sentry_link] or [firebase analytics][firebase_analytics_link].
- We might want to configure an `ApiClient` or `DatabaseClient` to point to a different endpoint for each flavor.

To run the desired flavor either use the launch configuration in VSCode or Android Studio, or use the following commands:

```sh
# Development
flutter run --flavor development --target lib/main_development.dart

# Staging
flutter run --flavor staging --target lib/main_staging.dart

# Production
flutter run --flavor production --target lib/main_production.dart
```

:::caution
Flavors are only supported on iOS, Android, Web, and Windows.
:::

Now your app is running 🎉

## Project Structure and Architecture 🏗️

Although Very Good Core is fairly basic in terms of functionality, the architecture and project structure is intended to scale from a simple hobby project to a large production ready application. A folder-by-feature project structure is used to maintain a modular project structure which helps the project scale as the number of features and/or developers increase.

In Very Good Core, there is only a single feature (`counter`) to start but that will quickly change as you build out your project. Each feature usually consists of a `view` and a `cubit` (or `bloc`). The view is responsible for holding the UI (`Widgets`) which the user sees and interacts with and the `cubit`/`bloc` is responsible for containing the business logic needed to manage the state of the feature.

For more details, [read our best practices for building scalable apps][blog_scalable].

## Testing 🧪

Very Good Core ships with 100% code coverage.
:::note
To learn more about why we believe 100% code coverage is important and other testing best practices, [read our guide to Flutter testing][blog_testing].
:::

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

## Working with Translations 🌐

This project relies on [flutter_localizations][flutter_localizations] and follows the [official internationalization guide for Flutter][flutter_internationalization].

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

## Continuous Integration 🤖

Very Good Core comes with a built-in [GitHub Actions workflow][github_actions] but you can also add your preferred CI/CD solution.

Out of the box, on each pull request and push, the CI `formats`, `lints`, and `tests` the code. This ensures the code remains consistent and behaves correctly as you add functionality or make changes. The project uses [Very Good Analysis][vga] for a strict set of analysis options used by our team. Code coverage is enforced using the [Very Good Coverage GitHub Action][very_good_coverage].

## Updating App Icons 📱

When you create a new project, it has a default launcher icon. To customize this icon, you can do it by using the following steps for each platform.

### Android

1. Review the [Material Design product icons][material_design_product_icons] guidelines for icon design.

2. In the `[project]/android/app/src/main/res/` directory, place your icon files in folders named using [configuration qualifiers][android_configuration_qualifiers]. The default `mipmap-` folders demonstrate the correct naming convention.

3. In `AndroidManifest.xml`, update the [`application`][android_application_element] tag’s `android:icon` attribute to reference icons from the previous step (for example, `<application android:icon="@mipmap/ic_launcher" ...`).

4. To verify that the icon has been replaced, run your app and inspect the app icon in the Launcher.

### iOS

1. Review the [iOS app icons guidelines][ios_app_icon_guidelines].

2. In the Xcode project navigator, select `Assets.xcassets` in the `Runner` folder. Update the placeholder icons with your own app icons.

3. Verify the icon has been replaced by running your app using `flutter run`.

[android_application_element]: https://developer.android.com/guide/topics/manifest/application-element
[android_configuration_qualifiers]: https://developer.android.com/guide/topics/resources/providing-resources#AlternativeResources
[bloc_pub]: https://pub.dev/packages/bloc
[blog_scalable]: https://verygood.ventures/blog/scalable-best-practices
[blog_testing]: https://verygood.ventures/blog/guide-to-flutter-testing
[cli_pub]: https://pub.dev/packages/very_good_cli
[core_devices]: /img/core_devices.png
[counter_app_link]: https://github.com/flutter/flutter/blob/master/packages/flutter_tools/templates/app/lib/main.dart.tmpl
[firebase_analytics_link]: https://firebase.google.com/products/analytics
[flutter_install_link]: https://docs.flutter.dev/get-started/install
[flutter_internationalization]: https://docs.flutter.dev/development/accessibility-and-localization/internationalization
[flutter_localizations]: https://api.flutter.dev/flutter/flutter_localizations/flutter_localizations-library.html
[github_actions]: https://docs.github.com/en/actions/learn-github-actions
[ios_app_icon_guidelines]: https://developer.apple.com/design/human-interface-guidelines/foundations/app-icons
[material_design_product_icons]: https://material.io/design/iconography/
[sentry_link]: https://sentry.io
[very_good_coverage]: https://github.com/marketplace/actions/very-good-coverage
[vga]: https://github.com/VeryGoodOpenSource/very_good_analysis
[vgv]: https://verygood.ventures
