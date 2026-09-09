@Tags(['excluded'])
library;

import 'package:test/test.dart';

void main() {
  test('tagged', () => fail('must never run'));
}
