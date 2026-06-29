import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:very_good_cli/src/workspace/workspace.dart';

void main() {
  group('WorkspaceDetector', () {
    test('can be instantiated at runtime', () {
      const create = WorkspaceDetector.new;
      expect(create(), isA<WorkspaceDetector>());
    });

    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('vg_ws_detector_');
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    void writePubspec(Directory dir, String contents) {
      Directory(dir.path).createSync(recursive: true);
      File(path.join(dir.path, 'pubspec.yaml')).writeAsStringSync(contents);
    }

    test('returns null when no pubspec is found in any ancestor', () {
      final nested = Directory(path.join(tempDir.path, 'a', 'b'))
        ..createSync(recursive: true);

      expect(const WorkspaceDetector().detect(nested), isNull);
    });

    test('returns null when the nearest pubspec is not a workspace', () {
      writePubspec(tempDir, 'name: solo\n');

      expect(const WorkspaceDetector().detect(tempDir), isNull);
    });

    test('detects the workspace from the root directory itself', () {
      writePubspec(tempDir, '''
name: my_workspace
workspace:
  - packages/a
  - apps/b
''');

      final context = const WorkspaceDetector().detect(tempDir);

      expect(context, isNotNull);
      expect(path.equals(context!.rootPath, tempDir.path), isTrue);
      expect(context.members, equals(['packages/a', 'apps/b']));
    });

    test('walks up from a nested directory to the workspace root', () {
      writePubspec(tempDir, '''
name: my_workspace
workspace:
  - packages/a
''');
      final nested = Directory(path.join(tempDir.path, 'packages', 'a', 'lib'))
        ..createSync(recursive: true);

      final context = const WorkspaceDetector().detect(nested);

      expect(context, isNotNull);
      expect(path.equals(context!.rootPath, tempDir.path), isTrue);
    });

    test('skips a member pubspec and resolves to the root', () {
      writePubspec(tempDir, '''
name: my_workspace
workspace:
  - packages/a
''');
      final member = Directory(path.join(tempDir.path, 'packages', 'a'));
      writePubspec(member, '''
name: a
resolution: workspace
''');

      final context = const WorkspaceDetector().detect(member);

      expect(context, isNotNull);
      expect(path.equals(context!.rootPath, tempDir.path), isTrue);
    });

    test('treats a non-list workspace value as no members', () {
      writePubspec(tempDir, '''
name: my_workspace
workspace:
''');

      final context = const WorkspaceDetector().detect(tempDir);

      expect(context, isNotNull);
      expect(context!.members, isEmpty);
    });
  });
}
