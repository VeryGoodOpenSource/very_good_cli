@Tags(['integration'])
library;

import 'package:test/test.dart';

void main() {
  group('optimization_exclude_fixture', () {
    // Fails on purpose. The file-level tag above is only honored when this
    // file runs as its own suite, which is what excluding it from the
    // optimized bundle achieves, so a passing run proves it was excluded and
    // then skipped by `--exclude-tags integration`.
    test('is never meant to run', () {
      fail('this test should have been excluded by its tag');
    });
  });
}
