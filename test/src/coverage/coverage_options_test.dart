import 'package:test/test.dart';
import 'package:very_good_cli/src/coverage/coverage.dart';

void main() {
  group(CoverageCollectionMode, () {
    group('.fromString', () {
      test('returns matching mode for known value', () {
        expect(
          CoverageCollectionMode.fromString('all'),
          equals(CoverageCollectionMode.all),
        );
      });

      test('returns imports for unrecognized value', () {
        expect(
          CoverageCollectionMode.fromString('unknown'),
          equals(CoverageCollectionMode.imports),
        );
      });
    });
  });

  group(CoverageOptions, () {
    test('has defaults that collect nothing', () {
      const options = CoverageOptions();

      expect(options.collect, isFalse);
      expect(options.collectFrom, equals(CoverageCollectionMode.imports));
      expect(options.minCoverage, isNull);
      expect(options.showUncovered, isFalse);
      expect(options.excludeFromCoverage, isNull);
      expect(options.reportOn, equals(['lib']));
      expect(options.checkIgnore, isFalse);
    });
  });
}
