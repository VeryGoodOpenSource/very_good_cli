part of 'coverage.dart';

/// Discovers all Dart files in the specified directories for coverage.
List<String> _discoverDartFilesForCoverage({
  required String cwd,
  required List<String> reportOn,
  String? excludeFromCoverage,
}) {
  final excludedGlobs = _parseExcludeGlobs(excludeFromCoverage);

  return reportOn.expand((dir) {
    final reportOnPath = p.join(cwd, dir);
    final directory = Directory(reportOnPath);

    if (!directory.existsSync()) return <String>[];

    return directory
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .map((file) => p.relative(file.path, from: cwd))
        .whereNot((file) => excludedGlobs.any((glob) => glob.matches(file)));
  }).toList();
}

/// Enhances an existing lcov file by adding uncovered files with 0% coverage.
Future<void> _addUntestedFiles({
  required String lcovPath,
  required String cwd,
  required List<String> reportOn,
  String? excludeFromCoverage,
}) async {
  final lcovFile = File(lcovPath);

  final allDartFiles = _discoverDartFilesForCoverage(
    cwd: cwd,
    reportOn: reportOn,
    excludeFromCoverage: excludeFromCoverage,
  );

  // Parse existing lcov to find covered files
  final existingRecords = await Parser.parse(lcovPath);
  final coveredFiles = existingRecords.map((r) => r.file).nonNulls.toSet();

  final uncoveredFiles = allDartFiles.where((file) {
    final normalizedFile = p.normalize(file);
    return !coveredFiles.any(
      (covered) => p.normalize(covered).endsWith(normalizedFile),
    );
  }).toList();

  if (uncoveredFiles.isEmpty) return;

  // Append uncovered files to lcov
  final buffer = StringBuffer(await lcovFile.readAsString());

  for (final file in uncoveredFiles) {
    final dartFile = File(p.join(cwd, file));
    if (!dartFile.existsSync()) continue;
    buffer.write(_untestedFileRecord(file, await dartFile.readAsLines()));
  }

  await lcovFile.writeAsString(buffer.toString());
}

/// The lcov record of a [file] no test reached, given its [lines], where
/// every non-trivial line is marked as uncovered.
String _untestedFileRecord(String file, List<String> lines) {
  final uncoveredLineNumbers = [
    for (final (index, line) in lines.indexed)
      if (_isCoverableLine(line.trim())) index + 1,
  ];

  final record = StringBuffer()..writeln('SF:${file.replaceAll(r'\', '/')}');
  for (final lineNumber in uncoveredLineNumbers) {
    record.writeln('DA:$lineNumber,0');
  }
  record
    ..writeln('LF:${uncoveredLineNumbers.length}')
    ..writeln('LH:0')
    ..writeln('end_of_record');
  return record.toString();
}

/// Whether a [trimmedLine] of source counts towards coverage.
bool _isCoverableLine(String trimmedLine) =>
    trimmedLine.isNotEmpty &&
    !_nonCoverableLinePrefixes.any(trimmedLine.startsWith);

const _nonCoverableLinePrefixes = ['//', 'import', 'export', 'part'];
