/// A Dart script which enables checking a package's license.
///
/// The script is intented to be used by Very Good CLI to help extracting
/// license information. The existance of this script is likely to be ephemeral.
/// It may be obsolete once [pub.dev](https://pub.dev/) exposes stable license
/// information in their official API; you may track the progress [here](https://github.com/dart-lang/pub-dev/issues/4717).
library pub_license;

import 'package:html/dom.dart' as html_dom;
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

/// The pub.dev [Uri] used to retrieve the license of a package.
Uri _pubPackageLicenseUri(String packageName) =>
    Uri.parse('https://pub.dev/packages/$packageName/license');

/// {@template pub_license_exception}
/// An exception thrown by [PubLicense].
/// {@endtemplate}
class PubLicenseException implements Exception {
  /// {@macro pub_license_exception}
  const PubLicenseException(String message)
      : message = '[pub_license] $message';

  /// The exception message.
  final String message;
}

/// {@template pub_license}
/// A Dart package that enables checking pub.dev's hosted packages license.
/// {@endtemplate}
class PubLicense {
  /// {@macro pub_license}
  PubLicense({
    @visibleForTesting http.Client? client,
  }) : _client = client ?? http.Client();

  final http.Client _client;

  /// Retrieves the license of a package.
  ///
  /// If the license is not found, an empty [Set] is returned.
  ///
  /// It may throw a [PubLicenseException] if:
  /// * The response from pub.dev is not successful.
  /// * The response body cannot be parsed.
  Future<Set<String>> getLicense(String packageName) async {
    final response = await _client.get(_pubPackageLicenseUri(packageName));

    if (response.statusCode != 200) {
      throw PubLicenseException(
        '''Failed to retrieve the license of the package, received status code: ${response.statusCode}''',
      );
    }

    late final html_dom.Document document;
    try {
      document = html_parser.parse(response.body);
    } on html_parser.ParseError catch (e) {
      throw PubLicenseException(
        'Failed to parse the response body, received error: $e',
      );
    } catch (e) {
      throw PubLicenseException(
        '''An unknown error occurred when trying to parse the response body, received error: $e''',
      );
    }

    return _scrapeLicense(document);
  }
}

Set<String> _scrapeLicense(html_dom.Document document) {
  final detailInfoBox = document.querySelector('.detail-info-box');
  if (detailInfoBox == null) {
    throw const PubLicenseException(
      '''Failed to scrape license because `.detail-info-box` was not found.''',
    );
  }

  late final String? rawLicenseText;
  for (var i = 0; i < detailInfoBox.children.length; i++) {
    final child = detailInfoBox.children[i];

    final headerText = child.text.trim().toLowerCase();
    if (headerText == 'license') {
      rawLicenseText = detailInfoBox.children[i + 1].text.trim();
      break;
    }
  }
  if (rawLicenseText == null) {
    throw const PubLicenseException(
      '''Failed to scrape license because the license header was not found.''',
    );
  }

  // FIXME(alestiago): Parse those with more than one license, see:
  // https://pub.dev/packages/just_audio/license
  final licenseText = rawLicenseText.split('(').first.trim();
  throw UnimplementedError();
}
