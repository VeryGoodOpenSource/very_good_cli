import 'package:test/test.dart';
import 'package:very_good_cli/src/cli/cli.dart';

void main() {
  group('Dart', () {
    group('.installed', () {
      test('returns true when dart is installed', () {
        expectLater(Dart.installed(), completion(isTrue));
      });
    });

    group('.applyFixes', () {
      test('completes normally', () {
        expectLater(Dart.applyFixes(), completes);
      });
    });
  });
}
