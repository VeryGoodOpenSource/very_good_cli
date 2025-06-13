import 'dart:async';
import 'dart:io';

import 'package:mason/mason.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../post_gen.dart' as post_gen;

class _MockHookContext extends Mock implements HookContext {}

class _MockLogger extends Mock implements Logger {}

class _MockProgress extends Mock implements Progress {}

void main() {
  group('post_gen', () {
    late HookContext context;
    late Logger logger;
    late Progress progress;
    late ProcessResult processResult;

    setUp(() {
      context = _MockHookContext();

      logger = _MockLogger();
      when(() => context.logger).thenReturn(logger);

      progress = _MockProgress();
      when(() => logger.progress(any())).thenReturn(progress);

      processResult = ProcessResult(0, ExitCode.success.code, null, null);
    });

    test('logs progress', () async {
      final formatCompleter = Completer<void>();

      Future<ProcessResult> runProcess(
        String executable,
        List<String> arguments, {
        String? workingDirectory,
        bool runInShell = false,
      }) async {
        switch (arguments.first) {
          case 'format':
            await formatCompleter.future;
        }
        return processResult;
      }

      final postGen = post_gen.run(context, runProcess: runProcess);

      verify(() => logger.progress('Formatting files...')).called(1);

      formatCompleter.complete();
      await Future<void>.delayed(Duration.zero);

      verify(() => progress.complete('Completed post generation')).called(1);

      await postGen;
    });
  });
}
