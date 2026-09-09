import 'package:hooks/suite_annotations.dart';
import 'package:test/test.dart';

const _testImport = "import 'package:test/test.dart';";

/// [suiteGroupArguments] for a Dart package.
String? _dartGroupArguments(String contents) =>
    suiteGroupArguments(contents, isFlutter: false);

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
          _dartGroupArguments('''
@Skip('not ready')
library;

$_testImport
'''),
          equals(", skip: 'not ready'"),
        );
      });

      test('a skip reason declared above the first import', () {
        expect(
          _dartGroupArguments('''
@Skip('not ready')

$_testImport
'''),
          equals(", skip: 'not ready'"),
        );
      });

      test('a skip without a reason as an unconditional skip', () {
        expect(
          _dartGroupArguments('''
@Skip()
library;
$_testImport
'''),
          equals(', skip: true'),
        );
      });

      test('tags', () {
        expect(
          _dartGroupArguments('''
@Tags(['slow', 'golden'])
library;
$_testImport
'''),
          equals(", tags: ['slow', 'golden']"),
        );
      });

      test('a timeout', () {
        expect(
          _dartGroupArguments('''
@Timeout(Duration(milliseconds: 100))
library;
$_testImport
'''),
          equals(', timeout: Timeout(Duration(milliseconds: 100))'),
        );
      });

      test('a timeout factor', () {
        expect(
          _dartGroupArguments('''
@Timeout.factor(2)
library;
$_testImport
'''),
          equals(', timeout: Timeout.factor(2)'),
        );
      });

      test('a retry count', () {
        expect(
          _dartGroupArguments('''
@Retry(3)
library;
$_testImport
'''),
          equals(', retry: 3'),
        );
      });

      test('a platform selector satisfied by the Dart VM', () {
        expect(
          _dartGroupArguments('''
@TestOn('vm')
library;
$_testImport
'''),
          equals(", testOn: 'vm'"),
        );
      });

      test('a platform selector naming an operating system', () {
        expect(
          _dartGroupArguments('''
@TestOn("mac-os")
library;
$_testImport
'''),
          equals(', testOn: "mac-os"'),
        );
      });

      test('platform overrides', () {
        expect(
          _dartGroupArguments('''
@OnPlatform({'browser': Skip('no dart:io')})
library;
$_testImport
'''),
          equals(", onPlatform: {'browser' : Skip('no dart:io')}"),
        );
      });

      test('every annotation of a file that declares several', () {
        expect(
          _dartGroupArguments('''
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
          _dartGroupArguments('''
@t.Skip('x')
library;
import 'package:test/test.dart' as t;
'''),
          equals(", skip: 'x'"),
        );
      });

      test('a prefixed annotation with a named constructor', () {
        expect(
          _dartGroupArguments('''
@t.Timeout.factor(2)
library;
import 'package:test/test.dart' as t;
'''),
          equals(', timeout: Timeout.factor(2)'),
        );
      });

      test('arguments spread over several lines, as a single line', () {
        expect(
          _dartGroupArguments('''
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
          _dartGroupArguments('''
@Timeout(Duration(seconds: 5) /* fast */)
library;
$_testImport
'''),
          equals(', timeout: Timeout(Duration(seconds: 5))'),
        );
      });

      test('a reason containing what looks like a comment', () {
        expect(
          _dartGroupArguments('''
@Skip('see http://example.com')
library;
$_testImport
'''),
          equals(", skip: 'see http://example.com'"),
        );
      });

      test('an annotation below a block comment holding a directive', () {
        expect(
          _dartGroupArguments('''
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
          _dartGroupArguments('''
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
          _dartGroupArguments('''
$_testImport

void main() {}
'''),
          isEmpty,
        );
      });

      test('for a file with no directives, as package:test does', () {
        expect(
          _dartGroupArguments('''
@Skip('x')
void main() {}
'''),
          isEmpty,
        );
      });

      test('for an annotation inside a line comment', () {
        expect(
          _dartGroupArguments('''
// @Skip('x')
$_testImport
'''),
          isEmpty,
        );
      });

      test('for an annotation after the first directive', () {
        expect(
          _dartGroupArguments('''
$_testImport

@Skip('x')
void main() {}
'''),
          isEmpty,
        );
      });

      test('for an annotation on a directive other than the first', () {
        expect(
          _dartGroupArguments('''
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
          _dartGroupArguments('''
@MyTags(['x'])
library;
$_testImport
'''),
          isEmpty,
        );
      });

      test('for source the parser cannot make sense of', () {
        expect(
          _dartGroupArguments('''
void main( {
'''),
          isEmpty,
        );
      });
    });

    group('forwards, on Flutter,', () {
      test('a skip reason', () {
        expect(
          suiteGroupArguments('''
@Skip('not ready')
library;

import 'package:flutter_test/flutter_test.dart';
''', isFlutter: true),
          equals(", skip: 'not ready'"),
        );
      });

      test('a retry count', () {
        expect(
          suiteGroupArguments('''
@Retry(3)
library;

import 'package:flutter_test/flutter_test.dart';
''', isFlutter: true),
          equals(', retry: 3'),
        );
      });

      test('nothing for a file without annotations', () {
        expect(
          suiteGroupArguments('''
import 'package:flutter_test/flutter_test.dart';

void main() {}
''', isFlutter: true),
          isEmpty,
        );
      });
    });

    group('returns null', () {
      test('for a platform selector that implies web-only imports', () {
        expect(
          _dartGroupArguments('''
@TestOn('browser')
library;
$_testImport
'''),
          isNull,
        );
      });

      test('for a negated platform selector', () {
        expect(
          _dartGroupArguments('''
@TestOn('!windows')
library;
$_testImport
'''),
          isNull,
        );
      });

      test('for an argument that may not resolve in the entrypoint', () {
        expect(
          _dartGroupArguments('''
@Timeout(myProjectTimeout)
library;
$_testImport
'''),
          isNull,
        );
      });

      test('for an argument interpolating an identifier', () {
        expect(
          _dartGroupArguments(r'''
@Skip('flaky on $platform')
library;
import 'package:test/test.dart';
'''),
          isNull,
        );
      });

      test('for a repeated annotation, which package:test rejects too', () {
        expect(
          _dartGroupArguments('''
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
          _dartGroupArguments('''
@Timeout.none
library;
$_testImport
'''),
          isNull,
        );
      });

      test('for a named constructor on an annotation without one', () {
        expect(
          _dartGroupArguments('''
@Skip.reason('x')
library;
$_testImport
'''),
          isNull,
        );
      });

      test("for an annotation flutter_test's group cannot carry", () {
        for (final annotation in [
          "@Tags(['golden'])",
          '@Timeout(Duration(seconds: 5))',
          "@OnPlatform({'browser': Skip('no dart:io')})",
          "@TestOn('vm')",
        ]) {
          expect(
            suiteGroupArguments('''
$annotation
library;

import 'package:flutter_test/flutter_test.dart';
''', isFlutter: true),
            isNull,
            reason: '$annotation should not be forwarded on Flutter',
          );
        }
      });

      test('when only one of several annotations cannot be forwarded', () {
        expect(
          _dartGroupArguments('''
@Tags(['slow'])
@TestOn('browser')
library;
$_testImport
'''),
          isNull,
        );
      });
    });
  });
}
