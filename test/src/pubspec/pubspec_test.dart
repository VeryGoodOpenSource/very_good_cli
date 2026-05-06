import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:very_good_cli/src/pubspec/pubspec.dart';

void main() {
  group('tryParsePubspec', () {
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

      final pubspec = tryParsePubspec(file);

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
      expect(tryParsePubspec(file), isNull);
    });

    test('returns null when the file contains invalid YAML', () {
      final file = File(path.join(tempDirectory.path, pubspecBasename))
        ..writeAsStringSync('invalid: yaml: content: [');
      expect(tryParsePubspec(file), isNull);
    });
  });

  group('PubspecWorkspace', () {
    test('isWorkspaceRoot is true when workspace is set', () {
      final pubspec = Pubspec.parse(_workspaceRootPubspecContent);
      expect(pubspec.isWorkspaceRoot, isTrue);
      expect(pubspec.isWorkspaceMember, isFalse);
    });

    test('isWorkspaceRoot is false when workspace is not set', () {
      final pubspec = Pubspec.parse(_basicPubspecContent);
      expect(pubspec.isWorkspaceRoot, isFalse);
    });

    test('isWorkspaceMember is true when resolution is workspace', () {
      final pubspec = Pubspec.parse(_workspaceMemberPubspecContent);
      expect(pubspec.isWorkspaceMember, isTrue);
      expect(pubspec.isWorkspaceRoot, isFalse);
    });

    test('isWorkspaceMember is false when resolution is absent', () {
      final pubspec = Pubspec.parse(_basicPubspecContent);
      expect(pubspec.isWorkspaceMember, isFalse);
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
  });

  group('collectWorkspaceDependencies', () {
    late Directory tempDirectory;

    setUp(() {
      tempDirectory = Directory.systemTemp.createTempSync();
    });

    tearDown(() {
      tempDirectory.deleteSync(recursive: true);
    });

    test('returns null when not a workspace root', () {
      final pubspec = Pubspec.parse(_basicPubspecContent);
      expect(
        pubspec.collectWorkspaceDependencies(
          root: tempDirectory,
          dependencyTypes: ['direct-main', 'direct-dev'],
        ),
        isNull,
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
      expect(
        () => pubspec.collectWorkspaceDependencies(
          root: tempDirectory,
          dependencyTypes: ['direct-main'],
        ),
        returnsNormally,
      );
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
