import 'package:test/test.dart';
import 'package:test_api/hooks.dart';

void main() {
  test('runs inside the optimized bundle', () {
    expect(TestHandle.current.name, contains('passing_test.dart'));
  });
}
