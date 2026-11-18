import 'dart:io';

import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:very_good_cli/src/pubspec/pubspec.dart';
import 'package:very_good_cli/src/pubspec_workspace/pubspec_workspace.dart';

class _MockLogger extends Mock implements Logger;

class _MockWorkspaceDependencyCollector extends Mock
    implements WorkspaceDependencyCollector;

class _FakeDirectory extends Fake implements Directory;

class _FakePubspec extends Fake implements Pubspec;

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeDirectory());
    registerFallbackValue(_FakePubspec());
  });

  /// Writes a `pubspec.yaml` with [content] into a subdirectory [name]
  /// (which maybe a nested path) of [root], creating directories as needed.
  Directory writePubspec(Directory root, String name, String content) {
    final directory = Directory(path.join(root.path, name))
      ..createSync(recursive: true);
    File(path.join(directory.path, 'pubspec.yaml')).writeAsStringSync(content);
    return directory;
  }

  group(PubspecWorkspace, () {
    group('fromDirectory', () {
      late Directory tempDirectory;

      setUp(() {
        tempDirectory = Directory.systemTemp.createTempSync();
        addTearDown(() => tempDirectory.deleteSync(recursive: true));
      });

      test('throws a $PubspecWorkspaceNotFoundException '
          'when the pubspec.yaml is missing', () {
        expect(
          () => PubspecWorkspace.fromDirectory(tempDirectory),
          throwsA(
            isA<PubspecWorkspaceNotFoundException>()
                .having(
                  (e) => e.directory.path,
                  'directory',
                  tempDirectory.path,
                )
                .having((e) => e.pubspecFile, 'pubspecFile', isNull)
                .having(
                  (e) => '$e',
                  'toString()',
                  contains(tempDirectory.path),
                ),
          ),
        );
      });

      test('throws a $PubspecWorkspaceParseException '
          'when the pubspec.yaml is unparseable', () {
        final pubspecFile = File(path.join(tempDirectory.path, 'pubspec.yaml'))
          ..writeAsStringSync('{{{ not valid yaml');

        expect(
          () => PubspecWorkspace.fromDirectory(tempDirectory),
          throwsA(
            isA<PubspecWorkspaceParseException>()
                .having(
                  (e) => e.pubspecFile.path,
                  'pubspecFile',
                  pubspecFile.path,
                )
                .having((e) => '$e', 'toString()', contains(pubspecFile.path)),
          ),
        );
      });

      test('throws a $PubspecWorkspaceNotFoundException '
          'for a non-workspace package (no workspace key)', () {
        writePubspec(tempDirectory, '.', '''
name: single_package
environment:
  sdk: ^3.11.0
dependencies:
  path: ^1.9.0
''');

        expect(
          () => PubspecWorkspace.fromDirectory(tempDirectory),
          throwsA(
            isA<PubspecWorkspaceNotFoundException>().having(
              (e) => e.pubspecFile?.path,
              'pubspecFile',
              path.join(tempDirectory.path, 'pubspec.yaml'),
            ),
          ),
        );
      });

      test('throws a $PubspecWorkspaceNotFoundException '
          'for a non-list workspace key (treated as non-workspace)', () {
        writePubspec(tempDirectory, '.', '''
name: workspace_root
environment:
  sdk: ^3.11.0
workspace: not-a-list
''');

        expect(
          () => PubspecWorkspace.fromDirectory(tempDirectory),
          throwsA(isA<PubspecWorkspaceNotFoundException>()),
        );
      });

      test('reads a workspace with an empty workspace list', () {
        writePubspec(tempDirectory, '.', '''
name: workspace_root
environment:
  sdk: ^3.11.0
workspace: []
''');

        final workspace = PubspecWorkspace.fromDirectory(tempDirectory);

        expect(workspace.root.path, equals(tempDirectory.path));
        expect(workspace.entries, isEmpty);
      });

      test('reads the root, pubspec and entries of a workspace', () {
        writePubspec(tempDirectory, '.', '''
name: workspace_root
environment:
  sdk: ^3.11.0
workspace:
  - app
  - packages/*
''');

        final workspace = PubspecWorkspace.fromDirectory(tempDirectory);

        expect(workspace.root.path, equals(tempDirectory.path));
        expect(workspace.pubspec.name, equals('workspace_root'));
        expect(workspace.entries, equals(['app', 'packages/*']));
      });
    });

    group('enclosing', () {
      late Directory tempDirectory;

      setUp(() {
        tempDirectory = Directory.systemTemp.createTempSync();
        addTearDown(() => tempDirectory.deleteSync(recursive: true));
      });

      test('finds the workspace root in the parent directory', () {
        writePubspec(tempDirectory, '.', '''
name: workspace_root
environment:
  sdk: ^3.11.0
workspace: []
''');

        final workspace = PubspecWorkspace.enclosing(
          Directory(path.join(tempDirectory.path, 'pkg')),
        );

        expect(workspace.root.path, equals(tempDirectory.path));
      });

      test('finds the closest workspace root above a directory '
          'that does not exist yet', () {
        writePubspec(tempDirectory, '.', '''
name: outer_root
environment:
  sdk: ^3.11.0
workspace:
  - inner
''');
        final inner = writePubspec(tempDirectory, 'inner', '''
name: inner_root
environment:
  sdk: ^3.11.0
resolution: workspace
workspace:
  - packages/a
''');

        final workspace = PubspecWorkspace.enclosing(
          Directory(path.join(inner.path, 'packages', 'b')),
        );

        expect(workspace.root.path, equals(inner.path));
        expect(workspace.entries, equals(['packages/a']));
      });

      test('skips ancestors whose pubspec does not declare a workspace', () {
        writePubspec(tempDirectory, '.', '''
name: workspace_root
environment:
  sdk: ^3.11.0
workspace:
  - packages/*
''');
        final nested = writePubspec(tempDirectory, 'packages/a', '''
name: a
environment:
  sdk: ^3.11.0
resolution: workspace
''');

        final workspace = PubspecWorkspace.enclosing(
          Directory(path.join(nested.path, 'example')),
        );

        expect(workspace.root.path, equals(tempDirectory.path));
      });

      test('does not consider the directory itself', () {
        final directory = writePubspec(tempDirectory, 'root', '''
name: workspace_root
environment:
  sdk: ^3.11.0
workspace: []
''');

        expect(
          () => PubspecWorkspace.enclosing(directory),
          throwsA(isA<PubspecWorkspaceNotFoundException>()),
        );
      });

      test('throws a $PubspecWorkspaceNotFoundException with the closest '
          'pubspec when no ancestor declares a workspace', () {
        writePubspec(tempDirectory, '.', '''
name: outer
environment:
  sdk: ^3.11.0
''');
        final closest = writePubspec(tempDirectory, 'closest', '''
name: closest
environment:
  sdk: ^3.11.0
''');
        final directory = Directory(path.join(closest.path, 'packages', 'a'));

        expect(
          () => PubspecWorkspace.enclosing(directory),
          throwsA(
            isA<PubspecWorkspaceNotFoundException>()
                .having((e) => e.directory.path, 'directory', directory.path)
                .having(
                  (e) => e.pubspecFile?.path,
                  'pubspecFile',
                  path.join(closest.path, 'pubspec.yaml'),
                ),
          ),
        );
      });

      test('throws a $PubspecWorkspaceNotFoundException without a pubspec '
          'when no ancestor has one', () {
        expect(
          () => PubspecWorkspace.enclosing(
            Directory(path.join(tempDirectory.path, 'pkg')),
          ),
          throwsA(
            isA<PubspecWorkspaceNotFoundException>().having(
              (e) => e.pubspecFile,
              'pubspecFile',
              isNull,
            ),
          ),
        );
      });

      test('throws a $PubspecWorkspaceParseException '
          'when an ancestor pubspec is unparseable', () {
        File(path.join(tempDirectory.path, 'pubspec.yaml'))
            .writeAsStringSync('{{{ not valid yaml');

        expect(
          () => PubspecWorkspace.enclosing(
            Directory(path.join(tempDirectory.path, 'pkg')),
          ),
          throwsA(isA<PubspecWorkspaceParseException>()),
        );
      });
    });

    group('members', () {
      late Directory tempDirectory;
      late File pubspecFile;

      setUp(() {
        tempDirectory = Directory.systemTemp.createTempSync();
        addTearDown(() => tempDirectory.deleteSync(recursive: true));
        pubspecFile = File(path.join(tempDirectory.path, 'pubspec.yaml'));
      });

      Directory member(String name) =>
          Directory(path.joinAll([tempDirectory.path, ...name.split('/')]));

      PubspecWorkspace workspaceWith(String workspace) {
        pubspecFile.writeAsStringSync('''
name: workspace_root
environment:
  sdk: ^3.11.0
$workspace''');
        return PubspecWorkspace.fromDirectory(tempDirectory);
      }

      group('entryFor', () {
        test('returns the path relative to the root with / separators', () {
          final workspace = workspaceWith('workspace: []\n');

          expect(
            workspace.entryFor(member('packages/a')),
            equals('packages/a'),
          );
        });
      });

      group('includes', () {
        test('returns true for a literal entry', () {
          final workspace = workspaceWith('''
workspace:
  - packages/a
''');

          expect(workspace.includes(member('packages/a')), isTrue);
        });

        test('returns true for a literal entry that is not normalized', () {
          final workspace = workspaceWith('''
workspace:
  - ./packages/a/
''');

          expect(workspace.includes(member('packages/a')), isTrue);
        });

        test('returns true for a matching glob entry', () {
          final workspace = workspaceWith('''
workspace:
  - packages/*
''');

          expect(workspace.includes(member('packages/a')), isTrue);
        });

        test('returns false when no entry covers the member', () {
          final workspace = workspaceWith('''
workspace:
  - packages/a
  - plugins/*
''');

          expect(workspace.includes(member('packages/b')), isFalse);
          expect(workspace.includes(member('packages/a/example')), isFalse);
        });
      });

      group('addMembers', () {
        test('appends the members, preserving comments and formatting', () {
          final workspace = workspaceWith('''
# The members of the workspace.
workspace:
  - packages/a # The first one.

dependencies:
  path: ^1.9.0
''');

          final added = workspace.addMembers([
            member('packages/b'),
            member('packages/c'),
          ]);

          expect(added, equals(['packages/b', 'packages/c']));
          expect(
            pubspecFile.readAsStringSync(),
            equals('''
name: workspace_root
environment:
  sdk: ^3.11.0
# The members of the workspace.
workspace:
  - packages/a # The first one.
  - packages/b
  - packages/c

dependencies:
  path: ^1.9.0
'''),
          );
          expect(
            PubspecWorkspace.fromDirectory(tempDirectory).entries,
            equals(['packages/a', 'packages/b', 'packages/c']),
          );
        });

        test('appends to an empty workspace list as a block list', () {
          final workspace = workspaceWith('workspace: []\n');

          final added = workspace.addMembers([
            member('packages/a'),
            member('packages/b'),
          ]);

          expect(added, equals(['packages/a', 'packages/b']));
          expect(
            pubspecFile.readAsStringSync(),
            equals('''
name: workspace_root
environment:
  sdk: ^3.11.0
workspace:
  - packages/a
  - packages/b
'''),
          );
        });

        test('skips members that are already included or repeated', () {
          final workspace = workspaceWith('''
workspace:
  - packages/a
  - plugins/*
''');

          final added = workspace.addMembers([
            member('packages/a'),
            member('plugins/b'),
            member('packages/c'),
            member('packages/c'),
          ]);

          expect(added, equals(['packages/c']));
          expect(
            PubspecWorkspace.fromDirectory(tempDirectory).entries,
            equals(['packages/a', 'plugins/*', 'packages/c']),
          );
        });

        test('does not write the pubspec when there is nothing to add', () {
          final workspace = workspaceWith('''
workspace:
  - packages/*
''');
          final content = pubspecFile.readAsStringSync();
          final modified = pubspecFile.lastModifiedSync();

          final added = workspace.addMembers([member('packages/a')]);

          expect(added, isEmpty);
          expect(pubspecFile.readAsStringSync(), equals(content));
          expect(pubspecFile.lastModifiedSync(), equals(modified));
        });

        test('edits pubspec_overrides.yaml when it declares the workspace', () {
          final overridesFile =
              File(path.join(tempDirectory.path, 'pubspec_overrides.yaml'))
                ..writeAsStringSync('''
workspace:
  - packages/a
''');
          final workspace = workspaceWith('');
          final content = pubspecFile.readAsStringSync();

          final added = workspace.addMembers([member('packages/b')]);

          expect(added, equals(['packages/b']));
          expect(pubspecFile.readAsStringSync(), equals(content));
          expect(
            overridesFile.readAsStringSync(),
            equals('''
workspace:
  - packages/a
  - packages/b
'''),
          );
        });

        test('edits pubspec.yaml when pubspec_overrides.yaml does not declare '
            'the workspace', () {
          final overridesFile =
              File(path.join(tempDirectory.path, 'pubspec_overrides.yaml'))
                ..writeAsStringSync('''
dependency_overrides:
  path: ^1.9.0
''');
          final overrides = overridesFile.readAsStringSync();
          workspaceWith('''
workspace:
  - packages/a
''').addMembers([member('packages/b')]);

          expect(overridesFile.readAsStringSync(), equals(overrides));
          expect(
            PubspecWorkspace.fromDirectory(tempDirectory).entries,
            equals(['packages/a', 'packages/b']),
          );
        });

        test(
          'edits pubspec.yaml when pubspec_overrides.yaml is unparseable',
          () {
            File(path.join(tempDirectory.path, 'pubspec_overrides.yaml'))
                .writeAsStringSync('{{{ not valid yaml');
            workspaceWith('''
workspace:
  - packages/a
''').addMembers([member('packages/b')]);

            expect(
              pubspecFile.readAsStringSync(),
              contains('  - packages/b\n'),
            );
          },
        );
      });
    });

    group('resolveDependencies', () {
      late Directory tempDirectory;
      late Logger logger;

      setUp(() {
        tempDirectory = Directory.systemTemp.createTempSync();
        addTearDown(() => tempDirectory.deleteSync(recursive: true));
        logger = _MockLogger();
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

        final result = PubspecWorkspace.fromDirectory(tempDirectory)
            .resolveDependencies(logger: logger);

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

        final result = PubspecWorkspace.fromDirectory(tempDirectory)
            .resolveDependencies(logger: logger);

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

          final result = PubspecWorkspace.fromDirectory(tempDirectory)
              .resolveDependencies(logger: logger);

          expect(result['shared'], PubspecDependencyType.directMain);
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

          final result = PubspecWorkspace.fromDirectory(tempDirectory)
              .resolveDependencies(logger: logger);

          expect(result['shared'], PubspecDependencyType.directDev);
        },
      );

      test('resolves a cross-member type conflict via precedence '
          'main > overridden', () {
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

        final result = PubspecWorkspace.fromDirectory(tempDirectory)
            .resolveDependencies(logger: logger);

        expect(result['shared'], PubspecDependencyType.directMain);
      });

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

        final result = PubspecWorkspace.fromDirectory(tempDirectory)
            .resolveDependencies(logger: logger);

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

        final result = PubspecWorkspace.fromDirectory(tempDirectory)
            .resolveDependencies(logger: logger);

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

        final result = PubspecWorkspace.fromDirectory(tempDirectory)
            .resolveDependencies(logger: logger);

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
        // A glob-matched directory without a pubspec.yaml is silently skipped:
        // globs like `packages/*` legitimately co-exist with documentation or
        // fixture folders and should not emit warnings for them.
        Directory(path.join(tempDirectory.path, 'packages', 'not_a_package'))
            .createSync(recursive: true);

        final result = PubspecWorkspace.fromDirectory(tempDirectory)
            .resolveDependencies(logger: logger);

        expect(result, {
          'path': PubspecDependencyType.directMain,
          'collection': PubspecDependencyType.directMain,
        });
        verifyNever(() => logger.warn(any()));
      });

      test(
        'still warns when a glob-matched directory has an unparseable pubspec',
        () {
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
          // A pubspec.yaml is present but unparseable — the review still wants
          // this surfaced as a warning even under a glob.
          writePubspec(tempDirectory, 'packages/broken', '{{{ not valid yaml');

          final result = PubspecWorkspace.fromDirectory(tempDirectory)
              .resolveDependencies(logger: logger);

          expect(result, {'path': PubspecDependencyType.directMain});
          verify(() => logger.warn(any())).called(1);
        },
      );

      test('silently skips a glob entry that cannot be listed', () {
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
        // FileSystemException, which is treated as no match. Since the entry
        // is a glob, a no-match is silent (an empty `blocked/*` is a
        // legitimate configuration).
        File(path.join(tempDirectory.path, 'blocked')).writeAsStringSync('');

        final result = PubspecWorkspace.fromDirectory(tempDirectory)
            .resolveDependencies(logger: logger);

        expect(result, {'path': PubspecDependencyType.directMain});
        verifyNever(() => logger.warn(any()));
      });

      test(
        'warns and continues when a workspace entry matches no directory',
        () {
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

          final result = PubspecWorkspace.fromDirectory(tempDirectory)
              .resolveDependencies(logger: logger);

          expect(result, {'path': PubspecDependencyType.directMain});
          verify(() => logger.warn(any())).called(1);
        },
      );

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

        final result = PubspecWorkspace.fromDirectory(tempDirectory)
            .resolveDependencies(logger: logger);

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

        final result = PubspecWorkspace.fromDirectory(tempDirectory)
            .resolveDependencies(logger: logger);

        expect(result, {'path': PubspecDependencyType.directMain});
        verifyNever(() => logger.warn(any()));
      });

      test('discovers a workspace declared only in the root '
          'pubspec_overrides.yaml', () {
        // The root pubspec.yaml has no workspace declaration; Pub allows the
        // workspace list to live in pubspec_overrides.yaml instead. If we
        // ignore the overrides file we return null and the licenses command
        // falls back to the lockfile (where every member dependency is
        // transitive) — that's the failure mode this test guards against.
        writePubspec(tempDirectory, '.', '''
name: workspace_root
environment:
  sdk: ^3.11.0
''');
        File(path.join(tempDirectory.path, 'pubspec_overrides.yaml'))
            .writeAsStringSync('''
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

        final result = PubspecWorkspace.fromDirectory(tempDirectory)
            .resolveDependencies(logger: logger);

        expect(result, {'path': PubspecDependencyType.directMain});
      });

      test(
        "applies a member's pubspec_overrides.yaml before walking further",
        () {
          // The member declares no `workspace:` in its pubspec.yaml, only in
          // its pubspec_overrides.yaml. The nested member's dependency must
          // still be picked up.
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
''');
          File(path.join(tempDirectory.path, 'app', 'pubspec_overrides.yaml'))
              .writeAsStringSync('''
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

          final result = PubspecWorkspace.fromDirectory(tempDirectory)
              .resolveDependencies(logger: logger);

          expect(result, {
            'path': PubspecDependencyType.directMain,
            'collection': PubspecDependencyType.directMain,
          });
        },
      );

      test('pubspec_overrides.yaml replaces dependency_overrides entirely', () {
        // The overrides file replaces, not merges — the pubspec.yaml
        // dependency_overrides entry must be dropped in favor of the one in
        // pubspec_overrides.yaml.
        writePubspec(tempDirectory, '.', '''
name: workspace_root
environment:
  sdk: ^3.11.0
workspace:
  - app
dependency_overrides:
  meta: ^1.9.0
''');
        File(path.join(tempDirectory.path, 'pubspec_overrides.yaml'))
            .writeAsStringSync('''
dependency_overrides:
  args: ^2.4.0
''');
        writePubspec(tempDirectory, 'app', '''
name: app
resolution: workspace
environment:
  sdk: ^3.11.0
''');

        final result = PubspecWorkspace.fromDirectory(tempDirectory)
            .resolveDependencies(logger: logger);

        expect(result, {'args': PubspecDependencyType.directOverridden});
      });

      test('falls back to pubspec.yaml alone when pubspec_overrides.yaml is '
          'unparseable', () {
        writePubspec(tempDirectory, '.', '''
name: workspace_root
environment:
  sdk: ^3.11.0
workspace:
  - app
''');
        File(path.join(tempDirectory.path, 'pubspec_overrides.yaml'))
            .writeAsStringSync('{{{ not valid yaml');
        writePubspec(tempDirectory, 'app', '''
name: app
resolution: workspace
environment:
  sdk: ^3.11.0
dependencies:
  path: ^1.9.0
''');

        final result = PubspecWorkspace.fromDirectory(tempDirectory)
            .resolveDependencies(logger: logger);

        expect(result, {'path': PubspecDependencyType.directMain});
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

        final result = PubspecWorkspace.fromDirectory(tempDirectory)
            .resolveDependencies(logger: logger);

        expect(result, isEmpty);
      });

      test('walks the workspace with the injected collector', () {
        writePubspec(tempDirectory, '.', '''
name: root
environment:
  sdk: ^3.11.0
workspace:
  - packages/a
''');
        final collector = _MockWorkspaceDependencyCollector();
        const dependencies = {'http': PubspecDependencyType.directMain};
        when(collector.classify).thenReturn(dependencies);

        final result = PubspecWorkspace.fromDirectory(tempDirectory)
            .resolveDependencies(logger: logger, collector: collector);

        expect(result, equals(dependencies));
        final visitedDirectory =
            verify(() => collector.visit(captureAny(), any())).captured.single
                as Directory;
        expect(visitedDirectory.path, equals(tempDirectory.path));
      });
    });

    group('parsePackagePaths', () {
      test('returns the path of every package, the root included', () {
        const output = '''
{
  "packages": [
    {"name": "_", "path": "/workspace"},
    {"name": "a", "path": "/workspace/packages/a"}
  ]
}''';

        expect(
          PubspecWorkspace.parsePackagePaths(output),
          equals(['/workspace', '/workspace/packages/a']),
        );
      });

      test('throws a FormatException when the output is not JSON', () {
        expect(
          () => PubspecWorkspace.parsePackagePaths(
            'Found no `pubspec.yaml` file',
          ),
          throwsFormatException,
        );
      });
    });

    group('declaresResolution', () {
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

        expect(PubspecWorkspace.declaresResolution(tempDirectory), isTrue);
      });

      test('returns false when pubspec does not declare a resolution', () {
        writePubspec(tempDirectory, '.', '''
name: app
environment:
  sdk: ^3.11.0
''');

        expect(PubspecWorkspace.declaresResolution(tempDirectory), isFalse);
      });

      test('returns false when there is no pubspec', () {
        expect(PubspecWorkspace.declaresResolution(tempDirectory), isFalse);
      });

      test(
        'returns true when pubspec_overrides.yaml sets resolution: workspace',
        () {
          writePubspec(tempDirectory, '.', '''
name: app
environment:
  sdk: ^3.11.0
''');
          File(path.join(tempDirectory.path, 'pubspec_overrides.yaml'))
              .writeAsStringSync('''
resolution: workspace
''');

          expect(PubspecWorkspace.declaresResolution(tempDirectory), isTrue);
        },
      );

      test(
        'pubspec_overrides.yaml resolution replaces the pubspec.yaml value',
        () {
          writePubspec(tempDirectory, '.', '''
name: app
resolution: workspace
environment:
  sdk: ^3.11.0
''');
          // The override clears the resolution (an empty overrides file that
          // does not set resolution leaves the pubspec.yaml value alone, so we
          // set it to something other than 'workspace' to force replacement).
          File(path.join(tempDirectory.path, 'pubspec_overrides.yaml'))
              .writeAsStringSync('''
resolution: none
''');

          expect(PubspecWorkspace.declaresResolution(tempDirectory), isFalse);
        },
      );
    });
  });

  group(WorkspaceDependencyCollector, () {
    late Directory tempDirectory;
    late Logger logger;

    setUp(() {
      tempDirectory = Directory.systemTemp.createTempSync();
      addTearDown(() => tempDirectory.deleteSync(recursive: true));
      logger = _MockLogger();
    });

    test('classify returns an empty map before any visit', () {
      expect(WorkspaceDependencyCollector(logger: logger).classify(), isEmpty);
    });

    test('visits each directory at most once', () {
      final pubspec = Pubspec(
        'root',
        dependencies: {'http': HostedDependency()},
        devDependencies: {'test': HostedDependency()},
        dependencyOverrides: {'meta': HostedDependency()},
      );
      final collector = WorkspaceDependencyCollector(logger: logger)
        ..visit(tempDirectory, pubspec)
        ..visit(
          tempDirectory,
          Pubspec('root', dependencies: {'args': HostedDependency()}),
        );

      expect(
        collector.classify(),
        equals({
          'http': PubspecDependencyType.directMain,
          'test': PubspecDependencyType.directDev,
          'meta': PubspecDependencyType.directOverridden,
        }),
      );
    });
  });
}
