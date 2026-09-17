@TestOn('browser')
library;

import 'package:test/test.dart';

void main() {
  test('never runs on the vm', () {
    fail('@TestOn was dropped by the optimizer');
  });
}
