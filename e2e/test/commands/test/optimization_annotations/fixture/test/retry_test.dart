@Retry(1)
library;

import 'package:test/test.dart';

var _attempts = 0;

void main() {
  test('passes only on the retry', () {
    _attempts++;
    if (_attempts == 1) fail('@Retry was dropped by the optimizer');
  });
}
