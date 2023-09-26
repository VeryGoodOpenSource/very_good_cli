// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: type=lint

/// List of all SPDX licenses.
///
/// This file was automatically generated with the SPDX license brick.
library spdx_license;

/// {@template spdx_license}
/// A list of SPDX licenses.
///
/// These have been automatically generated from the SPDX license brick.
/// {@endtemplate}
enum SpdxLicense {
  {{#licenses}}
  {{{identifier}}}._('{{{license}}}'),
  {{/licenses}}
  unknown._('unknown');

  const SpdxLicense._(this.value);

  final String value;
}
