import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

/// How each suite annotation is rendered as a `group` argument, given the
/// source of its arguments and its named constructor, if any.
///
/// A `null` renderer marks an annotation that is recognized but can never be
/// forwarded.
final _groupArgumentRenderers =
    <String, String Function(String source, String? constructorName)?>{
      'Tags': (source, _) => ', tags: $source',
      // `@Skip()` without a reason skips unconditionally.
      'Skip': (source, _) => ', skip: ${source.isEmpty ? 'true' : source}',
      'Timeout': (source, constructorName) =>
          ''', timeout: Timeout${constructorName == null ? '' : '.$constructorName'}($source)''',
      'Retry': (source, _) => ', retry: $source',
      'OnPlatform': (source, _) => ', onPlatform: $source',
      // `@TestOn` gates the suite on the platform, which usually means the file
      // imports platform specific libraries that must not be compiled into the
      // shared entrypoint at all.
      'TestOn': null,
    };

/// The `package:test` annotations that only take effect on the library of a
/// test suite's entrypoint.
///
/// The optimizer merges every test file into a single entrypoint, so these
/// annotations land on an imported library where `package:test` never reads
/// them. They are forwarded to the wrapping `group` instead.
final Set<String> suiteAnnotationNames = _groupArgumentRenderers.keys.toSet();

/// The identifiers an annotation's arguments may reference and still resolve
/// inside the generated entrypoint.
///
/// `package:test` and `flutter_test` both export `Skip`, `Timeout` and
/// `Retry`, and `Duration` comes from `dart:core`. Anything else may be
/// private to the test file, so the file has to run as its own suite.
const _resolvableIdentifiers = <String>{
  'Duration',
  'Timeout',
  'Skip',
  'Retry',
  // Members of the constructors above.
  'factor',
  'none',
  'zero',
  'days',
  'hours',
  'minutes',
  'seconds',
  'milliseconds',
  'microseconds',
};

/// The named `group` arguments carrying the suite-level annotations declared
/// by [contents], each prefixed with `, ` so they can be appended to an
/// existing argument list.
///
/// Empty when the test file declares nothing to forward. `null` when the
/// annotations cannot be represented on a `group`, in which case the file has
/// to run as its own suite to keep the behavior it has under a plain
/// `dart test`.
String? suiteGroupArguments(String contents) {
  // Parsing dominates the pre-gen hook and most test files declare no
  // annotation at all, so keep the parser out of the common case.
  if (!contents.contains('@')) return '';

  final buffer = StringBuffer();
  final seen = <String>{};

  for (final annotation in _parseSuiteAnnotations(contents)) {
    // `package:test` rejects a repeated annotation, and `group` cannot take
    // the same argument twice either.
    if (!seen.add(annotation.name)) return null;

    final render = _groupArgumentRenderers[annotation.name];
    if (render == null) return null;

    // A constant reference such as `@Timeout.none` has no argument list to
    // forward.
    final argumentList = annotation.arguments;
    if (argumentList == null) return null;

    final arguments = argumentList.arguments;
    if (arguments.any((argument) => !_isResolvable(argument))) return null;

    // `Timeout` is the only one of these annotations with named constructors.
    final constructorName = annotation.constructorName;
    if (constructorName != null && annotation.name != 'Timeout') return null;

    buffer.write(
      render(
        arguments.map((argument) => argument.toSource()).join(', '),
        constructorName,
      ),
    );
  }

  return buffer.toString();
}

/// The suite-level annotations declared by [contents].
///
/// Resolved the same way `package:test` resolves them: suite metadata comes
/// from the annotations attached to the *first* directive of the compilation
/// unit, which is the `library` directive when there is one and the first
/// `import` otherwise. Annotations that sit after the first directive, or in a
/// file with no directives at all, are invisible to `package:test` and are
/// left out here too.
///
/// Ported from `package:test_core`'s `src/runner/parse_metadata.dart`, which
/// cannot be imported here as it is a private implementation library.
List<_SuiteAnnotation> _parseSuiteAnnotations(String contents) {
  // The parser recovers from syntax errors rather than throwing, so a
  // malformed test file simply yields whatever header it managed to parse. It
  // fails to compile inside the generated entrypoint either way.
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

_SuiteAnnotation? _resolveAnnotation(
  Annotation annotation,
  Set<String> prefixes,
) {
  final identifier = annotation.name;
  final constructorName = annotation.constructorName;

  // The syntax is ambiguous between a named constructor and a prefixed
  // annotation. The analyzer parses `@x.y()` as prefix `x` with annotation `y`
  // and no named constructor, and `@x.y.z()` as prefix `x` with annotation `y`
  // and named constructor `z`, so the known import prefixes tell the two
  // apart. Same resolution `package:test` performs.
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
  final collector = _IdentifierCollector();
  node.accept(collector);
  return collector.names.every(_resolvableIdentifiers.contains);
}

/// A `package:test` annotation that applies to an entire test suite.
class _SuiteAnnotation({
  /// The annotation class, e.g. `Timeout` in `@Timeout.factor(2)`.
  required final String name,

  /// The named constructor, e.g. `factor` in `@Timeout.factor(2)`.
  final String? constructorName,

  /// The annotation's arguments, or `null` when it has no argument list.
  final ArgumentList? arguments,
});

/// Collects every identifier an expression references, including the ones
/// inside string interpolations.
class _IdentifierCollector extends RecursiveAstVisitor<void> {
  final names = <String>[];

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) => names.add(node.name);
}
