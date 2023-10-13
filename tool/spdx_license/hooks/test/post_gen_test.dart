import 'dart:io';

import 'package:mason/mason.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import '../post_gen.dart' as post_gen;

class _MockLogger extends Mock implements Logger {}

class _MockProgress extends Mock implements Progress {}

class _TestHookContext implements HookContext {
  _TestHookContext({required Logger logger}) : _logger = logger;

  final Logger _logger;

  @override
  Map<String, dynamic> vars = {};

  @override
  Logger get logger => _logger;
}

void main() {
  group('post gen', () {
    late HookContext context;
    late Logger logger;
    late Progress progress;

    setUpAll(() {
      registerFallbackValue('');
    });

    setUp(() {
      progress = _MockProgress();

      logger = _MockLogger();
      registerFallbackValue('');
      when(() => logger.progress(any())).thenReturn(progress);

      context = _TestHookContext(logger: logger);
    });

    test('runs dart formatter on generated file', () async {
      late final String capturedCommand;
      late final List<String> capturedArgs;
      late final bool capturedRunInShell;
      post_gen.processOverride = (
        command,
        args, {
        runInShell = true,
        workingDirectory = '',
      }) {
        capturedCommand = command;
        capturedArgs = args;
        capturedRunInShell = runInShell;
        return Future.value(ProcessResult(0, ExitCode.success.code, '', ''));
      };

      await post_gen.run(context);

      expect(capturedCommand, 'dart');
      expect(
        capturedArgs,
        ['format', path.join('test', 'spdx_license.gen.dart')],
      );
      expect(capturedRunInShell, true);
    });

    group('progress', () {
      setUp(() {
        post_gen.processOverride = (
          command,
          args, {
          runInShell = true,
          workingDirectory = '',
        }) =>
            Future.value(ProcessResult(0, ExitCode.success.code, '', ''));
      });

      tearDown(() {
        post_gen.processOverride = null;
      });

      test('logs formatting start', () async {
        await post_gen.run(context);

        verify(() => logger.progress('Formatting files')).called(1);
      });

      test('logs formatting complete', () async {
        await post_gen.run(context);

        verify(() => progress.complete()).called(1);
      });
    });
  });
}
