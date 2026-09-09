import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

/// Renders a suite annotation as a named `group` argument, or returns `null`
/// when the annotation cannot be represented on a `group`.
typedef _GroupArgumentRenderer = String? Function(
  String source,
  String? constructorName,
);

/// How each suite annotation is rendered as a `group` argument.
final _groupArgumentRenderers = <String, _GroupArgumentRenderer>{
  'Tags': (source, _) => 'tags: $source',
  'Skip': (source, _) => 'skip: ${source.isEmpty ? 'true' : source}',
  'Timeout': (source, constructorName) =>
      '''timeout: Timeout${constructorName == null ? '' : '.$constructorName'}($source)''',
  'Retry': (source, _) => 'retry: $source',
  'OnPlatform': (source, _) => 'onPlatform: $source',
  'TestOn': (source, _) =>
      _vmPlatformSelector.hasMatch(source) ? 'testOn: $source' : null,
};

/// The `package:test` annotations that only take effect on the library of a
/// test suite's entrypoint.
final Set<String> suiteAnnotationNames = _groupArgumentRenderers.keys.toSet();

/// A `@TestOn` selector naming the Dart VM or an operating system.
///
/// `--platform` disables the optimization, so the generated entrypoint only
/// ever runs on the default platform. There such a selector either matches or
/// skips the group correctly, and, unlike a selector such as `browser`, it
/// cannot imply the web-only imports that make a file impossible to fold into
/// the entrypoint.
final _vmPlatformSelector = RegExp(
  r"""^(['"])(vm|posix|linux|mac-os|windows)\1$""",
);

/// The suite annotations `flutter_test`'s `group` can carry.
///
/// A Flutter package's entrypoint only imports
/// `package:flutter_test/flutter_test.dart`, which exports its own
/// `group(description, body, {skip, retry})` in place of `package:test`'s. Any
/// other argument would not compile, so the file runs as its own suite.
const _flutterGroupArgumentNames = <String>{'Skip', 'Retry'};

/// The identifiers an annotation's arguments may reference and still resolve
/// inside the generated entrypoint.
const _resolvableIdentifiers = <String>{
  'Duration',
  'Timeout',
  'Skip',
  'Retry',
  'factor',
  'none',
  'zero',
};

/// The named `group` arguments carrying the suite-level annotations declared
/// by [contents], prefixed with `, ` so they can be appended to an existing
/// argument list.
///
/// Empty when there is nothing to forward. `null` when the annotations cannot
/// be represented on the `group` of an [isFlutter] package's entrypoint, so
/// the file has to run as its own suite.
String? suiteGroupArguments(String contents, {required bool isFlutter}) {
  if (!_declaresAnnotation(contents)) return '';

  final arguments = <String>[];
  final seen = <String>{};

  for (final annotation in _parseSuiteAnnotations(contents)) {
    if (!seen.add(annotation.name)) return null;

    if (isFlutter && !_flutterGroupArgumentNames.contains(annotation.name)) {
      return null;
    }

    final argumentList = annotation.arguments;
    if (argumentList == null) return null;

    final annotationArguments = argumentList.arguments;
    if (!annotationArguments.every(_isResolvable)) return null;

    final constructorName = annotation.constructorName;
    if (constructorName != null && annotation.name != 'Timeout') return null;

    // Every parsed annotation names a renderer, as [suiteAnnotationNames] is
    // derived from [_groupArgumentRenderers].
    final argument = _groupArgumentRenderers[annotation.name]!(
      annotationArguments.map((argument) => argument.toSource()).join(', '),
      constructorName,
    );
    if (argument == null) return null;

    arguments.add(argument);
  }

  return arguments.isEmpty ? '' : ', ${arguments.join(', ')}';
}

/// Whether the first token of [contents], once comments are skipped, is an
/// annotation, which is the only place suite metadata can appear.
bool _declaresAnnotation(String contents) {
  var index = 0;
  while (index < contents.length) {
    final character = contents[index];

    if (character.trim().isEmpty) {
      index++;
    } else if (contents.startsWith('//', index) ||
        contents.startsWith('#!', index)) {
      final lineEnd = contents.indexOf('\n', index);
      if (lineEnd == -1) return false;
      index = lineEnd + 1;
    } else if (contents.startsWith('/*', index)) {
      var depth = 0;
      do {
        if (contents.startsWith('/*', index)) {
          depth++;
          index += 2;
        } else if (contents.startsWith('*/', index)) {
          depth--;
          index += 2;
        } else {
          index++;
        }
      } while (depth > 0 && index < contents.length);
    } else {
      return character == '@';
    }
  }

  return false;
}

/// The suite-level annotations declared by [contents].
///
/// Resolved as `package:test` resolves them, from the annotations attached to
/// the *first* directive of the compilation unit. Ported from
/// `package:test_core`'s `src/runner/parse_metadata.dart`, which is only
/// reachable through a deprecated library.
List<_SuiteAnnotation> _parseSuiteAnnotations(String contents) {
  final unit = parseString(content: contents, throwIfDiagnostics: false).unit;

  final directives = unit.directives;
  if (directives.isEmpty) return const [];

  final prefixes = directives
      .whereType<ImportDirective>()
      .map((directive) => directive.prefix?.name)
      .whereType<String>()
      .toSet();

  return [
    for (final annotation in directives.first.metadata)
      ?_resolveAnnotation(annotation, prefixes),
  ];
}

/// Resolves [annotation] against the [prefixes] the test file imports under.
///
/// The analyzer parses `@x.y()` as prefix `x` with annotation `y`, and
/// `@x.y.z()` as prefix `x` with annotation `y` and named constructor `z`, so
/// only the known prefixes tell a named constructor from a prefixed
/// annotation.
_SuiteAnnotation? _resolveAnnotation(
  Annotation annotation,
  Set<String> prefixes,
) {
  final identifier = annotation.name;
  final constructorName = annotation.constructorName;

  final String name;
  String? namedConstructor;
  if (identifier is PrefixedIdentifier &&
      !prefixes.contains(identifier.prefix.name) &&
      constructorName == null) {
    name = identifier.prefix.name;
    namedConstructor = identifier.identifier.name;
  } else {
    name = identifier is PrefixedIdentifier
        ? identifier.identifier.name
        : identifier.name;
    namedConstructor = constructorName?.name;
  }

  if (!suiteAnnotationNames.contains(name)) return null;

  return _SuiteAnnotation(
    name: name,
    constructorName: namedConstructor,
    arguments: annotation.arguments,
  );
}

/// Whether every identifier [node] references resolves inside the generated
/// entrypoint.
bool _isResolvable(AstNode node) {
  final visitor = _ResolvableIdentifierVisitor();
  node.accept(visitor);
  return visitor.resolvable;
}

/// A `package:test` annotation that applies to an entire test suite, e.g.
/// [name] `Timeout` with [constructorName] `factor` for `@Timeout.factor(2)`.
class _SuiteAnnotation({
  required final String name,
  final String? constructorName,
  final ArgumentList? arguments,
});

/// Checks that every identifier an expression references, including the ones
/// inside string interpolations, resolves inside the generated entrypoint.
class _ResolvableIdentifierVisitor extends RecursiveAstVisitor<void> {
  bool resolvable = true;

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    resolvable &= _resolvableIdentifiers.contains(node.name);
  }

  /// A named argument's label is not a reference, so it has nothing to resolve.
  @override
  void visitLabel(Label node) {}
}
