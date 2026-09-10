@Tags(['integration'])
library;

import 'package:test/test.dart';

void main() {
  group('optimization_exclude_fixture', () {
    test('fails unless excluded, so a passing run proves it was', () {
      fail('this test should have been excluded by its tag');
    });
  });
}
