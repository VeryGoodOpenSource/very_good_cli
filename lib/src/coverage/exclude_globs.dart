part of 'coverage.dart';

/// Parses the whitespace-separated glob patterns of an `--exclude-coverage`
/// value, ignoring empty segments.
List<Glob> _parseExcludeGlobs(String? excludeFromCoverage) => [
  for (final pattern in (excludeFromCoverage ?? '').split(_whitespace))
    if (pattern.isNotEmpty) Glob(pattern),
];

final _whitespace = RegExp(r'\s+');
