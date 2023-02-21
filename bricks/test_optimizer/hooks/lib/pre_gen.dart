// ignore_for_file: public_member_api_docs

import 'dart:io';

import 'package:hooks/dart_identifier_generator.dart';
import 'package:mason/mason.dart';
import 'package:path/path.dart' as path;

typedef ExitFn = Never Function(int code);

ExitFn exitFn = exit;

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
  for (final entity
      in testDir.listSync(recursive: true).where((entity) => entity.isTest)) {
    final relativePath =
        path.relative(entity.path, from: testDir.path).replaceAll(r'\', '/');
    testIdentifierTable.add({
      'path': relativePath,
      'identifier': identifierGenerator.next(),
    });
  }

  context.vars = {'tests': testIdentifierTable, 'isFlutter': isFlutter};
}

extension on FileSystemEntity {
  bool get isTest {
    return this is File && path.basename(this.path).endsWith('_test.dart');
  }
}
