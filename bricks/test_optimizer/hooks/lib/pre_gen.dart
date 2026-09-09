import 'dart:io';

import 'package:hooks/dart_identifier_generator.dart';
import 'package:hooks/suite_annotations.dart';
import 'package:mason/mason.dart';
import 'package:path/path.dart' as path;

typedef ExitFn = Never Function(int code);

ExitFn exitFn = exit;

String skipVeryGoodOptimizationTag = 'skip_very_good_optimization';
RegExp skipVeryGoodOptimizationRegExp = RegExp(
  "@Tags\\s*\\(\\s*\\[[\\s\\S]*?[\"']$skipVeryGoodOptimizationTag[\"'][\\s\\S]*?\\]\\s*\\)",
  multiLine: true,
);

extension on FileSystemEntity {
  bool get isTest {
    return this is File && path.basename(this.path).endsWith('_test.dart');
  }
}

/// The `group` arguments to wrap a test file with [contents] in, or `null`
/// when the file has to run as its own suite.
String? getGroupArguments(String contents) {
  if (skipVeryGoodOptimizationRegExp.hasMatch(contents)) return null;
  return suiteGroupArguments(contents);
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

  final identifierGenerator = DartIdentifierGenerator();
  final tests = testDir
      .listSync(recursive: true)
      .where((entity) => entity.isTest)
      .toList();

  // Reading the files one at a time dominates the hook on large packages, so
  // read them all up front and inspect them in order afterwards.
  final contents = await Future.wait(
    tests.map((entity) => File(entity.path).readAsString()),
  );

  final optimizedTests = <Map<String, String>>[];
  final notOptimizedTests = <String>[];

  for (final (index, entity) in tests.indexed) {
    final relativePath = path
        .relative(entity.path, from: testDir.path)
        .replaceAll(r'\', '/');
    final groupArguments = getGroupArguments(contents[index]);

    // A test file whose behavior cannot be reproduced on a `group` has to run
    // as its own suite.
    if (groupArguments == null) {
      notOptimizedTests.add(relativePath);
      continue;
    }

    optimizedTests.add({
      'path': relativePath,
      'identifier': identifierGenerator.next(),
      'groupArguments': groupArguments,
    });
  }

  if (notOptimizedTests.isNotEmpty) {
    context.logger.detail(
      'Excluded from optimization: ${notOptimizedTests.join(', ')}',
    );
  }

  context.vars = {
    'tests': optimizedTests,
    'isFlutter': isFlutter,
    'notOptimizedTests': notOptimizedTests,
  };
}
