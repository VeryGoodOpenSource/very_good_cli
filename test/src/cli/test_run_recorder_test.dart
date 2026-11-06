import 'package:test/test.dart';
import 'package:very_good_cli/src/cli/cli.dart';

void main() {
  group(TestRunRecorder, () {
    test('is null outside of a zone', () {
      expect(TestRunRecorder.current, isNull);
    });

    test('is the recorder of the zone it runs in', () async {
      final recorder = TestRunRecorder();

      await TestRunRecorder.runZoned(() async {
        await Future<void>.delayed(Duration.zero);
        expect(TestRunRecorder.current, same(recorder));
      }, recorder: recorder);

      expect(TestRunRecorder.current, isNull);
    });

    test('records nothing by default', () {
      final recorder = TestRunRecorder();

      expect(recorder.passed, isZero);
      expect(recorder.skipped, isZero);
      expect(recorder.durationMs, isZero);
      expect(recorder.failingTests, isEmpty);
      expect(recorder.testsFailed, isFalse);
      expect(recorder.hasResults, isFalse);
      expect(recorder.coverageNotMet, isNull);
    });

    test('has results once a test passed', () {
      expect((TestRunRecorder()..passed = 1).hasResults, isTrue);
    });

    test('has results once a test was skipped', () {
      expect((TestRunRecorder()..skipped = 1).hasResults, isTrue);
    });

    test('has failing tests once one was recorded', () {
      final recorder = TestRunRecorder()
        ..failingTests.add((file: 'a_test.dart', name: 'a', error: 'boom'));

      expect(recorder.testsFailed, isTrue);
      expect(recorder.hasResults, isTrue);
    });
  });
}
