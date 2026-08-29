import 'dart:io';

import 'package:hooks/dart_identifier_generator.dart';
import 'package:mason/mason.dart';
import 'package:path/path.dart' as path;

typedef ExitFn = Never Function(int code);

ExitFn exitFn = exit;

String skipVeryGoodOptimizationTag = 'skip_very_good_optimization';
RegExp skipVeryGoodOptimizationRegExp = RegExp(
  "@Tags\\s*\\(\\s*\\[[\\s\\S]*?[\"']$skipVeryGoodOptimizationTag[\"'][\\s\\S]*?\\]\\s*\\)",
  multiLine: true,
);

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

  final tests = testDir
      .listSync(recursive: true)
      .where((entity) => entity.isTest);

  final notOptimizedTests = await getNotOptimizedTests(tests, testDir.path);

  // Sorting guarantees a deterministic order across machines, which is what
  // makes sharding reproducible: `Directory.listSync` order is filesystem
  // dependent, so without this two runners could disagree on the partition
  // and either skip or duplicate tests.
  final testPaths =
      tests
          .map(
            (entity) => path
                .relative(entity.path, from: testDir.path)
                .replaceAll(r'\', '/'),
          )
          .toList()
        ..sort();

  final optimizedTestPaths = shardOf(
    testPaths.where((p) => !notOptimizedTests.contains(p)).toList(),
    shardIndex: shardIndex,
    totalShards: totalShards,
  );

  // Non optimized tests run as standalone files alongside the optimizer
  // entrypoint, so they must be sharded too. Otherwise every runner would
  // re-run all of them, defeating the purpose of sharding.
  final shardedNotOptimizedTests = shardOf(
    notOptimizedTests..sort(),
    shardIndex: shardIndex,
    totalShards: totalShards,
  );

  final identifierGenerator = DartIdentifierGenerator();
  final optimizedTestsIdentifierTable = [
    for (final relativePath in optimizedTestPaths)
      {'path': relativePath, 'identifier': identifierGenerator.next()},
  ];

  context.vars = {
    'tests': optimizedTestsIdentifierTable,
    'isFlutter': isFlutter,
    'notOptimizedTests': shardedNotOptimizedTests,
  };
}

/// Returns the subset of [paths] that belongs to the shard [shardIndex] out of
/// [totalShards].
///
/// Returns [paths] unchanged when sharding is not enabled (either value is
/// `null`).
///
/// Files are dealt out round-robin (index modulo [totalShards]) over the
/// already sorted [paths], which keeps shards balanced in file count and makes
/// the partition stable for a given test suite.
List<String> shardOf(
  List<String> paths, {
  required int? shardIndex,
  required int? totalShards,
}) {
  if (shardIndex == null || totalShards == null) return paths;

  return [
    for (var i = shardIndex - 1; i < paths.length; i += totalShards) paths[i],
  ];
}

extension on FileSystemEntity {
  bool get isTest {
    return this is File && path.basename(this.path).endsWith('_test.dart');
  }
}

Future<List<String>> getNotOptimizedTests(
  Iterable<FileSystemEntity> tests,
  String testDir,
) async {
  final paths = tests.map((e) => e.path).toList();
  final formattedPaths = paths.map((e) => e.replaceAll('/./', '/')).toList();

  final fileFutures = formattedPaths.map(_checkFileForSkipVeryGoodOptimization);
  final fileResults = await Future.wait(fileFutures);

  final testWithVeryGoodTest = <String>[];
  for (var i = 0; i < formattedPaths.length; i++) {
    if (fileResults[i]) {
      testWithVeryGoodTest.add(formattedPaths[i]);
    }
  }

  /// Format to relative path, normalizing separators so the paths compare
  /// equal to the ones built in [run] on Windows too.
  final relativePaths = testWithVeryGoodTest
      .map((e) => path.relative(e, from: testDir).replaceAll(r'\', '/'))
      .toList();

  return relativePaths;
}

/// Check if a single file contains skip_very_good_optimization tag
Future<bool> _checkFileForSkipVeryGoodOptimization(String path) async {
  final file = File(path);
  if (!file.existsSync()) return false;
  final content = await file.readAsString();
  return skipVeryGoodOptimizationRegExp.hasMatch(content);
}
