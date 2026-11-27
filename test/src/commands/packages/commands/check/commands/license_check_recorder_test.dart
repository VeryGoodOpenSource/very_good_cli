import 'package:test/test.dart';
import 'package:very_good_cli/src/commands/packages/commands/check/commands/commands.dart';

void main() {
  group(LicenseCheckRecorder, () {
    test('is null outside of a zone', () {
      expect(LicenseCheckRecorder.current, isNull);
    });

    test('is the recorder of the zone it runs in', () async {
      final recorder = LicenseCheckRecorder();

      await LicenseCheckRecorder.runZoned(() async {
        await Future<void>.delayed(Duration.zero);
        expect(LicenseCheckRecorder.current, same(recorder));
      }, recorder: recorder);

      expect(LicenseCheckRecorder.current, isNull);
    });

    test('records nothing by default', () {
      expect(LicenseCheckRecorder().bannedDependencies, isNull);
    });

    test('records the banned dependencies and their licenses', () {
      final recorder = LicenseCheckRecorder()
        ..recordBannedDependencies({
          'foo': {'GPL-3.0-only'},
          'bar': {'MIT', 'BSD-3-Clause'},
        });

      expect(
        recorder.bannedDependencies,
        equals({
          'foo': {'GPL-3.0-only'},
          'bar': {'MIT', 'BSD-3-Clause'},
        }),
      );
    });

    test('exposes an unmodifiable copy of the banned dependencies', () {
      final banned = {
        'foo': {'GPL-3.0-only'},
      };
      final recorder = LicenseCheckRecorder()..recordBannedDependencies(banned);
      banned['bar'] = {'MIT'};
      banned['foo']!.add('MIT');

      final recorded = recorder.bannedDependencies!;
      expect(
        recorded,
        equals({
          'foo': {'GPL-3.0-only'},
        }),
      );
      expect(() => recorded['bar'] = {'MIT'}, throwsUnsupportedError);
      expect(() => recorded['foo']!.add('MIT'), throwsUnsupportedError);
    });

    test('replaces previously recorded banned dependencies', () {
      final recorder = LicenseCheckRecorder()
        ..recordBannedDependencies({
          'foo': {'MIT'},
        })
        ..recordBannedDependencies({
          'bar': {'BSD-3-Clause'},
        });

      expect(
        recorder.bannedDependencies,
        equals({
          'bar': {'BSD-3-Clause'},
        }),
      );
    });
  });
}
