import 'package:test/test.dart';
import 'package:universal_io/io.dart';
import 'package:very_good_cli/src/cli/cli.dart';

class _FakeProcess {
  Future<ProcessResult> run(
    String command,
    List<String> args, {
    bool runInShell = false,
    String? workingDirectory,
  }) {
    throw UnimplementedError();
  }
}

void main() {
  group('ProcessOverrides', () {
    group('runZoned', () {
      test('uses default Process.run when not specified', () {
        ProcessOverrides.runZoned(() {
          final overrides = ProcessOverrides.current;
          expect(overrides!.runProcess, isA<Function>());
        });
      });

      test('uses custom Process.run when specified', () {
        final process = _FakeProcess();
        ProcessOverrides.runZoned(
          () {
            final overrides = ProcessOverrides.current;
            expect(overrides!.runProcess, equals(process.run));
          },
          runProcess: process.run,
        );
      });

      test(
          'uses current Process.run when not specified '
          'and zone already contains a Process.run', () {
        final process = _FakeProcess();
        ProcessOverrides.runZoned(
          () {
            ProcessOverrides.runZoned(() {
              final overrides = ProcessOverrides.current;
              expect(overrides!.runProcess, equals(process.run));
            });
          },
          runProcess: process.run,
        );
      });

      test(
          'uses nested Process.run when specified '
          'and zone already contains a Process.run', () {
        final rootProcess = _FakeProcess();
        ProcessOverrides.runZoned(
          () {
            final nestedProcess = _FakeProcess();
            final overrides = ProcessOverrides.current;
            expect(overrides!.runProcess, equals(rootProcess.run));
            ProcessOverrides.runZoned(
              () {
                final overrides = ProcessOverrides.current;
                expect(overrides!.runProcess, equals(nestedProcess.run));
              },
              runProcess: nestedProcess.run,
            );
          },
          runProcess: rootProcess.run,
        );
      });
    });
  });
}
