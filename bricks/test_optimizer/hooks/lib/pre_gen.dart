import 'dart:io';

import 'package:hooks/dart_identifier_generator.dart';
import 'package:hooks/test_metadata.dart';
import 'package:mason/mason.dart';
import 'package:path/path.dart' as path;

typedef ExitFn = Never Function(int code);

ExitFn exitFn = exit;

/// The tag that opts a test file out of the optimized bundle.
const skipVeryGoodOptimizationTag = 'skip_very_good_optimization';

extension TestMetadataBundle on TestMetadata {
  bool get skipsOptimization => tagNames.contains(skipVeryGoodOptimizationTag);

  /// The named arguments to append to a `group` call, each prefixed by `, `.
  String get groupArguments {
    return arguments.entries.map((e) => ', ${e.key}: ${e.value}').join();
  }
}

Future<void> run(HookContext context) async {
  final packageRoot = context.vars['package-root'] as String;
  final testDir = Directory(path.join(packageRoot, 'test'));

  if (!testDir.existsSync()) {
    context.logger.err('Could not find directory ${testDir.path}');
    exitFn(1);
  }

  final pubspec = File(path.join(packageRoot, 'pubspec.yaml'));
  if (!pubspec.existsSync()) {
    context.logger.err('Could not find pubspec.yaml at ${testDir.path}');
    exitFn(1);
  }

  final pubspecContents = await pubspec.readAsString();
  final flutterSdkRegExp = RegExp(r'sdk:\s*flutter$', multiLine: true);
  final isFlutter = flutterSdkRegExp.hasMatch(pubspecContents);

  final shardIndex = context.vars['shard-index'] as int?;
  final totalShards = context.vars['total-shards'] as int?;

  // The CLI validates these before it gets here, but `mason make` prompts for
  // them directly, so guard the round-robin below against values that would
  // never terminate or index out of range.
  if (shardIndex != null &&
      totalShards != null &&
      (totalShards < 1 || shardIndex < 1 || shardIndex > totalShards)) {
    context.logger.err(
      'shard-index must be between 1 and total-shards, but got '
      'shard-index $shardIndex and total-shards $totalShards',
    );
    exitFn(1);
  }

  final identifierGenerator = DartIdentifierGenerator();
  final optimizedTests = <Map<String, String>>[];
  final notOptimizedTests = <String>[];

  final tests = testDir
      .listSync(recursive: true)
      .where((entity) => entity.isTest)
      .cast<File>();
  final parsedTests = await Future.wait(
    tests.map((file) => _parse(file, testDir: testDir.path)),
  );

  // Sorting guarantees a deterministic order across machines, which is what
  // makes sharding reproducible: `Directory.listSync` order is filesystem
  // dependent, so without this two runners could disagree on the partition
  // and either skip or duplicate tests. Tests kept out of the bundle are
  // dealt out in the same round as the optimized ones, which keeps every
  // shard within one file of the others.
  final shard = _shardOf(
    parsedTests..sort((a, b) => a.relativePath.compareTo(b.relativePath)),
    shardIndex: shardIndex,
    totalShards: totalShards,
  );

  for (final (:relativePath, :content, :metadata) in shard) {
    if (metadata.skipsOptimization) {
      notOptimizedTests.add(relativePath);
      continue;
    }

    if (content.contains(skipVeryGoodOptimizationTag)) {
      context.logger.warn(
        '$relativePath names $skipVeryGoodOptimizationTag but was optimized '
        'anyway: package:test reads @Tags only from the metadata of the '
        "file's first directive.",
      );
    }

    for (final annotation in metadata.droppedAnnotations) {
      context.logger.warn(
        '$relativePath: left $annotation out of the optimized bundle, which '
        'cannot resolve every name it references.',
      );
    }

    optimizedTests.add({
      'path': relativePath,
      'identifier': identifierGenerator.next(),
      'groupArguments': metadata.groupArguments,
    });
  }

  context.vars = {
    'tests': optimizedTests,
    'isFlutter': isFlutter,
    'notOptimizedTests': notOptimizedTests,
  };
}

typedef _ParsedTest = ({
  String relativePath,
  String content,
  TestMetadata metadata,
});

/// Reads and parses [file], keyed by its POSIX path relative to [testDir].
Future<_ParsedTest> _parse(File file, {required String testDir}) async {
  final content = await file.readAsString();
  return (
    relativePath: path.relative(file.path, from: testDir).replaceAll(r'\', '/'),
    content: content,
    metadata: parseTestMetadata(content, path: file.path),
  );
}

/// Returns the subset of [items] that belongs to the shard [shardIndex] out of
/// [totalShards], or [items] unchanged when sharding is not enabled (either
/// value is `null`).
///
/// Items are dealt out round-robin (index modulo [totalShards]) over the
/// already sorted [items], which keeps shards balanced in file count and makes
/// the partition stable for a given test suite.
List<T> _shardOf<T>(
  List<T> items, {
  required int? shardIndex,
  required int? totalShards,
}) {
  if (shardIndex == null || totalShards == null) return items;

  return [
    for (var i = shardIndex - 1; i < items.length; i += totalShards) items[i],
  ];
}

extension on FileSystemEntity {
  bool get isTest {
    return this is File && path.basename(this.path).endsWith('_test.dart');
  }
}
