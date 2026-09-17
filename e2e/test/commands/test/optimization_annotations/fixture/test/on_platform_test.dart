@OnPlatform({'vm': Skip('proves @OnPlatform reaches the optimized bundle')})
library;

import 'package:test/test.dart';

void main() {
  test('never runs on the vm', () {
    fail('@OnPlatform was dropped by the optimizer');
  });
}
