import 'dart:io';

import 'package:mason/mason.dart';
import 'package:path/path.dart' as path;

Future<void> run(HookContext context) async {
  final packageRoot = context.vars['package-root'];
  final testDir = Directory(path.join(packageRoot, 'test'));

  if (!testDir.existsSync()) {
    context.logger.err('Could not find directory ${testDir.path}');
    exit(1);
  }

  final pubspec = File(path.join(packageRoot, 'pubspec.yaml'));
  if (!pubspec.existsSync()) {
    context.logger.err('Could not find pubspec.yaml at ${testDir.path}');
    exit(1);
  }

  final pubspecContents = await pubspec.readAsString();
  final flutterSdkRegExp = RegExp(r'sdk:\s*flutter$', multiLine: true);
  final isFlutter = flutterSdkRegExp.hasMatch(pubspecContents);

  final tests = testDir
      .listSync(recursive: true)
      .where((entity) => entity.isTest)
      .map((entity) =>
          path.relative(entity.path, from: testDir.path).replaceAll(r'\', '/'))
      .toList();

  context.vars = {'tests': tests, 'isFlutter': isFlutter};
}

extension on FileSystemEntity {
  bool get isTest {
    return this is File && path.basename(this.path).endsWith('_test.dart');
  }
}
