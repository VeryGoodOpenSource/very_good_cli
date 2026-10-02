import 'package:coverage_merge_fixture/src/multiply.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('multiply', () {
    expect(multiply(4, 2), equals(4 * 2));
  });
}
