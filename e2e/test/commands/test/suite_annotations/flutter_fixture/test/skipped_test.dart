@Skip('not ready')
library;

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('skipped', () => fail('must never run'));
}
