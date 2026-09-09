@TestOn('browser')
library;

import 'package:test/test.dart';

void main() {
  test('browser only', () => fail('must never run'));
}
