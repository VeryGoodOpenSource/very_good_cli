import 'package:coverage_merge_fixture/src/subtract.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('subtract', () {
    expect(subtract(4, 2), equals(4 - 2));
  });
}
