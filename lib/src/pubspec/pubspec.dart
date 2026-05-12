/// Workspace-aware helpers around [package:pubspec_parse].
///
/// Parsing is delegated to [Pubspec.parse]; this library only adds the
/// filesystem and glob expansion helpers needed by
/// `packages check licenses` to walk workspace members.
library;

import 'dart:io';

import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';
import 'package:path/path.dart' as path;
import 'package:pubspec_parse/pubspec_parse.dart';

export 'package:pubspec_parse/pubspec_parse.dart' show Pubspec;

/// The basename of the pubspec file.
const pubspecBasename = 'pubspec.yaml';

const _workspaceResolution = 'workspace';

/// Workspace-related conveniences on top of [Pubspec].
extension PubspecWorkspace on Pubspec {
  /// Whether this pubspec is a workspace root.
  bool get isWorkspaceRoot => workspace != null;

  /// Whether this pubspec is a workspace member.
  bool get isWorkspaceMember => resolution == _workspaceResolution;
}

/// Attempts to read and parse a [Pubspec] from [file].
///
/// Returns `null` when the file does not exist or cannot be parsed.
Pubspec? tryParsePubspec(File file) {
  if (!file.existsSync()) return null;
  try {
    return Pubspec.parse(
      file.readAsStringSync(),
      sourceUrl: file.uri,
      lenient: true,
    );
  } on Exception {
    return null;
  }
}

/// Resolves the workspace members declared by [pubspec], expanding any glob
/// patterns relative to [root].
///
/// Returns an empty list when [pubspec] is not a workspace root.
List<Directory> resolveWorkspaceMembers(Pubspec pubspec, Directory root) {
  final patterns = pubspec.workspace;
  if (patterns == null) return const [];

  final members = <Directory>[];
  for (final pattern in patterns) {
    if (_isGlobPattern(pattern)) {
      final matches = Glob(pattern).listSync(root: root.path);
      for (final match in matches) {
        if (match is Directory) {
          final pubspecFile = File(path.join(match.path, pubspecBasename));
          if (pubspecFile.existsSync()) {
            members.add(Directory(match.path));
          }
        } else if (match is File &&
            path.basename(match.path) == pubspecBasename) {
          members.add(Directory(match.parent.path));
        }
      }
    } else {
      final memberDir = Directory(path.join(root.path, pattern));
      if (memberDir.existsSync()) members.add(memberDir);
    }
  }

  return members;
}

bool _isGlobPattern(String pattern) {
  return pattern.contains('*') ||
      pattern.contains('?') ||
      pattern.contains('[') ||
      pattern.contains('{');
}
