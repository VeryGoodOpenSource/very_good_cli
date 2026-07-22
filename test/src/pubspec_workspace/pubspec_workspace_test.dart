import 'dart:io';

import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:very_good_cli/src/pubspec/pubspec.dart';
import 'package:very_good_cli/src/pubspec_workspace/pubspec_workspace.dart';

class _MockLogger extends Mock implements Logger {}

void main() {
  /// Writes a `pubspec.yaml` with [content] into a subdirectory [name]
  /// (which maybe a nested path) of [root], creating directories as needed.
  Directory writePubspec(Directory root, String name, String content) {
    final directory = Directory(
      path.join(root.path, name),
    )..createSync(recursive: true);
    File(path.join(directory.path, 'pubspec.yaml')).writeAsStringSync(content);
    return directory;
  }

  group('resolveWorkspaceDependencies', () {
    late Directory tempDirectory;
    late Logger logger;

    setUp(() {
      tempDirectory = Directory.systemTemp.createTempSync();
      addTearDown(() => tempDirectory.deleteSync(recursive: true));
      logger = _MockLogger();
    });

    test('returns null when the root pubspec.yaml is missing', () {
      final result = resolveWorkspaceDependencies(
        tempDirectory,
        logger: logger,
      );

      expect(result, isNull);
      verifyNever(() => logger.warn(any()));
    });

    test('returns null and warns when the root pubspec is unparseable', () {
      File(
        path.join(tempDirectory.path, 'pubspec.yaml'),
      ).writeAsStringSync('{{{ not valid yaml');

      final result = resolveWorkspaceDependencies(
        tempDirectory,
        logger: logger,
      );

      expect(result, isNull);
      verify(() => logger.warn(any())).called(1);
    });

    test('returns null for a non-workspace package (no workspace key)', () {
      writePubspec(tempDirectory, '.', '''
name: single_package
environment:
  sdk: ^3.11.0
dependencies:
  path: ^1.9.0
''');

      final result = resolveWorkspaceDependencies(
        tempDirectory,
        logger: logger,
      );

      expect(result, isNull);
      verifyNever(() => logger.warn(any()));
    });

    test(
      'returns null for a non-list workspace key (treated as non-workspace)',
      () {
        writePubspec(tempDirectory, '.', '''
name: workspace_root
environment:
  sdk: ^3.11.0
workspace: not-a-list
''');

        final result = resolveWorkspaceDependencies(
          tempDirectory,
          logger: logger,
        );

        expect(result, isNull);
      },
    );

    test('returns null for an empty workspace list', () {
      writePubspec(tempDirectory, '.', '''
name: workspace_root
environment:
  sdk: ^3.11.0
workspace: []
''');

      final result = resolveWorkspaceDependencies(
        tempDirectory,
        logger: logger,
      );

      expect(result, isNull);
    });

    test("unions members' direct deps under direct-main and direct-dev", () {
      writePubspec(tempDirectory, '.', '''
name: workspace_root
environment:
  sdk: ^3.11.0
workspace:
  - app
  - packages/pkg_a
''');
      writePubspec(tempDirectory, 'app', '''
name: app
resolution: workspace
environment:
  sdk: ^3.11.0
dependencies:
  path: ^1.9.0
dev_dependencies:
  test: ^1.24.0
''');
      writePubspec(tempDirectory, 'packages/pkg_a', '''
name: pkg_a
resolution: workspace
environment:
  sdk: ^3.11.0
dependencies:
  collection: ^1.18.0
''');

      final result = resolveWorkspaceDependencies(
        tempDirectory,
        logger: logger,
      );

      expect(result, {
        'path': PubspecDependencyType.directMain,
        'collection': PubspecDependencyType.directMain,
        'test': PubspecDependencyType.directDev,
      });
      verifyNever(() => logger.warn(any()));
    });

    test("includes the root's own dependencies in the union", () {
      writePubspec(tempDirectory, '.', '''
name: workspace_root
environment:
  sdk: ^3.11.0
dependencies:
  args: ^2.4.0
dev_dependencies:
  build_runner: ^2.4.0
dependency_overrides:
  meta: ^1.9.0
workspace:
  - app
''');
      writePubspec(tempDirectory, 'app', '''
name: app
resolution: workspace
environment:
  sdk: ^3.11.0
dependencies:
  path: ^1.9.0
''');

      final result = resolveWorkspaceDependencies(
        tempDirectory,
        logger: logger,
      );

      expect(result, {
        'args': PubspecDependencyType.directMain,
        'path': PubspecDependencyType.directMain,
        'build_runner': PubspecDependencyType.directDev,
        'meta': PubspecDependencyType.directOverridden,
      });
    });

    test(
      'resolves a cross-member type conflict via precedence main > dev',
      () {
        writePubspec(tempDirectory, '.', '''
name: workspace_root
environment:
  sdk: ^3.11.0
workspace:
  - app
  - packages/pkg_a
''');
        writePubspec(tempDirectory, 'app', '''
name: app
resolution: workspace
environment:
  sdk: ^3.11.0
dependencies:
  shared: ^1.0.0
''');
        writePubspec(tempDirectory, 'packages/pkg_a', '''
name: pkg_a
resolution: workspace
environment:
  sdk: ^3.11.0
dev_dependencies:
  shared: ^1.0.0
''');

        final result = resolveWorkspaceDependencies(
          tempDirectory,
          logger: logger,
        );

        expect(
          result!['shared'],
          PubspecDependencyType.directMain,
        );
      },
    );

    test(
      'resolves a cross-member type conflict via precedence dev > overridden',
      () {
        writePubspec(tempDirectory, '.', '''
name: workspace_root
environment:
  sdk: ^3.11.0
workspace:
  - app
  - packages/pkg_a
''');
        writePubspec(tempDirectory, 'app', '''
name: app
resolution: workspace
environment:
  sdk: ^3.11.0
dev_dependencies:
  shared: ^1.0.0
''');
        writePubspec(tempDirectory, 'packages/pkg_a', '''
name: pkg_a
resolution: workspace
environment:
  sdk: ^3.11.0
dependency_overrides:
  shared: ^1.0.0
''');

        final result = resolveWorkspaceDependencies(
          tempDirectory,
          logger: logger,
        );

        expect(
          result!['shared'],
          PubspecDependencyType.directDev,
        );
      },
    );

    test(
      'resolves a cross-member type conflict via precedence main > overridden',
      () {
        writePubspec(tempDirectory, '.', '''
name: workspace_root
environment:
  sdk: ^3.11.0
workspace:
  - app
  - packages/pkg_a
''');
        writePubspec(tempDirectory, 'app', '''
name: app
resolution: workspace
environment:
  sdk: ^3.11.0
dependencies:
  shared: ^1.0.0
''');
        writePubspec(tempDirectory, 'packages/pkg_a', '''
name: pkg_a
resolution: workspace
environment:
  sdk: ^3.11.0
dependency_overrides:
  shared: ^1.0.0
''');

        final result = resolveWorkspaceDependencies(
          tempDirectory,
          logger: logger,
        );

        expect(
          result!['shared'],
          PubspecDependencyType.directMain,
        );
      },
    );

    test('resolves a two-level nested workspace', () {
      writePubspec(tempDirectory, '.', '''
name: workspace_root
environment:
  sdk: ^3.11.0
workspace:
  - app
''');
      writePubspec(tempDirectory, 'app', '''
name: app
resolution: workspace
environment:
  sdk: ^3.11.0
dependencies:
  path: ^1.9.0
workspace:
  - nested
''');
      writePubspec(tempDirectory, 'app/nested', '''
name: nested
resolution: workspace
environment:
  sdk: ^3.11.0
dependencies:
  collection: ^1.18.0
''');

      final result = resolveWorkspaceDependencies(
        tempDirectory,
        logger: logger,
      );

      expect(result, {
        'path': PubspecDependencyType.directMain,
        'collection': PubspecDependencyType.directMain,
      });
    });

    test('terminates on a cyclic / self-referential workspace graph', () {
      writePubspec(tempDirectory, '.', '''
name: workspace_root
environment:
  sdk: ^3.11.0
workspace:
  - app
''');
      // The member points back at itself, forming a cycle.
      writePubspec(tempDirectory, 'app', '''
name: app
resolution: workspace
environment:
  sdk: ^3.11.0
dependencies:
  path: ^1.9.0
workspace:
  - .
''');

      final result = resolveWorkspaceDependencies(
        tempDirectory,
        logger: logger,
      );

      expect(result, {'path': PubspecDependencyType.directMain});
    });

    test('counts a member reached through overlapping entries once', () {
      writePubspec(tempDirectory, '.', '''
name: workspace_root
environment:
  sdk: ^3.11.0
workspace:
  - packages/pkg_a
  - packages/*
''');
      writePubspec(tempDirectory, 'packages/pkg_a', '''
name: pkg_a
resolution: workspace
environment:
  sdk: ^3.11.0
dependencies:
  path: ^1.9.0
''');

      final result = resolveWorkspaceDependencies(
        tempDirectory,
        logger: logger,
      );

      expect(result, {'path': PubspecDependencyType.directMain});
    });

    test('expands a glob workspace entry to matching member directories', () {
      writePubspec(tempDirectory, '.', '''
name: workspace_root
environment:
  sdk: ^3.11.0
workspace:
  - packages/*
''');
      writePubspec(tempDirectory, 'packages/pkg_a', '''
name: pkg_a
resolution: workspace
environment:
  sdk: ^3.11.0
dependencies:
  path: ^1.9.0
''');
      writePubspec(tempDirectory, 'packages/pkg_b', '''
name: pkg_b
resolution: workspace
environment:
  sdk: ^3.11.0
dependencies:
  collection: ^1.18.0
''');
      // A matched directory without a pubspec.yaml is skipped, not fatal.
      Directory(
        path.join(tempDirectory.path, 'packages', 'not_a_package'),
      ).createSync(recursive: true);

      final result = resolveWorkspaceDependencies(
        tempDirectory,
        logger: logger,
      );

      expect(result, {
        'path': PubspecDependencyType.directMain,
        'collection': PubspecDependencyType.directMain,
      });
      verify(() => logger.warn(any())).called(1);
    });

    test('warns and continues when a glob entry cannot be listed', () {
      writePubspec(tempDirectory, '.', '''
name: workspace_root
environment:
  sdk: ^3.11.0
workspace:
  - app
  - blocked/*
''');
      writePubspec(tempDirectory, 'app', '''
name: app
resolution: workspace
environment:
  sdk: ^3.11.0
dependencies:
  path: ^1.9.0
''');
      // A file where the glob expects a directory makes listing throw a
      // FileSystemException, which is treated as no match.
      File(path.join(tempDirectory.path, 'blocked')).writeAsStringSync('');

      final result = resolveWorkspaceDependencies(
        tempDirectory,
        logger: logger,
      );

      expect(result, {'path': PubspecDependencyType.directMain});
      verify(() => logger.warn(any())).called(1);
    });

    test('warns and continues when a workspace entry matches no directory', () {
      writePubspec(tempDirectory, '.', '''
name: workspace_root
environment:
  sdk: ^3.11.0
workspace:
  - app
  - does_not_exist
''');
      writePubspec(tempDirectory, 'app', '''
name: app
resolution: workspace
environment:
  sdk: ^3.11.0
dependencies:
  path: ^1.9.0
''');

      final result = resolveWorkspaceDependencies(
        tempDirectory,
        logger: logger,
      );

      expect(result, {'path': PubspecDependencyType.directMain});
      verify(() => logger.warn(any())).called(1);
    });

    test('warns and skips a member with an unparseable pubspec', () {
      writePubspec(tempDirectory, '.', '''
name: workspace_root
environment:
  sdk: ^3.11.0
workspace:
  - app
  - broken
''');
      writePubspec(tempDirectory, 'app', '''
name: app
resolution: workspace
environment:
  sdk: ^3.11.0
dependencies:
  path: ^1.9.0
''');
      writePubspec(tempDirectory, 'broken', '{{{ not valid yaml');

      final result = resolveWorkspaceDependencies(
        tempDirectory,
        logger: logger,
      );

      expect(result, {'path': PubspecDependencyType.directMain});
      verify(() => logger.warn(any())).called(1);
    });

    test('leniently parses a member with valid-but-unmodeled keys', () {
      writePubspec(tempDirectory, '.', '''
name: workspace_root
environment:
  sdk: ^3.11.0
workspace:
  - app
''');
      writePubspec(tempDirectory, 'app', '''
name: app
resolution: workspace
environment:
  sdk: ^3.11.0
dependencies:
  path: ^1.9.0
flutter:
  uses-material-design: true
''');

      final result = resolveWorkspaceDependencies(
        tempDirectory,
        logger: logger,
      );

      expect(result, {'path': PubspecDependencyType.directMain});
      verifyNever(() => logger.warn(any()));
    });

    test('returns an empty map when no member declares direct deps', () {
      writePubspec(tempDirectory, '.', '''
name: workspace_root
environment:
  sdk: ^3.11.0
workspace:
  - app
''');
      writePubspec(tempDirectory, 'app', '''
name: app
resolution: workspace
environment:
  sdk: ^3.11.0
''');

      final result = resolveWorkspaceDependencies(
        tempDirectory,
        logger: logger,
      );

      expect(result, isEmpty);
    });
  });

  group('declaresWorkspaceResolution', () {
    late Directory tempDirectory;

    setUp(() {
      tempDirectory = Directory.systemTemp.createTempSync();
      addTearDown(() => tempDirectory.deleteSync(recursive: true));
    });

    test('returns true when pubspec declares resolution: workspace', () {
      writePubspec(tempDirectory, '.', '''
name: app
resolution: workspace
environment:
  sdk: ^3.11.0
''');

      expect(declaresWorkspaceResolution(tempDirectory), isTrue);
    });

    test('returns false when pubspec does not declare a resolution', () {
      writePubspec(tempDirectory, '.', '''
name: app
environment:
  sdk: ^3.11.0
''');

      expect(declaresWorkspaceResolution(tempDirectory), isFalse);
    });

    test('returns false when there is no pubspec', () {
      expect(declaresWorkspaceResolution(tempDirectory), isFalse);
    });
  });
}
