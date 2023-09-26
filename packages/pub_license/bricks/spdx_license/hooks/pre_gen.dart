/// A generator that updates the SPDX License enumeration.
///
/// For more information, see the [README](./README.md).
library generate_spdx_license_pre_gen;

import 'package:archive/archive.dart';
import 'package:http/http.dart' as http;
import 'package:mason/mason.dart';
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
/// PANA tool uses those under the [_spdxTargetPath].
const _spdxTargetPath = 'license-list-data-main/json/details';

/// {@template generate_spdx_license}
/// An exception thrown by the Generate SPDX License tool.
/// {@endtemplate}
class GenerateSpdxLicense implements Exception {
  const GenerateSpdxLicense(String message)
      : message = '[GenerateSpdxLicense] $message';

  final String message;
}

Future<void> run(HookContext context) async {
  try {
    await _run(context);
  } on GenerateSpdxLicense catch (e) {
    context.logger.err(e.message);
  } catch (e) {
    context.logger.err('An unknown error occurred, received error: $e');
  }
}

Future<void> _run(HookContext context) async {
  final progress = context.logger.progress(
    'Starting to download the SPDX license list, this might take some time...',
  );

  final response = await http.Client().get(Uri.parse(_spdxLicenseListUrl));

  if (response.statusCode != 200) {
    progress.cancel();
    throw GenerateSpdxLicense(
      '''Failed to download the SPDX license list, received response with status code: ${response.statusCode}''',
    );
  }

  late final Archive archive;
  try {
    archive = ZipDecoder().decodeBytes(response.bodyBytes);
  } catch (e) {
    progress.cancel();
    throw GenerateSpdxLicense(
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

  context.vars['licenses'] = licenses.toList()..sort();
  progress.complete();
}
