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

class _MockLogger extends Mock implements Logger {}

class _MockProgress extends Mock implements Progress {}

void main() {
  group('Dart', () {
    late ProcessResult processResult;
    late _TestProcess process;
    late Logger logger;
    late Progress progress;

    setUp(() {
      logger = _MockLogger();
      progress = _MockProgress();
      when(() => logger.progress(any())).thenReturn(progress);

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

    group('.installed', () {
      test('returns true when dart is installed', () {
        ProcessOverrides.runZoned(
          () => expectLater(Dart.installed(logger: logger), completion(isTrue)),
          runProcess: process.run,
        );
      });

      test('returns false when dart is not installed', () {
        when(() => processResult.exitCode).thenReturn(ExitCode.software.code);
        ProcessOverrides.runZoned(
          () =>
              expectLater(Dart.installed(logger: logger), completion(isFalse)),
          runProcess: process.run,
        );
      });
    });

    group('.applyFixes', () {
      test('completes normally', () {
        ProcessOverrides.runZoned(
          () => expectLater(Dart.applyFixes(logger: logger), completes),
          runProcess: process.run,
        );
      });
    });
  });
}
