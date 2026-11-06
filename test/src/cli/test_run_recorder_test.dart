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

      expect(recorder.testsFailed, isFalse);
      expect(recorder.coverageNotMet, isNull);
    });
  });
}
