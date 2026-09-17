@Tags(['slow'])
library;

import 'package:test/test.dart';

void main() {
  test('never runs, dart_test.yaml skips the slow tag', () {
    fail('@Tags was dropped by the optimizer');
  });
}
