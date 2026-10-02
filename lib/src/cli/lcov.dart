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
    Map<int, int> lines = const {},
    Map<String, int> functionLines = const {},
    Map<String, int> functionHits = const {},
    Map<LcovBranch, int> branches = const {},
  }) : lines = Map.unmodifiable(lines),
       functionLines = Map.unmodifiable(functionLines),
       functionHits = Map.unmodifiable(functionHits),
       branches = Map.unmodifiable(branches);

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
    lines: lines,
    functionLines: functionLines,
    functionHits: functionHits,
    branches: branches,
  );

  /// Serializes this record to lcov, ending with `end_of_record`.
  String toLcov() {
    final buffer = StringBuffer()..writeln('SF:$file');

    if (functionLines.isNotEmpty) {
      final functions = functionLines.entries.sortedBy<num>(
        (function) => function.value,
      );
      for (final MapEntry(key: name, value: line) in functions) {
        buffer.writeln('FN:$line,$name');
      }
      final hitNames = [
        for (final MapEntry(key: name) in functions)
          if ((functionHits[name] ?? 0) > 0) name,
      ];
      for (final name in hitNames) {
        buffer.writeln('FNDA:${functionHits[name]},$name');
      }
      buffer
        ..writeln('FNF:${functions.length}')
        ..writeln('FNH:${hitNames.length}');
    }

    for (final line in lines.keys.sorted((a, b) => a - b)) {
      buffer.writeln('DA:$line,${lines[line]}');
    }
    buffer
      ..writeln('LF:${lines.length}')
      ..writeln('LH:${lines.values.where((hits) => hits > 0).length}');

    if (branches.isNotEmpty) {
      final keys = branches.keys.sorted(_compareBranches);
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

/// Sums the hits of the lcov details of a single source [file], while parsing
/// or merging, then [build]s its [LcovRecord].
class _LcovRecordBuilder {
  new(this.file);

  final String file;

  final _lines = <int, int>{};

  final _functionLines = <String, int>{};

  final _functionHits = <String, int>{};

  final _branches = <LcovBranch, int>{};

  void addLine(int line, int hits) => _sum(_lines, line, hits);

  void addFunction(String name, int line) =>
      _functionLines.putIfAbsent(name, () => line);

  void addFunctionHits(String name, int hits) =>
      _sum(_functionHits, name, hits);

  void addBranch(LcovBranch branch, int taken) =>
      _sum(_branches, branch, taken);

  /// Adds the hits of [record].
  void addAll(LcovRecord record) {
    record.lines.forEach(addLine);
    record.functionLines.forEach(addFunction);
    record.functionHits.forEach(addFunctionHits);
    record.branches.forEach(addBranch);
  }

  LcovRecord build() => LcovRecord(
    file,
    lines: _lines,
    functionLines: _functionLines,
    functionHits: _functionHits,
    branches: _branches,
  );

  static void _sum<K>(Map<K, int> hits, K key, int value) =>
      hits[key] = (hits[key] ?? 0) + value;
}

/// Orders branches by line, then block, then branch number.
int _compareBranches(LcovBranch a, LcovBranch b) {
  final (aLine, aBlock, aBranch) = a;
  final (bLine, bBlock, bBranch) = b;
  if (aLine != bLine) return aLine.compareTo(bLine);
  if (aBlock != bBlock) return aBlock.compareTo(bBlock);
  return aBranch.compareTo(bBranch);
}

/// Parses the lcov [content] into one [LcovRecord] per `end_of_record`.
///
/// Unlike `package:lcov_parser`, this tolerates CRLF line endings, blank
/// lines, `:` and `,` in source paths and tags it doesn't know about, which
/// are ignored along with the `LF/LH/FNF/FNH/BRF/BRH` summaries. Both the
/// `FN:<line>,<name>` layout of `package:coverage` and the
/// `FN:<line>,<end line>,<name>` one of lcov 2 are read, the end line being
/// ignored.
///
/// Throws a [FormatException] when a line is malformed.
List<LcovRecord> parseLcov(String content) {
  final records = <LcovRecord>[];
  _LcovRecordBuilder? record;

  for (final rawLine in const LineSplitter().convert(content)) {
    final line = rawLine.trim();
    if (line.isEmpty) continue;

    if (line == 'end_of_record') {
      if (record != null) records.add(record.build());
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

    Never invalid() => throw FormatException('Invalid lcov line "$line".');

    int number(int index) =>
        int.tryParse(fields.elementAtOrNull(index) ?? '') ?? invalid();

    // Function names may contain commas, so they span the remaining fields.
    String name(int index) => switch (fields.skip(index).join(',')) {
      '' => invalid(),
      final name => name,
    };

    switch ((tag, record)) {
      case ('SF', _):
        // A record left without `end_of_record` is kept, as at the end of the
        // report, rather than dropped.
        if (record != null) records.add(record.build());
        record = _LcovRecordBuilder(value);
      case ('DA' || 'FN' || 'FNDA' || 'BRDA', null):
        throw FormatException('Found "$line" before any "SF:" line.');
      case ('DA', final _LcovRecordBuilder current):
        current.addLine(number(0), number(1));
      case ('FN', final _LcovRecordBuilder current):
        // Dart function names can't start with a digit, so a numeric second
        // field is the end line of lcov 2.
        final hasEndLine = fields.length > 2 && int.tryParse(fields[1]) != null;
        current.addFunction(name(hasEndLine ? 2 : 1), number(0));
      case ('FNDA', final _LcovRecordBuilder current):
        current.addFunctionHits(name(1), number(0));
      case ('BRDA', final _LcovRecordBuilder current):
        // A `-` means the branch was never reached, which counts as not taken.
        final taken = fields.elementAtOrNull(3) == '-' ? 0 : number(3);
        current.addBranch((number(0), number(1), number(2)), taken);
    }
  }

  if (record != null) records.add(record.build());
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

/// The directories of the packages under [cwd], relative to it, that have a
/// `coverage/lcov.info` report, as left behind by
/// `very_good test --recursive --coverage`.
///
/// Packages are found the same way as with `--recursive`, so platform, build
/// and tool directories are skipped.
List<String> discoverLcovPackages(String cwd) => Directory(cwd)
    .listSync(recursive: true)
    .where(_isPackagePubspec)
    .map((pubspec) => p.relative(pubspec.parent.path, from: cwd))
    .where(
      (package) =>
          File(p.join(cwd, package, 'coverage', 'lcov.info')).existsSync(),
    )
    .sorted();

/// The files matched by [glob], relative to [cwd] and sorted.
///
/// Throws a [FormatException] when [glob] is invalid.
List<String> expandLcovGlob(String glob, {required String cwd}) =>
    Glob(glob)
        .listSync(root: cwd)
        .whereType<File>()
        .map((file) => p.relative(file.path, from: cwd))
        .sorted();

/// Merges [records] that describe the same source file, summing their hits.
///
/// The result keeps the order in which each file first appears.
List<LcovRecord> mergeLcovRecords(Iterable<LcovRecord> records) {
  final merged = <String, _LcovRecordBuilder>{};
  for (final record in records) {
    merged
        .putIfAbsent(record.file, () => _LcovRecordBuilder(record.file))
        .addAll(record);
  }
  return [for (final record in merged.values) record.build()];
}

/// Serializes [records] to lcov.
String formatLcovRecords(Iterable<LcovRecord> records) =>
    records.map((record) => record.toLcov()).join();
