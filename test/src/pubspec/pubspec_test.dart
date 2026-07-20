import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:very_good_cli/src/pubspec/pubspec.dart';

void main() {
  group('PubspecWorkspace.tryParse', () {
    late Directory tempDirectory;

    setUp(() {
      tempDirectory = Directory.systemTemp.createTempSync();
    });

    tearDown(() {
      tempDirectory.deleteSync(recursive: true);
    });

    test('returns a Pubspec when the file exists and is valid', () {
      final file = File(path.join(tempDirectory.path, pubspecBasename))
        ..writeAsStringSync(_basicPubspecContent);

      final pubspec = PubspecWorkspace.tryParse(file);

      expect(pubspec, isNotNull);
      expect(pubspec!.name, equals('test_package'));
      expect(pubspec.dependencies.keys, containsAll(<String>['foo', 'bar']));
      expect(
        pubspec.devDependencies.keys,
        containsAll(<String>['test', 'mocktail']),
      );
    });

    test('returns null when the file does not exist', () {
      final file = File(path.join(tempDirectory.path, 'missing.yaml'));
      expect(PubspecWorkspace.tryParse(file), isNull);
    });

    test('returns null when the file contains invalid YAML', () {
      final file = File(path.join(tempDirectory.path, pubspecBasename))
        ..writeAsStringSync('invalid: yaml: content: [');
      expect(PubspecWorkspace.tryParse(file), isNull);
    });

    test(
      'returns null when YAML is valid but the pubspec is structurally invalid',
      () {
        final file = File(path.join(tempDirectory.path, pubspecBasename))
          ..writeAsStringSync('''
environment:
  sdk: ^3.0.0
dependencies:
  foo: ^1.0.0
''');
        expect(PubspecWorkspace.tryParse(file), isNull);
      },
    );
  });

  group('PubspecWorkspace', () {
    test('isWorkspaceRoot is true when workspace is set', () {
      final pubspec = Pubspec.parse(_workspaceRootPubspecContent);
      expect(pubspec.isWorkspaceRoot, isTrue);
    });

    test('isWorkspaceRoot is false when workspace is not set', () {
      final pubspec = Pubspec.parse(_basicPubspecContent);
      expect(pubspec.isWorkspaceRoot, isFalse);
    });
  });

  group('resolveMembers', () {
    late Directory tempDirectory;

    setUp(() {
      tempDirectory = Directory.systemTemp.createTempSync();
    });

    tearDown(() {
      tempDirectory.deleteSync(recursive: true);
    });

    test('returns empty list when not a workspace root', () {
      final pubspec = Pubspec.parse(_basicPubspecContent);
      expect(pubspec.resolveMembers(tempDirectory), isEmpty);
    });

    test('resolves direct path members correctly', () {
      final appDir = Directory(path.join(tempDirectory.path, 'packages/app'))
        ..createSync(recursive: true);
      File(
        path.join(appDir.path, pubspecBasename),
      ).writeAsStringSync(_workspaceMemberPubspecContent);

      final sharedDir = Directory(
        path.join(tempDirectory.path, 'packages/shared'),
      )..createSync(recursive: true);
      File(
        path.join(sharedDir.path, pubspecBasename),
      ).writeAsStringSync(_workspaceMemberPubspecContent);

      final pubspec = Pubspec.parse(_workspaceRootPubspecContent);
      final members = pubspec.resolveMembers(tempDirectory);

      expect(members.length, equals(2));
      expect(members.map((d) => path.basename(d.path)), contains('app'));
      expect(members.map((d) => path.basename(d.path)), contains('shared'));
    });

    test('ignores directories without pubspec.yaml for glob patterns', () {
      final validDir = Directory(
        path.join(tempDirectory.path, 'packages/valid'),
      )..createSync(recursive: true);
      File(
        path.join(validDir.path, pubspecBasename),
      ).writeAsStringSync(_workspaceMemberPubspecContent);

      // Create a directory without pubspec.yaml
      Directory(
        path.join(tempDirectory.path, 'packages/invalid'),
      ).createSync(recursive: true);

      final pubspec = Pubspec.parse(_workspaceWithGlobPubspecContent);
      final members = pubspec.resolveMembers(tempDirectory);

      expect(members.length, equals(1));
      expect(path.basename(members.first.path), equals('valid'));
    });

    test('skips non-existent direct path members', () {
      final pubspec = Pubspec.parse(_workspaceRootPubspecContent);
      final members = pubspec.resolveMembers(tempDirectory);
      expect(members, isEmpty);
    });

    test('resolves glob pattern matching pubspec.yaml files directly', () {
      final memberDir = Directory(
        path.join(tempDirectory.path, 'packages/member'),
      )..createSync(recursive: true);
      File(
        path.join(memberDir.path, pubspecBasename),
      ).writeAsStringSync(_workspaceMemberPubspecContent);

      final pubspec = Pubspec.parse(_workspaceWithFileGlobPubspecContent);
      final members = pubspec.resolveMembers(tempDirectory);

      expect(members.length, equals(1));
      expect(path.basename(members.first.path), equals('member'));
    });

    test('resolves `?` single-character glob patterns', () {
      for (final name in ['appA', 'appAB']) {
        final memberDir = Directory(
          path.join(tempDirectory.path, 'packages', name),
        )..createSync(recursive: true);
        File(
          path.join(memberDir.path, pubspecBasename),
        ).writeAsStringSync(_workspaceMemberPubspecContent);
      }

      final pubspec = Pubspec.parse('''
name: workspace_root
environment:
  sdk: ^3.6.0
workspace:
  - packages/app?
''');
      final members = pubspec.resolveMembers(tempDirectory);

      expect(members.length, equals(1));
      expect(path.basename(members.first.path), equals('appA'));
    });

    test('resolves `[...]` character class glob patterns', () {
      final memberDir = Directory(path.join(tempDirectory.path, 'packages/app'))
        ..createSync(recursive: true);
      File(
        path.join(memberDir.path, pubspecBasename),
      ).writeAsStringSync(_workspaceMemberPubspecContent);

      final pubspec = Pubspec.parse('''
name: workspace_root
environment:
  sdk: ^3.6.0
workspace:
  - packages/[abc]pp
''');
      final members = pubspec.resolveMembers(tempDirectory);

      expect(members.length, equals(1));
      expect(path.basename(members.first.path), equals('app'));
    });

    test('resolves `{...}` alternation glob patterns', () {
      for (final name in ['app', 'shared', 'other']) {
        final memberDir = Directory(
          path.join(tempDirectory.path, 'packages', name),
        )..createSync(recursive: true);
        File(
          path.join(memberDir.path, pubspecBasename),
        ).writeAsStringSync(_workspaceMemberPubspecContent);
      }

      final pubspec = Pubspec.parse('''
name: workspace_root
environment:
  sdk: ^3.6.0
workspace:
  - packages/{app,shared}
''');
      final members = pubspec.resolveMembers(tempDirectory);

      expect(
        members.map((d) => path.basename(d.path)),
        unorderedEquals(<String>['app', 'shared']),
      );
    });

    test('resolves literal paths whose names contain non-metachar symbols', () {
      final memberDir = Directory(
        path.join(tempDirectory.path, 'packages', '!special'),
      )..createSync(recursive: true);
      File(
        path.join(memberDir.path, pubspecBasename),
      ).writeAsStringSync(_workspaceMemberPubspecContent);

      final pubspec = Pubspec.parse('''
name: workspace_root
environment:
  sdk: ^3.6.0
workspace:
  - packages/!special
''');
      final members = pubspec.resolveMembers(tempDirectory);

      expect(members.length, equals(1));
      expect(path.basename(members.first.path), equals('!special'));
    });
  });

  group('collectWorkspaceDependencies', () {
    late Directory tempDirectory;

    setUp(() {
      tempDirectory = Directory.systemTemp.createTempSync();
    });

    tearDown(() {
      tempDirectory.deleteSync(recursive: true);
    });

    test('returns an empty set when not a workspace root', () {
      final pubspec = Pubspec.parse(_basicPubspecContent);
      expect(
        pubspec.collectWorkspaceDependencies(
          root: tempDirectory,
          dependencyTypes: ['direct-main', 'direct-dev'],
        ),
        isEmpty,
      );
    });

    test('collects direct-main deps from root and members', () {
      final memberDir = Directory(
        path.join(tempDirectory.path, 'packages/app'),
      )..createSync(recursive: true);
      File(
        path.join(memberDir.path, pubspecBasename),
      ).writeAsStringSync(_workspaceMemberPubspecContent);

      final pubspec = Pubspec.parse(_workspaceRootWithMemberPubspecContent);
      final deps = pubspec.collectWorkspaceDependencies(
        root: tempDirectory,
        dependencyTypes: ['direct-main'],
      );

      expect(deps, isNotNull);
      expect(deps, containsAll(<String>['http', 'shared']));
    });

    test('collects direct-dev deps from root and members', () {
      final memberDir = Directory(
        path.join(tempDirectory.path, 'packages/app'),
      )..createSync(recursive: true);
      File(
        path.join(memberDir.path, pubspecBasename),
      ).writeAsStringSync(_workspaceMemberPubspecContent);

      final pubspec = Pubspec.parse(_workspaceRootWithMemberPubspecContent);
      final deps = pubspec.collectWorkspaceDependencies(
        root: tempDirectory,
        dependencyTypes: ['direct-dev'],
      );

      expect(deps, isNotNull);
      expect(deps, contains('test'));
    });

    test(
      'merges dep from direct-main in one member and direct-dev in another',
      () {
        final appDir = Directory(
          path.join(tempDirectory.path, 'packages/app'),
        )..createSync(recursive: true);
        File(path.join(appDir.path, pubspecBasename)).writeAsStringSync('''
name: app
environment:
  sdk: ^3.6.0
resolution: workspace
dependencies:
  shared_pkg: ^1.0.0
''');

        final libDir = Directory(
          path.join(tempDirectory.path, 'packages/lib'),
        )..createSync(recursive: true);
        File(path.join(libDir.path, pubspecBasename)).writeAsStringSync('''
name: lib
environment:
  sdk: ^3.6.0
resolution: workspace
dev_dependencies:
  shared_pkg: ^1.0.0
''');

        final pubspec = Pubspec.parse('''
name: workspace_root
environment:
  sdk: ^3.6.0
workspace:
  - packages/app
  - packages/lib
''');
        final deps = pubspec.collectWorkspaceDependencies(
          root: tempDirectory,
          dependencyTypes: ['direct-main', 'direct-dev'],
        );

        // shared_pkg is included because it appears in at least one member
        expect(deps, isNotNull);
        expect(deps, contains('shared_pkg'));
      },
    );

    test('collects deps from members that omit `resolution: workspace`', () {
      final memberDir = Directory(
        path.join(tempDirectory.path, 'packages/app'),
      )..createSync(recursive: true);
      File(path.join(memberDir.path, pubspecBasename)).writeAsStringSync('''
name: app
environment:
  sdk: ^3.6.0
dependencies:
  http: ^1.0.0
''');

      final pubspec = Pubspec.parse(_workspaceRootWithMemberPubspecContent);
      final deps = pubspec.collectWorkspaceDependencies(
        root: tempDirectory,
        dependencyTypes: ['direct-main'],
      );

      expect(deps, contains('http'));
    });

    test('prevents infinite recursion from circular workspace references', () {
      // Set up a workspace root pointing to a member that points back
      final memberDir = Directory(
        path.join(tempDirectory.path, 'packages/app'),
      )..createSync(recursive: true);

      File(path.join(memberDir.path, pubspecBasename)).writeAsStringSync('''
name: app
environment:
  sdk: ^3.6.0
workspace:
  - ../..
dependencies:
  http: ^1.0.0
''');

      final pubspec = Pubspec.parse(_workspaceRootWithMemberPubspecContent);
      late final Set<String> deps;
      expect(
        () => deps = pubspec.collectWorkspaceDependencies(
          root: tempDirectory,
          dependencyTypes: ['direct-main'],
        ),
        returnsNormally,
      );

      // The cycling member's dependency is still collected and the call
      // returns, proving the traversal terminated rather than looping on the
      // circular reference.
      expect(deps, contains('http'));
    });
  });
}

/// A basic pubspec.yaml content with dependencies.
const _basicPubspecContent = '''
name: test_package

environment:
  sdk: ^3.0.0

dependencies:
  foo: ^1.0.0
  bar: ^2.0.0

dev_dependencies:
  test: ^1.0.0
  mocktail: ^1.0.0
''';

/// A workspace root pubspec.yaml content.
const _workspaceRootPubspecContent = '''
name: workspace_root

environment:
  sdk: ^3.6.0

workspace:
  - packages/app
  - packages/shared
''';

/// A workspace root pubspec.yaml with a single member.
const _workspaceRootWithMemberPubspecContent = '''
name: workspace_root

environment:
  sdk: ^3.6.0

workspace:
  - packages/app
''';

/// A workspace member pubspec.yaml content.
const _workspaceMemberPubspecContent = '''
name: workspace_member

environment:
  sdk: ^3.6.0

resolution: workspace

dependencies:
  http: ^1.0.0
  shared: ^1.0.0

dev_dependencies:
  test: ^1.0.0
''';

/// A workspace pubspec.yaml with glob pattern.
const _workspaceWithGlobPubspecContent = '''
name: workspace_glob

environment:
  sdk: ^3.6.0

workspace:
  - packages/*
''';

/// A workspace pubspec.yaml with glob pattern that matches pubspec.yaml files.
const _workspaceWithFileGlobPubspecContent = '''
name: workspace_file_glob

environment:
  sdk: ^3.6.0

workspace:
  - packages/*/pubspec.yaml
''';
