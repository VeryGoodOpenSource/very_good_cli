@Timeout(Duration(milliseconds: 100))
library;

import 'package:test/test.dart';

void main() {
  test(
    'outlives its timeout',
    () => Future<void>.delayed(const Duration(seconds: 1)),
  );
}
