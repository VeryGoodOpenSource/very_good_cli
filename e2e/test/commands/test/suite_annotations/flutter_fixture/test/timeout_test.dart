@Timeout(Duration(minutes: 5))
library;

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('generous timeout', () => expect(1, equals(1)));
}
