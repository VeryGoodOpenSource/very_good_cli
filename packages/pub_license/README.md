# Pub License

Developed with 💙 by [Very Good Ventures][very_good_ventures_link] 🦄

---

A Dart package which enables checking a package's license.

💡 **Note**: Currently the check is exclusively done against hosted packages in [pub.dev](https://pub.dev/).

The package is intented to be used by Very Good CLI to help extracting license information. The implementation of this package is likely to be ephemeral. It may change once [pub.dev](https://pub.dev/) exposes license information in their official API; you may track the progress [here](https://github.com/dart-lang/pub-dev/issues/4717).

## Usage

```dart
import 'package:pub_licens/pub_license.dart'

Future<void> main() async {
  // Create an instance of PubLicense
  final pubLicense = PubLicense();

  // Check the license of the latest version of very_good_cli
  final license = await pubLicense.getLicense('very_good_cli');
  print(license);
}
```

[very_good_ventures_link]: https://verygood.ventures
