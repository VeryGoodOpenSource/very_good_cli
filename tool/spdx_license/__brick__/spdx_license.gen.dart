// GENERATED CODE - DO NOT MODIFY BY HAND
// 
// If you need to make changes, please refer to the SPDX License brick 
// CONTRIBUTING file.

// ignore_for_file: type=lint

/// List of all SPDX licenses.
///
/// This file was automatically generated with the SPDX License brick.
library spdx_license;

/// {@template spdx_license}
/// A list of all {{total}} SPDX licenses.
///
/// These have been automatically generated from the SPDX License brick.
/// {@endtemplate}
enum SpdxLicense {
  {{#licenses}}{{{identifier}}}._('{{{license}}}'),
  {{/licenses}}$unknown._('unknown');

  const SpdxLicense._(this.value);

  /// Parses a [String] into a [SpdxLicense].
  ///
  /// If the [source] is not a valid [SpdxLicense], a [FormatException] is
  /// thrown.
  factory SpdxLicense.parse(String source) {
    final result = SpdxLicense.tryParse(source);
    if (result == null) {
      throw FormatException('Failed to parse $source as SpdxLicense.');
    }
    return result;
  }

  /// Parse [source] into a possible [SpdxLicense].
  ///
  /// Like [SpdxLicense.parse] except that it returns `null` where a similar
  /// call to [SpdxLicense.parse] would throw a [FormatException].
  static SpdxLicense? tryParse(String source) => _valueMap[source];

  static final Map<String, SpdxLicense> _valueMap = SpdxLicense.values
    .asNameMap()
    .map((key, value) => MapEntry(value.value, value));

  final String value;
}
