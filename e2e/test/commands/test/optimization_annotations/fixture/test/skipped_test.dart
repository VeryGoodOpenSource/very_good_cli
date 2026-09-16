@Skip('proves @Skip reaches the optimized bundle')
library;

import 'package:test/test.dart';

void main() {
  test('never runs', () {
    fail('@Skip was dropped by the optimizer');
  });
}
