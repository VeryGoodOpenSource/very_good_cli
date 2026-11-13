import 'package:test/test.dart';
import 'package:very_good_cli/src/cli/cli.dart';

void main() {
  group(TestRunResults, () {
    test('is empty by default', () {
      const results = TestRunResults();

      expect(results.passed, isZero);
      expect(results.skipped, isZero);
      expect(results.durationMs, isZero);
      expect(results.failingTests, isEmpty);
      expect(results.testsFailed, isFalse);
      expect(results.hasResults, isFalse);
    });

    test('has results once a test passed', () {
      expect(const TestRunResults(passed: 1).hasResults, isTrue);
    });

    test('has results once a test was skipped', () {
      expect(const TestRunResults(skipped: 1).hasResults, isTrue);
    });

    test('has failing tests once one was recorded', () {
      const results = TestRunResults(
        failingTests: [(file: 'a_test.dart', name: 'a', error: 'boom')],
      );

      expect(results.testsFailed, isTrue);
      expect(results.hasResults, isTrue);
    });

    test('merges counts, duration and failing tests across packages', () {
      const first = TestRunResults(
        passed: 1,
        skipped: 2,
        durationMs: 100,
        failingTests: [(file: 'a_test.dart', name: 'a', error: 'boom')],
      );
      const second = TestRunResults(
        passed: 3,
        skipped: 4,
        durationMs: 200,
        failingTests: [(file: 'b_test.dart', name: 'b', error: 'oops')],
      );

      final merged = first.merge(second);

      expect(merged.passed, equals(4));
      expect(merged.skipped, equals(6));
      expect(merged.durationMs, equals(300));
      expect(
        merged.failingTests,
        equals([
          (file: 'a_test.dart', name: 'a', error: 'boom'),
          (file: 'b_test.dart', name: 'b', error: 'oops'),
        ]),
      );
    });
  });

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

      expect(recorder.results, equals(const TestRunResults()));
      expect(recorder.testsFailed, isFalse);
      expect(recorder.hasResults, isFalse);
      expect(recorder.coverageNotMet, isNull);
    });

    test('accumulates the results of every package recorded into it', () {
      final recorder = TestRunRecorder()
        ..recordPackage(
          const TestRunResults(passed: 1, skipped: 2, durationMs: 100),
        )
        ..recordPackage(
          const TestRunResults(
            passed: 3,
            durationMs: 200,
            failingTests: [(file: 'a_test.dart', name: 'a', error: 'boom')],
          ),
        );

      expect(recorder.results.passed, equals(4));
      expect(recorder.results.skipped, equals(2));
      expect(recorder.results.durationMs, equals(300));
      expect(recorder.results.failingTests, hasLength(1));
      expect(recorder.testsFailed, isTrue);
      expect(recorder.hasResults, isTrue);
    });

    test('exposes immutable snapshots that a later recordPackage cannot '
        'mutate', () {
      final recorder = TestRunRecorder()
        ..recordPackage(const TestRunResults(passed: 1));

      final snapshot = recorder.results;
      recorder.recordPackage(const TestRunResults(passed: 2));

      expect(snapshot.passed, equals(1));
      expect(recorder.results.passed, equals(3));
    });
  });
}
