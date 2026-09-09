@Skip('not ready')
library;

import 'package:test/test.dart';

void main() {
  test('skipped', () => fail('must never run'));
}
