@Timeout(Duration(milliseconds: 100))
library;

import 'package:test/test.dart';

void main() {
  test('outlives its file level timeout', () async {
    await Future<void>.delayed(const Duration(seconds: 2));
  });
}
