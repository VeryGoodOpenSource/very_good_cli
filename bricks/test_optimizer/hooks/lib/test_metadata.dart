import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

/// {@template test_metadata}
/// The library level annotations `package:test` reads from a test file, held
/// as source text so they can be forwarded to the `group` that wraps the file
/// in the optimized bundle.
/// {@endtemplate}
class TestMetadata {
  /// {@macro test_metadata}
  const new({
    this.arguments = const {},
    this.tagNames = const {},
    this.droppedAnnotations = const [],
  });

  /// `group` arguments keyed by parameter name, in a fixed order rather than
  /// the order the file wrote its annotations.
  final Map<String, String> arguments;

  /// The string literal tags of a `@Tags` annotation, read even when the
  /// annotation itself was dropped.
  final Set<String> tagNames;

  /// The annotations left out because the bundle cannot resolve them.
  final List<String> droppedAnnotations;
}

/// The names an annotation argument may reference.
///
/// The bundle imports only `package:test` (or `package:flutter_test`) and
/// `dart:core`, so an argument naming anything else does not resolve there.
const _resolvableNames = {
  'Duration',
  'Timeout',
  'Skip',
  'factor',
  'none',
  'zero',
};

/// The `group` parameter each forwarded annotation supplies.
///
/// Iteration order fixes the order [TestMetadata.arguments] emits.
const _groupParameters = {
  'TestOn': 'testOn',
  'Timeout': 'timeout',
  'Skip': 'skip',
  'Tags': 'tags',
  'OnPlatform': 'onPlatform',
  'Retry': 'retry',
};

/// Parses the library level test annotations of [content], the source of the
/// test file at [path]. Only the first directive's metadata is read, the one
/// place `package:test` looks.
///
/// An annotation naming something the bundle cannot resolve, as in
/// `@Timeout(kSlowSuite)`, is recorded in [TestMetadata.droppedAnnotations]
/// instead of being forwarded, so one file cannot break the whole bundle.
TestMetadata parseTestMetadata(String content, {String? path}) {
  final unit = parseString(
    content: content,
    path: path,
    throwIfDiagnostics: false,
  ).unit;

  final directives = unit.directives;
  if (directives.isEmpty) return const TestMetadata();

  final prefixes = directives
      .whereType<ImportDirective>()
      .map((directive) => directive.prefix?.name)
      .nonNulls
      .toSet();

  var tagNames = const <String>{};
  final droppedAnnotations = <String>[];
  final sources = <String, String>{};

  for (final annotation in directives.first.metadata) {
    final (className, constructorName) = _resolveConstructor(
      annotation.name,
      annotation.constructorName,
      prefixes,
    );
    if (!_groupParameters.containsKey(className)) continue;

    final arguments = annotation.arguments;

    if (className == 'Tags') {
      final argument = arguments?.arguments.firstOrNull;
      if (argument is ListLiteral) {
        tagNames = argument.elements
            .whereType<StringLiteral>()
            .map((element) => element.stringValue)
            .nonNulls
            .toSet();
      }
    }

    if (!_isResolvable(arguments, constructorName)) {
      droppedAnnotations.add(annotation.toSource());
      continue;
    }

    final source = _argumentSource(className, constructorName, arguments);
    if (source != null) sources[className] = source;
  }

  return TestMetadata(
    arguments: {
      for (final MapEntry(key: annotation, value: parameter)
          in _groupParameters.entries)
        parameter: ?sources[annotation],
    },
    tagNames: tagNames,
    droppedAnnotations: droppedAnnotations,
  );
}

/// The source forwarded for one annotation, or `null` when it has none, as for
/// a bare `@Timeout` or `@Skip` that names the type rather than a value.
String? _argumentSource(
  String className,
  String? constructorName,
  ArgumentList? arguments,
) {
  final argument = arguments?.arguments.firstOrNull;
  return switch (className) {
    'Timeout' when arguments == null && constructorName == null => null,
    'Timeout' =>
      'Timeout${constructorName == null ? '' : '.$constructorName'}'
          '${arguments?.toSource() ?? ''}',
    'Skip' when arguments == null => null,
    'Skip' => argument?.toSource() ?? 'true',
    _ => argument?.toSource(),
  };
}

/// Whether every name [arguments] and [constructorName] reference resolves in
/// the optimized bundle.
bool _isResolvable(ArgumentList? arguments, String? constructorName) {
  final referenced = _ReferencedNames();
  arguments?.accept(referenced);
  return [
    ?constructorName,
    ...referenced.names,
  ].every(_resolvableNames.contains);
}

/// Collects every name an expression references.
///
/// Named argument labels are tokens rather than identifiers, so `minutes` in
/// `Duration(minutes: 5)` is not collected, while `Duration` is.
class _ReferencedNames extends RecursiveAstVisitor<void> {
  final names = <String>[];

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) => names.add(node.name);

  @override
  void visitNamedType(NamedType node) {
    names.add(node.name.lexeme);
    super.visitNamedType(node);
  }
}

/// Resolves the class and named constructor an annotation refers to.
///
/// The syntax is ambiguous, so [prefixes] disambiguates: `@Timeout.none` names
/// a constructor, while `@test.Skip()` names `Skip` behind the `test` prefix.
(String, String?) _resolveConstructor(
  Identifier name,
  SimpleIdentifier? constructorName,
  Set<String> prefixes,
) {
  if (name is PrefixedIdentifier &&
      !prefixes.contains(name.prefix.name) &&
      constructorName == null) {
    return (name.prefix.name, name.identifier.name);
  }

  final className = name is PrefixedIdentifier
      ? name.identifier.name
      : name.name;
  return (className, constructorName?.name);
}
