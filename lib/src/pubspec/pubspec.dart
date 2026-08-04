/// Shared pubspec-domain primitives built on top of `package:pubspec_parse`.
///
/// The `packages check licenses` command reads dependency information from two
/// different sources: a `pubspec.lock` file (via `pubspec_lock.dart`) and the
/// `pubspec.yaml` files of a Pub workspace (via `pubspec_workspace.dart`). Both
/// classify dependencies with the same model, so that model lives here — a
/// common ancestor both import — instead of being duplicated across the two
/// sibling parsers.
library;

import 'dart:io';
import 'package:pubspec_parse/pubspec_parse.dart';

export 'package:pubspec_parse/pubspec_parse.dart';

/// {@template pubspec_dependency_type}
/// The classification of a package dependency.
/// {@endtemplate}
enum PubspecDependencyType {
  /// Another package that your package needs to work.
  ///
  /// See also:
  ///
  /// * [Dart's dependency documentation](https://dart.dev/tools/pub/dependencies)
  directMain._('direct main'),

  /// Another package that your package needs during development.
  ///
  /// See also:
  ///
  /// * [Dart's developer dependency documentation](https://dart.dev/tools/pub/dependencies#dev-dependencies)
  directDev._('direct dev'),

  /// A dependency that your package indirectly uses because one of its
  /// dependencies requires it.
  ///
  /// See also:
  ///
  /// * [Dart's transitive dependency documentation](https://dart.dev/tools/pub/glossary#transitive-)
  transitive._('transitive'),

  ///  A dependency that your package overrides that is not already a
  /// `direct main` or `direct dev` dependency.
  ///
  /// See also:
  ///
  /// * [Dart's dependency override documentation](https://dart.dev/tools/pub/dependencies#dependency-overrides)
  directOverridden._('direct overridden');

  const PubspecDependencyType._(this.value);

  /// Parses a [PubspecDependencyType] from its `pubspec.lock` textual form.
  ///
  /// Throws an [ArgumentError] if the string is not a valid dependency type.
  factory PubspecDependencyType.parse(String value) {
    if (_valueMap.containsKey(value)) return _valueMap[value]!;

    throw ArgumentError.value(
      value,
      'value',
      'Invalid PubspecDependencyType value.',
    );
  }

  static final Map<String, PubspecDependencyType> _valueMap = {
    for (final type in PubspecDependencyType.values) type.value: type,
  };

  /// The textual representation of the [PubspecDependencyType] as it appears in
  /// the `dependency` field of a `pubspec.lock` file.
  final String value;
}

/// Tolerantly parses a [Pubspec] from [pubspecFile].
///
/// Returns `null` when the file does not exist or cannot be parsed. Parsing is
/// lenient so valid-but-unmodeled keys (e.g. a `flutter:` block) do not throw.
Pubspec? tryParsePubspec(File pubspecFile) {
  if (!pubspecFile.existsSync()) return null;
  try {
    return Pubspec.parse(pubspecFile.readAsStringSync(), lenient: true);
    // Tolerate any malformed pubspec by returning null instead of throwing.
    // ignore: avoid_catches_without_on_clauses
  } catch (_) {
    return null;
  }
}
