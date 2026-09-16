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

  final identifierGenerator = DartIdentifierGenerator();
  final optimizedTests = <Map<String, String>>[];
  final notOptimizedTests = <String>[];

  final tests = testDir
      .listSync(recursive: true)
      .where((entity) => entity.isTest)
      .cast<File>();
  final parsedTests = await Future.wait(tests.map(_parse));

  for (final (file, content, metadata) in parsedTests) {
    final relativePath = path
        .relative(file.path, from: testDir.path)
        .replaceAll(r'\', '/');

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

typedef _ParsedTest = (File file, String content, TestMetadata metadata);

Future<_ParsedTest> _parse(File file) async {
  final content = await file.readAsString();
  return (file, content, parseTestMetadata(content, path: file.path));
}

extension on FileSystemEntity {
  bool get isTest {
    return this is File && path.basename(this.path).endsWith('_test.dart');
  }
}
