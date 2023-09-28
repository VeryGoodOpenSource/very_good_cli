// GENERATED CODE - DO NOT MODIFY BY HAND
// 
// If you need to make changes, please refer to the SPDX License brick README
// file.

// ignore_for_file: type=lint

/// List of all SPDX licenses.
///
/// This file was automatically generated with the SPDX license brick.
library spdx_license;

/// {@template spdx_license}
/// A list of all {{total}} SPDX licenses.
///
/// These have been automatically generated from the SPDX license brick.
/// {@endtemplate}
enum SpdxLicense {
  {{#licenses}}{{{identifier}}}._('{{{license}}}'),
  {{/licenses}}$unknown._('unknown');

  const SpdxLicense._(this.value);

  /// Parses a [String] into a [SpdxLicense].
  ///
  /// If the [value] is not a valid [SpdxLicense], [SpdxLicense.$unknown] is
  /// returned instead.
  factory SpdxLicense.parse(String value) =>
      _valueMap[value] ?? SpdxLicense.$unknown;

  static final Map<String, SpdxLicense> _valueMap = SpdxLicense.values
      .asNameMap()
      .map((key, value) => MapEntry(value.value, value));

  final String value;
}
