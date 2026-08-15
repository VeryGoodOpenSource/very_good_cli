import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:very_good_cli/src/workspace_matrix/workspace_matrix.dart';

void main() {
  Directory writePubspec(Directory root, String projectPath, String content) {
    final directory = Directory(path.join(root.path, projectPath))
      ..createSync(recursive: true);
    File(path.join(directory.path, 'pubspec.yaml')).writeAsStringSync(content);
    return directory;
  }

  group('resolveAffectedWorkspaceProjects', () {
    late Directory tempDirectory;

    setUp(() {
      tempDirectory = Directory.systemTemp.createTempSync();
      addTearDown(() => tempDirectory.deleteSync(recursive: true));
    });

    test('returns empty when no pubspec projects are discovered', () {
      final result = resolveAffectedWorkspaceProjects(
        rootDirectory: tempDirectory,
        changedFiles: const ['lib/main.dart'],
      );

      expect(result, isEmpty);
    });

    test('returns directly changed projects', () {
      writePubspec(tempDirectory, 'packages/a', '''
name: a
environment:
  sdk: ^3.9.0
''');
      writePubspec(tempDirectory, 'packages/b', '''
name: b
environment:
  sdk: ^3.9.0
''');

      final result = resolveAffectedWorkspaceProjects(
        rootDirectory: tempDirectory,
        changedFiles: const ['packages/b/lib/b.dart'],
      );

      expect(result, const [WorkspaceProject(name: 'b', path: 'packages/b')]);
    });

    test('propagates affected projects through path dependencies', () {
      writePubspec(tempDirectory, 'packages/core/core_library_1', '''
name: core_library_1
environment:
  sdk: ^3.9.0
''');
      writePubspec(tempDirectory, 'packages/core/core_library_2', '''
name: core_library_2
environment:
  sdk: ^3.9.0
''');
      writePubspec(tempDirectory, 'packages/features/feature_a', '''
name: feature_b
environment:
  sdk: ^3.9.0
dependencies:
  core_library_1:
    path: ../../core/core_library_1
''');
      writePubspec(tempDirectory, 'packages/features/feature_b', '''
name: feature_b
environment:
  sdk: ^3.9.0
dependencies:
  core_library_2:
    path: ../../core/core_library_2
''');
      writePubspec(tempDirectory, 'packages/features/feature_c', '''
name: feature_c
environment:
  sdk: ^3.9.0
dev_dependencies:
  feature_b:
    path: ../feature_b
''');

      final result = resolveAffectedWorkspaceProjects(
        rootDirectory: tempDirectory,
        changedFiles: const [
          'packages/core/core_library_2/lib/src/change.dart',
        ],
      );

      expect(result, const [
        WorkspaceProject(
          name: 'core_library_2',
          path: 'packages/core/core_library_2',
        ),
        WorkspaceProject(
          name: 'feature_b',
          path: 'packages/features/feature_b',
        ),
        WorkspaceProject(
          name: 'feature_c',
          path: 'packages/features/feature_c',
        ),
      ]);
    });

    test('maps a changed file to the deepest matching project', () {
      writePubspec(tempDirectory, '.', '''
name: app
environment:
  sdk: ^3.9.0
''');
      writePubspec(tempDirectory, 'packages/core', '''
name: core
environment:
  sdk: ^3.9.0
''');

      final childChange = resolveAffectedWorkspaceProjects(
        rootDirectory: tempDirectory,
        changedFiles: const ['packages/core/lib/core.dart'],
      );
      final rootChange = resolveAffectedWorkspaceProjects(
        rootDirectory: tempDirectory,
        changedFiles: const ['lib/main.dart'],
      );

      expect(childChange, const [
        WorkspaceProject(name: 'core', path: 'packages/core'),
      ]);
      expect(rootChange, const [WorkspaceProject(name: 'app', path: '.')]);
    });
  });
}
