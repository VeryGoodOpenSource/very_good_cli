import 'package:hooks/dart_identifier_generator.dart';
import 'package:test/test.dart';

void main() {
  group('$DartIdentifierGenerator', () {
    test('can be instantiated', () {
      expect(DartIdentifierGenerator.new, returnsNormally);
    });

    group('next', () {
      test('returns normally', () {
        final generator = DartIdentifierGenerator();
        expect(generator.next, returnsNormally);
      });

      test('generates unique strings', () {
        final generator = DartIdentifierGenerator();
        final ids = <String>{};
        const count = 1000;
        for (var i = 0; i < count; i++) {
          final id = generator.next();
          ids.add(id);
        }
        expect(ids.length, count);
      });

      test('generates valid dart identifiers', () {
        // For a full specification of valid dart identifiers, read
        // Section 17.37 from the [Dart Language Specification](https://dart.dev/guides/language/specifications/DartLangSpec-v2.10.pdf).
        final generator = DartIdentifierGenerator();
        final ids = <String>[];
        for (var i = 0; i < 1000; i++) {
          final id = generator.next();
          ids.add(id);
        }

        expect(
          ids.where((id) => _dartReservedKeywords.contains(id)),
          isEmpty,
        );
        expect(
          ids.every((id) {
            final idStart = id.codeUnitAt(0);
            final isAlphabetic = (idStart >= 65 && idStart <= 90) ||
                (idStart >= 97 && idStart <= 122);
            final isUnderscore = idStart == 95;
            final isDollarSign = idStart == 36;
            return isAlphabetic || isUnderscore || isDollarSign;
          }),
          true,
        );
        expect(
          ids.every((id) {
            final idPart = id.codeUnits.skip(1);
            return idPart.every((ascii) {
              final isAlphabetic =
                  (ascii >= 65 && ascii <= 90) || (ascii >= 97 && ascii <= 122);
              final isUnderscore = ascii == 95;
              final isDollarSign = ascii == 36;
              final isDigit = ascii >= 48 && ascii <= 57;
              return isAlphabetic || isUnderscore || isDollarSign || isDigit;
            });
          }),
          true,
        );
      });
    });
  });
}

// All reserved keywords in [Dart 2.19.2](https://dart.dev/guides/language/language-tour#keywords).
const _dartReservedKeywords = [
  'abstract',
  'as',
  'assert',
  'async',
  'await',
  'break',
  'case',
  'catch',
  'class',
  'const',
  'continue',
  'covariant',
  'default',
  'deferred',
  'do',
  'dynamic',
  'else',
  'enum',
  'export',
  'extends',
  'extension',
  'external',
  'factory',
  'false',
  'final',
  'finally',
  'for',
  'Function',
  'get',
  'hide',
  'if',
  'implements',
  'import',
  'in',
  'interface',
  'is',
  'late',
  'library',
  'mixin',
  'new',
  'null',
  'on',
  'operator',
  'part',
  'required',
  'rethrow',
  'return',
  'set',
  'show',
  'static',
  'super',
  'switch',
  'sync',
  'this',
  'throw',
  'true',
  'try',
  'typedef',
  'var',
  'void',
  'while',
  'with',
  'yield',
];
