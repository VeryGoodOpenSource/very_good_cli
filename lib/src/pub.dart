import 'dart:convert';
import 'package:http/http.dart' show Client;

/// The http endpoint for the very_good_cli version list
const endpoint = 'https://pub.dev/packages/very_good_cli.json';

/// A class used to interface with the pub.dev web API
class Pub {
  ///
  const Pub(this.client);

  /// The http client used to make the request
  final Client client;

  /// Returns the latest version of the very_good_cli
  Future<String?> getLatestVersion() async {
    final url = Uri.parse(endpoint);
    final response = await client.get(url);

    if (response.statusCode == 200) {
      // ignore: avoid_dynamic_calls
      final versions = json.decode(response.body)['versions'] as List<dynamic>
        ..sort();

      return versions.last.toString();
    }
  }
}
