// Ensures we don't have to use const constructors
// and instances are created at runtime.
// ignore_for_file: prefer_const_constructors

import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:very_good_cli/src/pubspec/pubspec.dart';

void main() {
  group('$Pubspec', () {
    group('fromString', () {
      test('parses basic pubspec correctly', () {
        final pubspec = Pubspec.fromString(_basicPubspecContent);

        expect(pubspec.name, equals('test_package'));
        expect(pubspec.dependencies, equals(['foo', 'bar']));
        expect(pubspec.devDependencies, equals(['test', 'mocktail']));
        expect(pubspec.workspace, isNull);
        expect(pubspec.resolution, isNull);
        expect(pubspec.isWorkspaceRoot, isFalse);
        expect(pubspec.isWorkspaceMember, isFalse);
      });

      test('parses workspace root pubspec correctly', () {
        final pubspec = Pubspec.fromString(_workspaceRootPubspecContent);

        expect(pubspec.name, equals('workspace_root'));
        expect(pubspec.dependencies, isEmpty);
        expect(pubspec.devDependencies, isEmpty);
        expect(pubspec.workspace, equals(['packages/app', 'packages/shared']));
        expect(pubspec.resolution, isNull);
        expect(pubspec.isWorkspaceRoot, isTrue);
        expect(pubspec.isWorkspaceMember, isFalse);
      });

      test('parses workspace member pubspec correctly', () {
        final pubspec = Pubspec.fromString(_workspaceMemberPubspecContent);

        expect(pubspec.name, equals('workspace_member'));
        expect(pubspec.dependencies, equals(['http', 'shared']));
        expect(pubspec.devDependencies, equals(['test']));
        expect(pubspec.workspace, isNull);
        expect(pubspec.resolution, equals(PubspecResolution.workspace));
        expect(pubspec.isWorkspaceRoot, isFalse);
        expect(pubspec.isWorkspaceMember, isTrue);
      });

      test('parses workspace with glob pattern correctly', () {
        final pubspec = Pubspec.fromString(_workspaceWithGlobPubspecContent);

        expect(pubspec.workspace, equals(['packages/*']));
        expect(pubspec.isWorkspaceRoot, isTrue);
      });

      test('parses pubspec with no dependencies correctly', () {
        final pubspec = Pubspec.fromString(_noDependenciesPubspecContent);

        expect(pubspec.name, equals('no_deps'));
        expect(pubspec.dependencies, isEmpty);
        expect(pubspec.devDependencies, isEmpty);
      });

      test('throws $PubspecParseException when content is empty', () {
        expect(
          () => Pubspec.fromString(''),
          throwsA(isA<PubspecParseException>()),
        );
      });

      test('throws $PubspecParseException when content is invalid YAML', () {
        expect(
          () => Pubspec.fromString('invalid: yaml: content: ['),
          throwsA(isA<PubspecParseException>()),
        );
      });

      test('handles missing name gracefully', () {
        final pubspec = Pubspec.fromString('dependencies:\n  foo: ^1.0.0');
        expect(pubspec.name, equals(''));
      });
    });

    group('fromFile', () {
      late Directory tempDirectory;

      setUp(() {
        tempDirectory = Directory.systemTemp.createTempSync();
      });

      tearDown(() {
        tempDirectory.deleteSync(recursive: true);
      });

      test('parses file correctly', () {
        final pubspecFile = File(path.join(tempDirectory.path, 'pubspec.yaml'))
          ..writeAsStringSync(_basicPubspecContent);

        final pubspec = Pubspec.fromFile(pubspecFile);

        expect(pubspec.name, equals('test_package'));
        expect(pubspec.dependencies, equals(['foo', 'bar']));
      });

      test('throws $PubspecParseException when file does not exist', () {
        final nonExistentFile = File(
          path.join(tempDirectory.path, 'nonexistent.yaml'),
        );

        expect(
          () => Pubspec.fromFile(nonExistentFile),
          throwsA(isA<PubspecParseException>()),
        );
      });
    });

    group('resolveWorkspaceMembers', () {
      late Directory tempDirectory;

      setUp(() {
        tempDirectory = Directory.systemTemp.createTempSync();
      });

      tearDown(() {
        tempDirectory.deleteSync(recursive: true);
      });

      test('returns empty list when not a workspace root', () {
        final pubspec = Pubspec.fromString(_basicPubspecContent);
        final members = pubspec.resolveWorkspaceMembers(tempDirectory);
        expect(members, isEmpty);
      });

      test('resolves direct path members correctly', () {
        // Create workspace structure
        final appDir = Directory(path.join(tempDirectory.path, 'packages/app'))
          ..createSync(recursive: true);
        File(
          path.join(appDir.path, 'pubspec.yaml'),
        ).writeAsStringSync(_workspaceMemberPubspecContent);

        final sharedDir = Directory(
          path.join(tempDirectory.path, 'packages/shared'),
        )..createSync(recursive: true);
        File(
          path.join(sharedDir.path, 'pubspec.yaml'),
        ).writeAsStringSync(_workspaceMemberPubspecContent);

        final pubspec = Pubspec.fromString(_workspaceRootPubspecContent);
        final members = pubspec.resolveWorkspaceMembers(tempDirectory);

        expect(members.length, equals(2));
        expect(members.map((d) => path.basename(d.path)), contains('app'));
        expect(members.map((d) => path.basename(d.path)), contains('shared'));
      });

      test('ignores directories without pubspec.yaml for glob patterns', () {
        // Create workspace structure with one valid and one invalid member
        final validDir = Directory(
          path.join(tempDirectory.path, 'packages/valid'),
        )..createSync(recursive: true);
        File(
          path.join(validDir.path, 'pubspec.yaml'),
        ).writeAsStringSync(_workspaceMemberPubspecContent);

        // Create a directory without pubspec.yaml
        Directory(
          path.join(tempDirectory.path, 'packages/invalid'),
        ).createSync(recursive: true);

        final pubspec = Pubspec.fromString(_workspaceWithGlobPubspecContent);
        final members = pubspec.resolveWorkspaceMembers(tempDirectory);

        expect(members.length, equals(1));
        expect(path.basename(members.first.path), equals('valid'));
      });

      test('skips non-existent direct path members', () {
        // Don't create any directories
        final pubspec = Pubspec.fromString(_workspaceRootPubspecContent);
        final members = pubspec.resolveWorkspaceMembers(tempDirectory);

        expect(members, isEmpty);
      });

      test('resolves glob pattern matching pubspec.yaml files directly', () {
        // Create workspace structure
        final memberDir = Directory(
          path.join(tempDirectory.path, 'packages/member'),
        )..createSync(recursive: true);
        File(
          path.join(memberDir.path, 'pubspec.yaml'),
        ).writeAsStringSync(_workspaceMemberPubspecContent);

        // Use a glob pattern that matches pubspec.yaml files directly
        final pubspec = Pubspec.fromString(
          _workspaceWithFileGlobPubspecContent,
        );
        final members = pubspec.resolveWorkspaceMembers(tempDirectory);

        expect(members.length, equals(1));
        expect(path.basename(members.first.path), equals('member'));
      });
    });
  });

  group('$PubspecParseException', () {
    test('toString returns message when provided', () {
      final exception = PubspecParseException('test message');
      expect(
        exception.toString(),
        equals('PubspecParseException: test message'),
      );
    });

    test('toString returns class name when no message', () {
      final exception = PubspecParseException();
      expect(exception.toString(), equals('PubspecParseException'));
    });
  });

  group('$PubspecResolution', () {
    group('tryParse', () {
      test('parses workspace correctly', () {
        expect(
          PubspecResolution.tryParse('workspace'),
          equals(PubspecResolution.workspace),
        );
      });

      test('parses external correctly', () {
        expect(
          PubspecResolution.tryParse('external'),
          equals(PubspecResolution.external),
        );
      });

      test('returns null for invalid value', () {
        expect(PubspecResolution.tryParse('invalid'), isNull);
      });
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

/// A pubspec.yaml with no dependencies.
const _noDependenciesPubspecContent = '''
name: no_deps

environment:
  sdk: ^3.0.0
''';

/// A workspace pubspec.yaml with glob pattern that matches pubspec.yaml files.
const _workspaceWithFileGlobPubspecContent = '''
name: workspace_file_glob

environment:
  sdk: ^3.6.0

workspace:
  - packages/*/pubspec.yaml
''';
