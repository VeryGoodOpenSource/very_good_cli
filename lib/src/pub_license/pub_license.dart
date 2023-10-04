/// Enables checking a package's license from pub.dev.
///
/// This library is intented to be used by Very Good CLI to help extracting
/// license information. The existance of this library is likely to be
/// ephemeral. It may be obsolete once [pub.dev](https://pub.dev/) exposes
/// stable license information in their official API; you may track the
/// progress [here](https://github.com/dart-lang/pub-dev/issues/4717).
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

/// The function signature for parsing HTML documents.
@visibleForTesting
typedef HtmlDocumentParse = html_dom.Document Function(
  dynamic input, {
  String? encoding,
  bool generateSpans,
  String? sourceUrl,
});

/// {@template pub_license}
/// Enables checking pub.dev's hosted packages license.
/// {@endtemplate}
class PubLicense {
  /// {@macro pub_license}
  PubLicense({
    @visibleForTesting http.Client? client,
    @visibleForTesting HtmlDocumentParse? parse,
  })  : _client = client ?? http.Client(),
        _parse = parse ?? html_parser.parse;

  final http.Client _client;

  final html_dom.Document Function(
    dynamic input, {
    String? encoding,
    bool generateSpans,
    String? sourceUrl,
  }) _parse;

  /// Retrieves the license of a package.
  ///
  /// Some packages may have multiple licenses, hence a [Set] is returned.
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
      document = _parse(response.body);
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

/// Scrapes the license from the pub.dev's package license page.
///
/// The expected HTML structure is:
/// ```html
/// <aside class="detail-info-box">
///   <h3> ... </h3>
///   <p> ... </p>
///   <h3 class="title">License</h3>
///   <p>
///   <img/>
///   MIT (<a href="/packages/very_good_cli/license">LICENSE</a>)
///   </p>
/// </aside>
/// ```
///
/// It may throw a [PubLicenseException] if:
/// * The detail info box is not found.
/// * The license header is not found.
Set<String> _scrapeLicense(html_dom.Document document) {
  final detailInfoBox = document.querySelector('.detail-info-box');
  if (detailInfoBox == null) {
    throw const PubLicenseException(
      '''Failed to scrape license because `.detail-info-box` was not found.''',
    );
  }

  String? rawLicenseText;
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

  final licenseText = rawLicenseText.split('(').first.trim();
  return licenseText.split(',').map((e) => e.trim()).toSet();
}
