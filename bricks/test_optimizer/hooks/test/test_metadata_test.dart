import 'package:hooks/test_metadata.dart';
import 'package:test/test.dart';

/// Wraps [annotations] above a `library;` directive, the shape `package:test`
/// reads metadata from.
String library(String annotations) =>
    '$annotations\nlibrary;\n\nvoid main() {}';

/// Matches metadata that forwards no annotation to the bundle.
final Matcher forwardsNothing = isA<TestMetadata>().having(
  (metadata) => metadata.arguments,
  'arguments',
  isEmpty,
);

void main() {
  group('parseTestMetadata', () {
    group('forwards nothing', () {
      test('for empty content', () {
        final metadata = parseTestMetadata('');

        expect(metadata, forwardsNothing);
        expect(metadata.tagNames, isEmpty);
        expect(metadata.droppedAnnotations, isEmpty);
      });

      test('for a file without directives', () {
        final metadata = parseTestMetadata('void main() {}');

        expect(metadata, forwardsNothing);
      });

      test('for a file whose annotations sit above main', () {
        final metadata = parseTestMetadata('''
import 'package:test/test.dart';

@Skip('ignored by package:test')
void main() {}
''');

        expect(metadata, forwardsNothing);
      });

      test('for annotations on a directive other than the first', () {
        final metadata = parseTestMetadata('''
import 'package:test/test.dart';

@Skip('ignored by package:test')
import 'dart:async';

void main() {}
''');

        expect(metadata, forwardsNothing);
      });

      test('for a bare annotation with no argument list', () {
        final metadata = parseTestMetadata(library('@Skip'));

        expect(metadata, forwardsNothing);
      });

      test('for a bare @Timeout, which names the type rather than a value', () {
        final metadata = parseTestMetadata(library('@Timeout'));

        expect(metadata, forwardsNothing);
      });
    });

    group('ignores unrecognized annotations', () {
      test('without dropping them', () {
        final metadata = parseTestMetadata(library("@Deprecated('nope')"));

        expect(metadata, forwardsNothing);
        expect(metadata.droppedAnnotations, isEmpty);
      });

      test('even when they reference an unresolvable name', () {
        final metadata = parseTestMetadata(library('@Deprecated(reason)'));

        expect(metadata, forwardsNothing);
        expect(metadata.droppedAnnotations, isEmpty);
      });
    });

    group('parses', () {
      test('@Skip without a reason', () {
        final metadata = parseTestMetadata(library('@Skip()'));

        expect(metadata.arguments['skip'], equals('true'));
      });

      test('@Skip with a reason', () {
        final metadata = parseTestMetadata('''
@Skip('not ready')
import 'package:test/test.dart';

void main() {}
''');

        expect(metadata.arguments['skip'], equals("'not ready'"));
      });

      test('@Tags', () {
        final metadata = parseTestMetadata(
          library("@Tags(['slow', 'integration'])"),
        );

        expect(metadata.arguments['tags'], equals("['slow', 'integration']"));
        expect(metadata.tagNames, equals({'slow', 'integration'}));
      });

      test('@Tags spanning several lines onto a single one', () {
        final metadata = parseTestMetadata(
          library("@Tags([\n  'slow',\n  'integration',\n])"),
        );

        expect(metadata.arguments['tags'], equals("['slow', 'integration']"));
      });

      test('@Timeout with a duration', () {
        final metadata = parseTestMetadata(
          library('@Timeout(Duration(minutes: 5))'),
        );

        expect(
          metadata.arguments['timeout'],
          equals('Timeout(Duration(minutes: 5))'),
        );
      });

      test('@Timeout with a const duration', () {
        final metadata = parseTestMetadata(
          library('@Timeout(const Duration(seconds: 1))'),
        );

        expect(
          metadata.arguments['timeout'],
          equals('Timeout(const Duration(seconds: 1))'),
        );
      });

      test('@Timeout.factor', () {
        final metadata = parseTestMetadata(library('@Timeout.factor(2)'));

        expect(metadata.arguments['timeout'], equals('Timeout.factor(2)'));
      });

      test('@Timeout.none', () {
        final metadata = parseTestMetadata(library('@Timeout.none'));

        expect(metadata.arguments['timeout'], equals('Timeout.none'));
      });

      test('@TestOn', () {
        final metadata = parseTestMetadata(library("@TestOn('vm')"));

        expect(metadata.arguments['testOn'], equals("'vm'"));
      });

      test('@OnPlatform', () {
        final metadata = parseTestMetadata(
          library("@OnPlatform({'chrome': Timeout.factor(2)})"),
        );

        expect(
          metadata.arguments['onPlatform'],
          equals("{'chrome' : Timeout.factor(2)}"),
        );
      });

      test('@OnPlatform with a Skip value', () {
        final metadata = parseTestMetadata(
          library("@OnPlatform({'vm': Skip('not on the vm')})"),
        );

        expect(
          metadata.arguments['onPlatform'],
          equals("{'vm' : Skip('not on the vm')}"),
        );
      });

      test('@Retry', () {
        final metadata = parseTestMetadata(library('@Retry(3)'));

        expect(metadata.arguments['retry'], equals('3'));
      });

      test('a file that fails to parse', () {
        final metadata = parseTestMetadata('''
@Skip('still read')
library;

void main() { this is ( not valid dart
''');

        expect(metadata.arguments['skip'], equals("'still read'"));
      });
    });

    group('drops an annotation the bundle cannot resolve', () {
      test('naming a constant', () {
        final metadata = parseTestMetadata(library('@Timeout(kSlowSuite)'));

        expect(metadata.arguments['timeout'], isNull);
        expect(metadata.droppedAnnotations, equals(['@Timeout(kSlowSuite)']));
      });

      test('naming a constant inside a collection', () {
        final metadata = parseTestMetadata(library('@Tags([slow])'));

        expect(metadata.arguments['tags'], isNull);
        expect(metadata.droppedAnnotations, equals(['@Tags([slow])']));
      });

      test('naming a class the bundle does not import', () {
        final metadata = parseTestMetadata(
          library('@Timeout(const SlowDuration())'),
        );

        expect(metadata.arguments['timeout'], isNull);
        expect(
          metadata.droppedAnnotations,
          equals(['@Timeout(const SlowDuration())']),
        );
      });

      test('naming an unknown constructor', () {
        final metadata = parseTestMetadata(library('@Timeout.forever(2)'));

        expect(metadata.arguments['timeout'], isNull);
        expect(metadata.droppedAnnotations, equals(['@Timeout.forever(2)']));
      });

      test('reaching a class through an import prefix', () {
        final metadata = parseTestMetadata('''
@OnPlatform({'chrome': t.Timeout.factor(2)})
import 'package:test/test.dart' as t;

void main() {}
''');

        expect(metadata.arguments['onPlatform'], isNull);
        expect(metadata.droppedAnnotations, hasLength(1));
      });

      test('while still reading its string literal tags', () {
        final metadata = parseTestMetadata(library("@Tags([slow, 'fast'])"));

        expect(metadata.arguments['tags'], isNull);
        expect(metadata.tagNames, equals({'fast'}));
        expect(metadata.droppedAnnotations, hasLength(1));
      });

      test('without dropping its resolvable siblings', () {
        final metadata = parseTestMetadata(
          library('@Retry(attempts)\n@Timeout.none'),
        );

        expect(metadata.arguments['retry'], isNull);
        expect(metadata.arguments['timeout'], equals('Timeout.none'));
        expect(metadata.droppedAnnotations, equals(['@Retry(attempts)']));
      });
    });

    group('resolves import prefixes', () {
      test('on an annotation with arguments', () {
        final metadata = parseTestMetadata('''
@t.Skip('prefixed')
@t.Tags(['slow'])
import 'package:test/test.dart' as t;

void main() {}
''');

        expect(metadata.arguments['skip'], equals("'prefixed'"));
        expect(metadata.arguments['tags'], equals("['slow']"));
        expect(metadata.tagNames, equals({'slow'}));
      });

      test('on a prefixed named constructor', () {
        final metadata = parseTestMetadata('''
@t.Timeout.factor(2)
import 'package:test/test.dart' as t;

void main() {}
''');

        expect(metadata.arguments['timeout'], equals('Timeout.factor(2)'));
      });

      test('without confusing a named constructor for a prefix', () {
        final metadata = parseTestMetadata('''
@Timeout.none
import 'package:test/test.dart' as t;

void main() {}
''');

        expect(metadata.arguments['timeout'], equals('Timeout.none'));
      });
    });

    group('reads tag names', () {
      test('from a single tag', () {
        final metadata = parseTestMetadata(library("@Tags(['only'])"));

        expect(metadata.tagNames, equals({'only'}));
      });

      test('from a list spanning several lines', () {
        final metadata = parseTestMetadata(
          library("@Tags([\n  'other',\n  'last',\n])"),
        );

        expect(metadata.tagNames, equals({'other', 'last'}));
      });

      test('as empty for an argument that is not a list literal', () {
        final metadata = parseTestMetadata(library('@Tags(someTags)'));

        expect(metadata.tagNames, isEmpty);
      });

      test('as empty when the annotation is not on the first directive', () {
        final metadata = parseTestMetadata('''
@Tags(['ignored'])
void main() {}
''');

        expect(metadata.tagNames, isEmpty);
      });
    });
  });
}
