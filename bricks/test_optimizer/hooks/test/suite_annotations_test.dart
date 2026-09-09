import 'package:hooks/suite_annotations.dart';
import 'package:test/test.dart';

const _testImport = "import 'package:test/test.dart';";

void main() {
  group('suiteAnnotationNames', () {
    test('covers every annotation package:test reads at the suite level', () {
      expect(
        suiteAnnotationNames,
        equals({'Skip', 'Tags', 'Timeout', 'TestOn', 'OnPlatform', 'Retry'}),
      );
    });
  });

  group('suiteGroupArguments', () {
    group('forwards', () {
      test('a skip reason declared above the library directive', () {
        expect(
          suiteGroupArguments('''
@Skip('not ready')
library;

$_testImport
'''),
          equals(", skip: 'not ready'"),
        );
      });

      test('a skip reason declared above the first import', () {
        expect(
          suiteGroupArguments('''
@Skip('not ready')

$_testImport
'''),
          equals(", skip: 'not ready'"),
        );
      });

      test('a skip without a reason as an unconditional skip', () {
        expect(
          suiteGroupArguments('''
@Skip()
library;
$_testImport
'''),
          equals(', skip: true'),
        );
      });

      test('tags', () {
        expect(
          suiteGroupArguments('''
@Tags(['slow', 'golden'])
library;
$_testImport
'''),
          equals(", tags: ['slow', 'golden']"),
        );
      });

      test('a timeout', () {
        expect(
          suiteGroupArguments('''
@Timeout(Duration(milliseconds: 100))
library;
$_testImport
'''),
          equals(', timeout: Timeout(Duration(milliseconds: 100))'),
        );
      });

      test('a timeout factor', () {
        expect(
          suiteGroupArguments('''
@Timeout.factor(2)
library;
$_testImport
'''),
          equals(', timeout: Timeout.factor(2)'),
        );
      });

      test('a retry count', () {
        expect(
          suiteGroupArguments('''
@Retry(3)
library;
$_testImport
'''),
          equals(', retry: 3'),
        );
      });

      test('platform overrides', () {
        expect(
          suiteGroupArguments('''
@OnPlatform({'browser': Skip('no dart:io')})
library;
$_testImport
'''),
          equals(", onPlatform: {'browser' : Skip('no dart:io')}"),
        );
      });

      test('every annotation of a file that declares several', () {
        expect(
          suiteGroupArguments('''
@Tags(['slow'])
@Timeout(Duration(seconds: 5))
library;
$_testImport
'''),
          equals(", tags: ['slow'], timeout: Timeout(Duration(seconds: 5))"),
        );
      });

      test('a prefixed annotation', () {
        expect(
          suiteGroupArguments('''
@t.Skip('x')
library;
import 'package:test/test.dart' as t;
'''),
          equals(", skip: 'x'"),
        );
      });

      test('a prefixed annotation with a named constructor', () {
        expect(
          suiteGroupArguments('''
@t.Timeout.factor(2)
library;
import 'package:test/test.dart' as t;
'''),
          equals(', timeout: Timeout.factor(2)'),
        );
      });

      test('arguments spread over several lines, as a single line', () {
        expect(
          suiteGroupArguments('''
@Timeout(
  Duration(
    seconds: 5,
  ),
)
library;
$_testImport
'''),
          equals(', timeout: Timeout(Duration(seconds: 5))'),
        );
      });

      test('arguments without the comments between them', () {
        expect(
          suiteGroupArguments('''
@Timeout(Duration(seconds: 5) /* fast */)
library;
$_testImport
'''),
          equals(', timeout: Timeout(Duration(seconds: 5))'),
        );
      });

      test('a reason containing what looks like a comment', () {
        expect(
          suiteGroupArguments('''
@Skip('see http://example.com')
library;
$_testImport
'''),
          equals(", skip: 'see http://example.com'"),
        );
      });

      test('an annotation below a block comment holding a directive', () {
        expect(
          suiteGroupArguments('''
/*
@Skip('x')
import 'nope.dart';
*/
@Tags(['slow'])
library;
$_testImport
'''),
          equals(", tags: ['slow']"),
        );
      });

      test('an annotation below a license header', () {
        expect(
          suiteGroupArguments('''
// Copyright (c) 2026, Very Good Ventures.
// Mentions @Skip in prose.

@Tags(['slow'])
library;
$_testImport
'''),
          equals(", tags: ['slow']"),
        );
      });
    });

    group('forwards nothing', () {
      test('for a file without annotations', () {
        expect(
          suiteGroupArguments('''
$_testImport

void main() {}
'''),
          isEmpty,
        );
      });

      test('for a file with no directives, as package:test does', () {
        expect(
          suiteGroupArguments('''
@Skip('x')
void main() {}
'''),
          isEmpty,
        );
      });

      test('for an annotation inside a line comment', () {
        expect(
          suiteGroupArguments('''
// @Skip('x')
$_testImport
'''),
          isEmpty,
        );
      });

      test('for an annotation after the first directive', () {
        expect(
          suiteGroupArguments('''
$_testImport

@Skip('x')
void main() {}
'''),
          isEmpty,
        );
      });

      test('for an annotation on a directive other than the first', () {
        expect(
          suiteGroupArguments('''
library;
$_testImport
@Skip('x')
import 'dart:async';
'''),
          isEmpty,
        );
      });

      test('for an unrelated annotation', () {
        expect(
          suiteGroupArguments('''
@MyTags(['x'])
library;
$_testImport
'''),
          isEmpty,
        );
      });

      test('for source the parser cannot make sense of', () {
        expect(
          suiteGroupArguments('''
void main( {
'''),
          isEmpty,
        );
      });
    });

    group('returns null', () {
      test('for @TestOn, which gates the whole suite on the platform', () {
        expect(
          suiteGroupArguments('''
@TestOn('browser')
library;
$_testImport
'''),
          isNull,
        );
      });

      test('for an argument that may not resolve in the entrypoint', () {
        expect(
          suiteGroupArguments('''
@Timeout(myProjectTimeout)
library;
$_testImport
'''),
          isNull,
        );
      });

      test('for an argument interpolating an identifier', () {
        expect(
          suiteGroupArguments(r'''
@Skip('flaky on $platform')
library;
import 'package:test/test.dart';
'''),
          isNull,
        );
      });

      test('for a repeated annotation, which package:test rejects too', () {
        expect(
          suiteGroupArguments('''
@Skip('a')
@Skip('b')
library;
$_testImport
'''),
          isNull,
        );
      });

      test('for a constant reference with no arguments to forward', () {
        expect(
          suiteGroupArguments('''
@Timeout.none
library;
$_testImport
'''),
          isNull,
        );
      });

      test('for a named constructor on an annotation without one', () {
        expect(
          suiteGroupArguments('''
@Skip.reason('x')
library;
$_testImport
'''),
          isNull,
        );
      });

      test('when only one of several annotations cannot be forwarded', () {
        expect(
          suiteGroupArguments('''
@Tags(['slow'])
@TestOn('vm')
library;
$_testImport
'''),
          isNull,
        );
      });
    });
  });
}
