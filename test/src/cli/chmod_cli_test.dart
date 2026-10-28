import 'package:mason/mason.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:universal_io/io.dart';
import 'package:very_good_cli/src/cli/cli.dart';

class _TestProcess {
  Future<ProcessResult> run(
    String command,
    List<String> args, {
    bool runInShell = false,
    String? workingDirectory,
  }) {
    throw UnimplementedError();
  }
}

class _MockProcess extends Mock implements _TestProcess;

class _MockLogger extends Mock implements Logger;

void main() {
  final successProcessResult = ProcessResult(42, ExitCode.success.code, '', '');

  group('Chmod', () {
    late _TestProcess process;
    late Logger logger;

    setUp(() {
      logger = _MockLogger();

      process = _MockProcess();
      when(
        () => process.run(
          any(),
          any(),
          runInShell: any(named: 'runInShell'),
          workingDirectory: any(named: 'workingDirectory'),
        ),
      ).thenAnswer((_) async => successProcessResult);
    });

    group('makeExecutable', () {
      test('runs chmod +x on the given paths', () async {
        await ProcessOverrides.runZoned(() async {
          await Chmod.makeExecutable(['a.dart', 'b.dart'], logger: logger);
        }, runProcess: process.run);

        verify(
          () => process.run(
            'chmod',
            ['+x', 'a.dart', 'b.dart'],
            runInShell: any(named: 'runInShell'),
            workingDirectory: any(named: 'workingDirectory'),
          ),
        ).called(1);
      });
    });
  });
}
