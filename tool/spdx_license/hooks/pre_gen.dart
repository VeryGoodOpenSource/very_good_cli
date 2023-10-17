/// A generator that creates the SPDX License enumeration.
///
/// For more information, see the `README.md`.
library spdx_license_pre_gen;

import 'package:archive/archive.dart';
import 'package:http/http.dart' as http;
import 'package:mason/mason.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;

/// The SPDX license list URL.
///
/// This is the URL of the SPDX license list data on GitHub. It should always
/// be consistent with PANA's [SPDX license list URL](https://github.com/dart-lang/pana/blob/master/third_party/spdx/update_licenses.dart).
///
/// See also:
///
/// * [PANA](https://github.com/dart-lang/pana), the Dart package analyzer.
const _spdxLicenseListUrl =
    'https://github.com/spdx/license-list-data/archive/refs/heads/master.zip';

/// The license list path used by the PANA tool.
///
/// The [_spdxLicenseListUrl] has different paths for the license list data; the
/// PANA tool uses only those under the [_spdxTargetPath].
const _spdxTargetPath = 'license-list-data-main/json/details';

/// {@template generate_spdx_license_exception}
/// An exception thrown by the Generate SPDX License tool.
/// {@endtemplate}
class GenerateSpdxLicenseException implements Exception {
  /// {@macro generate_spdx_license_exception}
  const GenerateSpdxLicenseException(String message)
      : message = '[spdx_license] $message';

  final String message;
}

/// {@macro pre_gen}
Future<void> run(HookContext context) async => preGen(context);

/// {@template pre_gen}
/// Populates the context `licenses` variable with the SPDX license list, and
/// the `total` variable with the total number of licenses.
///
/// If the user decides to use their own license list, the `licenses` variable
/// will be populated with the user's list. Otherwise, the SPDX license list
/// will be downloaded and parsed from the same source as the PANA tool.
/// {@endtemplate}
@visibleForTesting
Future<void> preGen(
  HookContext context, {
  @visibleForTesting http.Client? client,
  @visibleForTesting ZipDecoder? zipDecoder,
}) async {
  try {
    final licensesVar = context.vars['licenses'];
    final shouldFetchLicenses =
        (licensesVar == null || (licensesVar is List && licensesVar.isEmpty)) &&
            licensesVar is! List<String>;

    final licenses = shouldFetchLicenses
        ? await _downloadLicenses(
            logger: context.logger,
            client: client,
            zipDecoder: zipDecoder,
          )
        : licensesVar as List;

    final newLicensesVar = <Map<String, dynamic>>[
      for (final license in licenses)
        {
          'license': license,
          'identifier': license.toString().toDartIdentifier(),
        },
    ];

    context.vars = {
      'licenses': newLicensesVar,
      'total': newLicensesVar.length,
    };
  } on GenerateSpdxLicenseException catch (e) {
    context.logger.err(e.message);
  } catch (e) {
    context.logger.err(
      '''[spdx_license] An unknown error occurred, received error: $e''',
    );
  }
}

Future<List<String>> _downloadLicenses({
  required Logger logger,
  @visibleForTesting http.Client? client,
  @visibleForTesting ZipDecoder? zipDecoder,
}) async {
  final progress = logger.progress(
    'Starting to download the SPDX license list, this might take some time',
  );

  final httpClient = client ?? http.Client();
  final response = await httpClient.get(Uri.parse(_spdxLicenseListUrl));

  if (response.statusCode != 200) {
    progress.cancel();
    throw GenerateSpdxLicenseException(
      '''Failed to download the SPDX license list, received response with status code: ${response.statusCode}''',
    );
  }

  late final Archive archive;
  try {
    final decoder = zipDecoder ?? ZipDecoder();
    archive = decoder.decodeBytes(response.bodyBytes);
  } catch (e) {
    progress.cancel();
    throw GenerateSpdxLicenseException(
      'Failed to decode the SPDX license list, received error: $e',
    );
  }

  final licenses = <String>{};
  for (final file in archive.files) {
    final filename = file.name;
    if (!filename.startsWith(_spdxTargetPath)) continue;

    final license = path.basename(path.withoutExtension(filename));
    licenses.add(license);
  }

  progress.complete('Found ${licenses.length} SPDX licenses');
  return licenses.toList()..sort();
}

extension on String {
  String toDartIdentifier() {
    return '\$$this'
        .replaceAll('-', '_')
        .replaceAll('.', '_')
        .replaceAll(' ', '')
        .replaceAll('+', 'plus')
        .trim();
  }
}
