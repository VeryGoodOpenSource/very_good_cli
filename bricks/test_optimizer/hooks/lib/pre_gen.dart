import 'dart:io';

import 'package:hooks/dart_identifier_generator.dart';
import 'package:mason/mason.dart';
import 'package:path/path.dart' as path;

typedef ExitFn = Never Function(int code);

ExitFn exitFn = exit;

String skipVeryGoodOptimizationTag = 'skip_very_good_optimization';

/// The name of the marker file that can be placed in a directory to disable
/// test optimization for all test files in that directory and its
/// subdirectories.
const skipVeryGoodOptimizationMarker = '.$skipVeryGoodOptimizationTag';

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

  final identifierGenerator = DartIdentifierGenerator();
  final testIdentifierTable = <Map<String, String>>[];
  final tests = testDir.listSync(recursive: true).where((entity) => entity.isTest);

  final notOptimizedTests = await getNotOptimizedTests(tests, testDir.path);

  for (final entity in tests) {
    final relativePath = path.relative(entity.path, from: testDir.path).replaceAll(r'\', '/');
    testIdentifierTable.add({'path': relativePath, 'identifier': identifierGenerator.next()});
  }

  final optimizedTestsIdentifierTable = testIdentifierTable
      .where((e) => !notOptimizedTests.contains(e['path']))
      .toList();

  context.vars = {
    'tests': optimizedTestsIdentifierTable,
    'isFlutter': isFlutter,
    'notOptimizedTests': notOptimizedTests,
  };
}

extension on FileSystemEntity {
  bool get isTest {
    return this is File && path.basename(this.path).endsWith('_test.dart');
  }
}

Future<List<String>> getNotOptimizedTests(Iterable<FileSystemEntity> tests, String testDir) async {
  final paths = tests.map((e) => e.path).toList();
  final formattedPaths = paths.map((e) => e.replaceAll('/./', '/')).toList();

  final fileFutures = formattedPaths.map((filePath) => _shouldSkipOptimization(filePath, testDir));
  final fileResults = await Future.wait(fileFutures);

  final testWithVeryGoodTest = <String>[];
  for (var i = 0; i < formattedPaths.length; i++) {
    if (fileResults[i]) {
      testWithVeryGoodTest.add(formattedPaths[i]);
    }
  }

  /// Format to relative path
  final relativePaths = testWithVeryGoodTest.map((e) => path.relative(e, from: testDir)).toList();

  return relativePaths;
}

/// Returns true if [filePath] should be excluded from optimization, either
/// because:
/// - the file contains the [skipVeryGoodOptimizationTag] annotation, or
/// - any ancestor directory up to [testDir] contains a
///   [skipVeryGoodOptimizationMarker] marker file.
Future<bool> _shouldSkipOptimization(String filePath, String testDir) async {
  if (await _checkFileForSkipVeryGoodOptimization(filePath)) return true;
  return _isInSkippedDirectory(filePath, testDir);
}

/// Check if a single file contains skip_very_good_optimization tag
Future<bool> _checkFileForSkipVeryGoodOptimization(String filePath) async {
  final file = File(filePath);
  if (!file.existsSync()) return false;
  final content = await file.readAsString();
  return skipVeryGoodOptimizationRegExp.hasMatch(content);
}

/// Returns true if [filePath] resides in a directory (or any of its ancestors
/// up to [testDir] inclusive) that contains a [skipVeryGoodOptimizationMarker]
/// marker file.
bool _isInSkippedDirectory(String filePath, String testDir) {
  final normalizedTestDir = path.normalize(testDir);
  var dir = path.normalize(path.dirname(filePath));

  // Walk up from the file's directory to testDir (inclusive).
  while (path.equals(dir, normalizedTestDir) || path.isWithin(normalizedTestDir, dir)) {
    if (File(path.join(dir, skipVeryGoodOptimizationMarker)).existsSync()) {
      return true;
    }
    final parent = path.dirname(dir);
    if (parent == dir) break; // reached filesystem root
    dir = parent;
  }
  return false;
}
