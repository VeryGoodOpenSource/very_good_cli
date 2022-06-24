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

class _MockProcess extends Mock implements _TestProcess {}

class _MockProcessResult extends Mock implements ProcessResult {}

void main() {
  group('Git', () {
    late ProcessResult processResult;
    late _TestProcess process;

    setUp(() {
      processResult = _MockProcessResult();
      process = _MockProcess();
      when(() => processResult.exitCode).thenReturn(ExitCode.success.code);
      when(
        () => process.run(
          any(),
          any(),
          runInShell: any(named: 'runInShell'),
          workingDirectory: any(named: 'workingDirectory'),
        ),
      ).thenAnswer((_) async => processResult);
    });

    group('reachable', () {
      test('completes for a reachable remote', () async {
        await ProcessOverrides.runZoned(
          () async {
            await expectLater(
              Git.reachable(Uri.parse('https://github.com/org/repo')),
              completes,
            );
          },
          runProcess: process.run,
        );
      });

      test(
          'throws UnreachableGitDependency '
          'for an unreachable remote', () async {
        when(() => processResult.exitCode).thenReturn(ExitCode.software.code);
        await ProcessOverrides.runZoned(
          () async {
            await expectLater(
              Git.reachable(Uri.parse('https://github.com/org/repo')),
              throwsA(isA<UnreachableGitDependency>()),
            );
          },
          runProcess: process.run,
        );
      });
    });

    group('UnreachableGitDependency', () {
      test('has correct toString override', () {
        final remote = Uri.parse('https://github.com/org/repo');
        final exception = UnreachableGitDependency(remote: remote);
        expect(
          exception.toString(),
          equals(
            '''
$remote is unreachable.
Make sure the remote exists and you have the correct access rights.''',
          ),
        );
      });
    });
  });
}
