part of 'cli.dart';

/// A branch of an lcov record, identified by its line, block and branch
/// number.
typedef LcovBranch = (int line, int block, int branch);

/// {@template lcov_record}
/// The coverage of a single source file, as described by an lcov record.
///
/// Only the details are kept: the `LF/LH/FNF/FNH/BRF/BRH` summaries are
/// derived from them when serializing, so they stay correct after merging.
/// {@endtemplate}
class LcovRecord {
  /// {@macro lcov_record}
  new(
    this.file, {
    Map<int, int>? lines,
    Map<String, int>? functionLines,
    Map<String, int>? functionHits,
    Map<LcovBranch, int>? branches,
  }) : lines = lines ?? {},
       functionLines = functionLines ?? {},
       functionHits = functionHits ?? {},
       branches = branches ?? {};

  /// The source file path (`SF:`).
  final String file;

  /// Hits per line number (`DA:`).
  final Map<int, int> lines;

  /// Line number per function name (`FN:`).
  final Map<String, int> functionLines;

  /// Hits per function name (`FNDA:`).
  final Map<String, int> functionHits;

  /// Times taken per branch (`BRDA:`).
  final Map<LcovBranch, int> branches;

  /// A copy of this record for the source [file].
  LcovRecord withFile(String file) => LcovRecord(
    file,
    lines: {...lines},
    functionLines: {...functionLines},
    functionHits: {...functionHits},
    branches: {...branches},
  );

  /// Adds the hits of [other] into this record.
  void addAll(LcovRecord other) {
    void sum<K>(Map<K, int> target, Map<K, int> source) {
      for (final MapEntry(:key, :value) in source.entries) {
        target[key] = (target[key] ?? 0) + value;
      }
    }

    sum(lines, other.lines);
    sum(functionHits, other.functionHits);
    sum(branches, other.branches);
    for (final MapEntry(:key, :value) in other.functionLines.entries) {
      functionLines.putIfAbsent(key, () => value);
    }
  }

  /// Serializes this record to lcov, ending with `end_of_record`.
  String toLcov() {
    final buffer = StringBuffer()..writeln('SF:$file');

    if (functionLines.isNotEmpty) {
      final names = functionLines.keys.sortedBy<num>((n) => functionLines[n]!);
      for (final name in names) {
        buffer.writeln('FN:${functionLines[name]},$name');
      }
      for (final name in names) {
        final hits = functionHits[name] ?? 0;
        if (hits > 0) buffer.writeln('FNDA:$hits,$name');
      }
      buffer
        ..writeln('FNF:${names.length}')
        ..writeln(
          'FNH:${names.where((n) => (functionHits[n] ?? 0) > 0).length}',
        );
    }

    for (final line in lines.keys.sorted((a, b) => a - b)) {
      buffer.writeln('DA:$line,${lines[line]}');
    }
    buffer
      ..writeln('LF:${lines.length}')
      ..writeln('LH:${lines.values.where((hits) => hits > 0).length}');

    if (branches.isNotEmpty) {
      final keys = branches.keys.sorted(
        (a, b) => [
          a.$1 - b.$1,
          a.$2 - b.$2,
          a.$3 - b.$3,
        ].firstWhere((order) => order != 0, orElse: () => 0),
      );
      for (final key in keys) {
        buffer.writeln('BRDA:${key.$1},${key.$2},${key.$3},${branches[key]}');
      }
      buffer
        ..writeln('BRF:${branches.length}')
        ..writeln('BRH:${branches.values.where((taken) => taken > 0).length}');
    }

    buffer.writeln('end_of_record');
    return buffer.toString();
  }
}

/// Parses the lcov [content] into one [LcovRecord] per `end_of_record`.
///
/// Unlike `package:lcov_parser`, this tolerates CRLF line endings, blank
/// lines, `:` and `,` in source paths and tags it doesn't know about, which
/// are ignored along with the `LF/LH/FNF/FNH/BRF/BRH` summaries.
///
/// Throws a [FormatException] when a line is malformed.
List<LcovRecord> parseLcov(String content) {
  final records = <LcovRecord>[];
  LcovRecord? record;

  for (final rawLine in const LineSplitter().convert(content)) {
    final line = rawLine.trim();
    if (line.isEmpty) continue;

    if (line == 'end_of_record') {
      if (record != null) records.add(record);
      record = null;
      continue;
    }

    final separator = line.indexOf(':');
    if (separator < 0) {
      throw FormatException('Invalid lcov line "$line".');
    }
    final tag = line.substring(0, separator);
    final value = line.substring(separator + 1);
    final fields = value.split(',');

    int number(int index) =>
        int.tryParse(fields.elementAtOrNull(index) ?? '') ??
        (throw FormatException('Invalid lcov line "$line".'));

    // Function names may contain commas, so they span the remaining fields.
    String name() => fields.skip(1).join(',');

    switch ((tag, record)) {
      case ('SF', _):
        record = LcovRecord(value);
      case ('DA' || 'FN' || 'FNDA' || 'BRDA', null):
        throw FormatException('Found "$line" before any "SF:" line.');
      case ('DA', final LcovRecord current):
        final lineNumber = number(0);
        current.lines[lineNumber] =
            (current.lines[lineNumber] ?? 0) + number(1);
      case ('FN', final LcovRecord current):
        current.functionLines[name()] = number(0);
      case ('FNDA', final LcovRecord current):
        current.functionHits[name()] =
            (current.functionHits[name()] ?? 0) + number(0);
      case ('BRDA', final LcovRecord current):
        final branch = (number(0), number(1), number(2));
        // A `-` means the branch was never reached, which counts as not taken.
        final taken = fields.elementAtOrNull(3) == '-' ? 0 : number(3);
        current.branches[branch] = (current.branches[branch] ?? 0) + taken;
    }
  }

  if (record != null) records.add(record);
  return records;
}

/// Normalizes the source path of [records] so that reports produced on
/// different runners, or for different packages, key the same file the same
/// way.
///
/// * Separators become `/`.
/// * Relative paths are rebased onto [packagePath] (relative to the current
///   directory of [context]) when given, so that `lib/a.dart` from two
///   packages stay distinct.
/// * Absolute paths under the current directory of [context] become relative
///   to it. Others are kept, and reported through [onExternalPath].
///
/// [context] defaults to the platform's [p.context].
List<LcovRecord> normalizeLcovRecords(
  Iterable<LcovRecord> records, {
  String? packagePath,
  p.Context? context,
  void Function(String path)? onExternalPath,
}) {
  final ctx = context ?? p.context;

  String normalize(String file) {
    final path = file.replaceAll(r'\', '/');

    final String resolved;
    if (ctx.isAbsolute(path) && ctx.isWithin(ctx.current, path)) {
      resolved = ctx.relative(path);
    } else if (ctx.isAbsolute(path) || p.windows.isAbsolute(path)) {
      // Also checked as Windows, since a report from a Windows runner can be
      // merged on any other platform.
      onExternalPath?.call(path);
      resolved = path;
    } else {
      resolved = packagePath == null ? path : ctx.join(packagePath, path);
    }
    return ctx.normalize(resolved).replaceAll(r'\', '/');
  }

  return [
    for (final record in records) record.withFile(normalize(record.file)),
  ];
}

/// Merges [records] that describe the same source file, summing their hits.
///
/// The result keeps the order in which each file first appears.
List<LcovRecord> mergeLcovRecords(Iterable<LcovRecord> records) {
  final merged = <String, LcovRecord>{};
  for (final record in records) {
    merged
        .putIfAbsent(record.file, () => LcovRecord(record.file))
        .addAll(record);
  }
  return merged.values.toList();
}

/// Serializes [records] to lcov.
String formatLcovRecords(Iterable<LcovRecord> records) =>
    records.map((record) => record.toLcov()).join();
