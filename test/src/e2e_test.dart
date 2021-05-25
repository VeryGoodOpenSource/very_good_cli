import 'package:test/test.dart';
import 'package:path/path.dart' as path;
import 'package:universal_io/io.dart';
import 'package:very_good_cli/src/command_runner.dart';

void main() {
  final destination = path.join('.tmp', 'my_app');

  void _resetEnvironment() {
    try {
      Directory(destination).deleteSync(recursive: true);
    } catch (_) {}
  }

  group('Very Good Create', () {
    setUp(_resetEnvironment);

    tearDownAll(_resetEnvironment);

    test('e2e', () async {
      final runner = VeryGoodCommandRunner();
      final runExitCode = await runner.run(['create', destination]);
      expect(runExitCode, equals(0));
    });
  });
}
