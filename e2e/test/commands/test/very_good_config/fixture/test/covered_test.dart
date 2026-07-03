import 'package:test/test.dart';

void main() {
  group('very_good_config_fixture', () {
    // This test exists only to produce a passing coverage run so the
    // `min_coverage: 100` config can be evaluated against the deliberately
    // uncovered `lib/uncovered.dart`.
    test('trivially succeeds', () {
      expect(true, isTrue);
    });
  });
}
