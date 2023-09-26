import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';
import 'package:html/dom.dart' as html_dom;
import 'package:html/parser.dart' as html_parser;
import 'package:pub_license/src/models/spdx_license.gen.dart';

/// The PUB Uri used to retrieve the license of a package.
///
/// **Note**: Currently the license is scraped out. This approach might change
/// once the pub.dev API includes the verison of the package in the Uri. See:
/// https://github.com/dart-lang/pub-dev/issues/4717
String _pubPackageLicenseUri(String packageName) =>
    'https://pub.dev/packages/$packageName/license';

/// {@template pub_license_exception}
/// An exception thrown by the Pub License package.
/// {@endtemplate}
class PubLicenseException implements Exception {
  /// {@macro pub_license_exception}
  const PubLicenseException(String message)
      : message = '[pub_license] $message';

  /// The exception message.
  final String message;
}

/// {@template pub_license}
/// A Dart package which enables checking a package's license.
/// {@endtemplate}
class PubLicense {
  /// {@macro pub_license}
  PubLicense({
    @visibleForTesting http.Client? client,
  }) : _client = client ?? http.Client();

  final http.Client _client;

  /// Retrieves the license of a package.
  ///
  /// If the license is not found, a [SpdxLicense.$unknown] is returned.
  ///
  /// It may throw a [PubLicenseException] if:
  /// * The response from pub.dev is not successful.
  /// * The response body cannot be parsed.
  Future<SpdxLicense> getLicense(String packageName) async {
    final response = await _client.get(
      Uri.parse(_pubPackageLicenseUri(packageName)),
    );

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

SpdxLicense _scrapeLicense(html_dom.Document document) {
  final detailInfoBox = document.querySelector('.detail-info-box');

  if (detailInfoBox == null) {
    return SpdxLicense.$unknown;
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
    return SpdxLicense.$unknown;
  }

  final licenseText = rawLicenseText.split('(').first.trim();
  return SpdxLicense.parse(licenseText);
}

void main() async {
  final pubLicense = PubLicense();
  final license = await pubLicense.getLicense('dart_frog');
  print(license);
}
