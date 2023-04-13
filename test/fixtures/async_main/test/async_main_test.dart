@Tags(['e2e'])
library async_main_test;

// ignore_for_file: prefer_const_constructors
import 'package:test/test.dart';

void main() async {
  group('AsyncMain', () {
    test('will succeed', () {
      expect(true, equals(!false));
    });
  });
}
