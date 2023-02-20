import 'package:hooks/pre_gen.dart';
import 'package:test/test.dart';

void main() {
  group('$StringIdGenerator', () {
    test('can be instantiated', () {
      expect(StringIdGenerator.new, returnsNormally);
    });

    group('next', () {
      test('returns normally', () {
        final generator = StringIdGenerator();
        expect(generator.next, returnsNormally);
      });

      test('generates unique strings', () {
        final generator = StringIdGenerator();
        final ids = <String>{};
        const count = 1000;
        for (var i = 0; i < count; i++) {
          final id = generator.next();
          expect(ids, isNot(contains(id)));
          ids.add(id);
        }
        expect(ids.length, count);
      });
    });
  });
}
