// ignore_for_file: public_member_api_docs

import 'dart:io';

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

  final identifierGenerator = StringIdGenerator();
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

/// {@template string_id_generator}
/// A class that generates short identifiers.
/// {@endtemplate}
class StringIdGenerator {
  /// {@macro string_id_generator}
  StringIdGenerator([
    this._chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ',
  ]) : _nextId = [0];

  final String _chars;
  final List<int> _nextId;

  /// Generate the next short identifier.
  String next() {
    final r = <String>[for (final char in _nextId) _chars[char]];
    _increment();
    return r.join();
  }

  void _increment() {
    for (var i = 0; i < _nextId.length; i++) {
      final val = ++_nextId[i];
      if (val >= _chars.length) {
        _nextId[i] = 0;
      } else {
        return;
      }
    }
    _nextId.add(0);
  }
}
