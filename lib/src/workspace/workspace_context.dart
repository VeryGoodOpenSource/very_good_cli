import 'package:equatable/equatable.dart';

/// {@template workspace_context}
/// Describes a Dart/Flutter [pub workspace][1] discovered on disk.
///
/// A workspace is identified by a `pubspec.yaml` that declares a top-level
/// `workspace:` key listing its member packages.
///
/// [1]: https://dart.dev/tools/pub/workspaces
/// {@endtemplate}
class WorkspaceContext extends Equatable {
  /// {@macro workspace_context}
  const WorkspaceContext({required this.rootPath, required this.members});

  /// The absolute path to the directory containing the workspace's
  /// root `pubspec.yaml`.
  final String rootPath;

  /// The member package paths declared under the `workspace:` key,
  /// relative to [rootPath] and using forward slashes.
  final List<String> members;

  @override
  List<Object?> get props => [rootPath, members];
}
