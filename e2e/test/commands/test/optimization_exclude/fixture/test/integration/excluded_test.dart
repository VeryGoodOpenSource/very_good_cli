import 'package:test/test.dart';
import 'package:test_api/hooks.dart';

void main() {
  group('optimization_exclude_fixture', () {
    test('runs as its own suite, outside the optimized bundle', () {
      expect(TestHandle.current.name, isNot(contains('excluded_test.dart')));
    });
  });
}
