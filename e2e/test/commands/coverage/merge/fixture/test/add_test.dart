import 'package:coverage_merge_fixture/src/add.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('add', () {
    expect(add(4, 2), equals(4 + 2));
  });
}
