/// A small script used to generate the fixture for the pub_license test.
///
/// Fixtures are simply a temporary snapshot of an HTML response from pub.dev.
/// The generated fixtures allows testing pub_license scraping logic without
/// making a request to pub.dev every time the test is run.
///
/// To run this script, use the following command:
/// ```bash
/// dart test/src/pub_license/fixtures/generate_pub_license_fixture.dart
/// ```
///
///  Or simply use the "Run" CodeLens from VSCode's Dart extension.
library generate_pub_license_fixture;

// ignore_for_file: avoid_print

import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

/// [Uri] used to test the case where a package has a single license.
final _singleLicenseUri = Uri.parse(
  'https://pub.dev/packages/very_good_cli/license',
);

/// [Uri] used to test the case where a package has multiple licenses.
final _multipleLicenseUri = Uri.parse(
  'https://pub.dev/packages/just_audio/license',
);

/// [Uri] used to test the case where a package has no license.
final _noLicenseUri = Uri.parse(
  'https://pub.dev/packages/music_control_notification/license',
);

Future<void> main() async {
  final fixtureUris = <String, Uri>{
    'singleLicense': _singleLicenseUri,
    'multipleLicense': _multipleLicenseUri,
    'noLicense': _noLicenseUri,
  };

  final httpClient = http.Client();

  for (final entry in fixtureUris.entries) {
    final name = entry.key;
    final uri = entry.value;

    final response = await httpClient.get(uri);

    if (response.statusCode != 200) {
      print(
        '''Failed to generate a fixture for $name, received status code: ${response.statusCode}''',
      );
      continue;
    }

    final fixturePath = path.joinAll([
      Directory.current.path,
      'test',
      'src',
      'pub_license',
      'fixtures',
      '$name.html',
    ]);
    File(fixturePath)
      ..createSync(recursive: true)
      ..writeAsStringSync(response.body);

    print('Fixture generated at $fixturePath');
  }
}
