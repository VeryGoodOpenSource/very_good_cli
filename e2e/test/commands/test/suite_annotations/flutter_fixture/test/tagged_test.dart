@Tags(['excluded'])
library;

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tagged', () => fail('must never run'));
}
