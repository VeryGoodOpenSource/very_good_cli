import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:very_good_cli/src/workspace/workspace.dart';

void main() {
  group('WorkspaceIntegrator', () {
    test('can be instantiated at runtime', () {
      const create = WorkspaceIntegrator.new;
      expect(create(), isA<WorkspaceIntegrator>());
    });

    late Directory root;
    late File pubspec;

    setUp(() {
      root = Directory.systemTemp.createTempSync('vg_ws_integrator_');
      pubspec = File(path.join(root.path, 'pubspec.yaml'));
    });

    tearDown(() {
      root.deleteSync(recursive: true);
    });

    Directory member(String relative) {
      return Directory(path.join(root.path, path.joinAll(relative.split('/'))));
    }

    test('adds the first member to an empty list as a block sequence', () {
      pubspec.writeAsStringSync('''
name: my_workspace
workspace: []
''');

      final added = const WorkspaceIntegrator().addPackage(
        workspaceRoot: root,
        packageDirectory: member('packages/a'),
      );

      expect(added, equals('packages/a'));
      expect(
        pubspec.readAsStringSync(),
        equals('''
name: my_workspace
workspace:
  - packages/a
'''),
      );
    });

    test('appends a member when the list is not empty', () {
      pubspec.writeAsStringSync('''
name: my_workspace
workspace:
  - packages/a
''');

      final added = const WorkspaceIntegrator().addPackage(
        workspaceRoot: root,
        packageDirectory: member('apps/b'),
      );

      expect(added, equals('apps/b'));
      expect(pubspec.readAsStringSync(), contains('  - packages/a'));
      expect(pubspec.readAsStringSync(), contains('  - apps/b'));
    });

    test('creates the workspace key when it is absent', () {
      pubspec.writeAsStringSync('name: my_workspace\n');

      final added = const WorkspaceIntegrator().addPackage(
        workspaceRoot: root,
        packageDirectory: member('packages/a'),
      );

      expect(added, equals('packages/a'));
      expect(pubspec.readAsStringSync(), contains('workspace:'));
      expect(pubspec.readAsStringSync(), contains('packages/a'));
    });

    test('treats a null workspace value as an empty list', () {
      pubspec.writeAsStringSync('''
name: my_workspace
workspace:
''');

      final added = const WorkspaceIntegrator().addPackage(
        workspaceRoot: root,
        packageDirectory: member('packages/a'),
      );

      expect(added, equals('packages/a'));
      expect(pubspec.readAsStringSync(), contains('- packages/a'));
    });

    test('preserves existing comments and formatting', () {
      pubspec.writeAsStringSync('''
name: my_workspace
# managed automatically
workspace: []
''');

      const WorkspaceIntegrator().addPackage(
        workspaceRoot: root,
        packageDirectory: member('packages/a'),
      );

      expect(pubspec.readAsStringSync(), contains('# managed automatically'));
    });

    test('returns null and makes no change when already a member', () {
      pubspec.writeAsStringSync('''
name: my_workspace
workspace:
  - packages/a
''');
      final before = pubspec.readAsStringSync();

      final added = const WorkspaceIntegrator().addPackage(
        workspaceRoot: root,
        packageDirectory: member('packages/a'),
      );

      expect(added, isNull);
      expect(pubspec.readAsStringSync(), equals(before));
    });

    test('returns null when the package is the workspace root itself', () {
      pubspec.writeAsStringSync('''
name: my_workspace
workspace: []
''');

      final added = const WorkspaceIntegrator().addPackage(
        workspaceRoot: root,
        packageDirectory: root,
      );

      expect(added, isNull);
    });

    test('returns null when the package is outside the workspace root', () {
      pubspec.writeAsStringSync('''
name: my_workspace
workspace: []
''');
      final outside = Directory(path.join(root.parent.path, 'elsewhere'));

      final added = const WorkspaceIntegrator().addPackage(
        workspaceRoot: root,
        packageDirectory: outside,
      );

      expect(added, isNull);
    });

    group('ensureWorkspaceResolution', () {
      test('adds resolution: workspace when absent', () {
        pubspec.writeAsStringSync('name: pkg\n');

        final changed = const WorkspaceIntegrator().ensureWorkspaceResolution(
          pubspec,
        );

        expect(changed, isTrue);
        expect(pubspec.readAsStringSync(), contains('resolution: workspace'));
      });

      test('is a no-op when already declared', () {
        pubspec.writeAsStringSync('name: pkg\nresolution: workspace\n');

        final changed = const WorkspaceIntegrator().ensureWorkspaceResolution(
          pubspec,
        );

        expect(changed, isFalse);
      });

      test('returns false when the pubspec does not exist', () {
        final missing = File(path.join(root.path, 'nope', 'pubspec.yaml'));
        expect(
          const WorkspaceIntegrator().ensureWorkspaceResolution(missing),
          isFalse,
        );
      });
    });

    group('addPathDependency', () {
      test('adds a path dependency under dependencies', () {
        pubspec.writeAsStringSync('''
name: app
dependencies:
  flutter:
    sdk: flutter
''');

        final added = const WorkspaceIntegrator().addPathDependency(
          appPubspec: pubspec,
          packageName: 'my_pkg',
          relativePath: '../../packages/my_pkg',
        );

        expect(added, isTrue);
        final content = pubspec.readAsStringSync();
        expect(content, contains('my_pkg:'));
        expect(content, contains('path: ../../packages/my_pkg'));
      });

      test('creates the dependencies map when missing', () {
        pubspec.writeAsStringSync('name: app\n');

        final added = const WorkspaceIntegrator().addPathDependency(
          appPubspec: pubspec,
          packageName: 'my_pkg',
          relativePath: '../my_pkg',
        );

        expect(added, isTrue);
        expect(pubspec.readAsStringSync(), contains('dependencies:'));
      });

      test('returns false when already a dependency', () {
        pubspec.writeAsStringSync('''
name: app
dependencies:
  my_pkg:
    path: ../my_pkg
''');

        final added = const WorkspaceIntegrator().addPathDependency(
          appPubspec: pubspec,
          packageName: 'my_pkg',
          relativePath: '../my_pkg',
        );

        expect(added, isFalse);
      });
    });
  });
}
