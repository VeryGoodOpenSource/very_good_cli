@Tags(['integration'])
library;

import 'package:test/test.dart';

void main() {
  test('never runs, --exclude-tags drops the integration tag', () {
    fail('@Tags was dropped by the optimizer');
  });
}
