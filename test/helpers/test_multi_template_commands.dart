import 'dart:io';

import 'package:args/args.dart';
import 'package:mason/mason.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:very_good_cli/src/commands/commands.dart';
import 'package:very_good_cli/src/logger_extension.dart';

class _MockArgResults extends Mock implements ArgResults {}

Future<void> testMultiTemplateCommand({
  required MultiTemplates multiTemplatesCommand,
  required String templateName,
  required Map<String, dynamic> mockArgs,
  required MasonGenerator generator,
  required Logger logger,
  required GeneratorHooks hooks,
  required Map<String, dynamic> expectedVars,
  required String expectedLogSummary,
  Directory? outputDirectoryOverride,
}) async {
  late final Directory outputDirectory;
  if (outputDirectoryOverride == null) {
    outputDirectory = Directory.systemTemp.createTempSync();
    addTearDown(() => outputDirectory.deleteSync(recursive: true));
  } else {
    outputDirectory = outputDirectoryOverride;
  }

  final argResults = _MockArgResults();
  final command = multiTemplatesCommand..argResultOverrides = argResults;

  when(() => argResults['template'] as String?).thenReturn(templateName);
  when(() => argResults['output-directory'] as String?)
      .thenReturn(outputDirectory.path);

  for (final entry in mockArgs.entries) {
    when(() => argResults[entry.key]).thenReturn(entry.value);
  }

  when(() => argResults.rest).thenReturn(['my_app']);

  final result = await command.run();

  expect(command.template.name, templateName);
  expect(result, equals(ExitCode.success.code));

  verify(() => logger.progress('Bootstrapping')).called(1);
  verify(
    () => hooks.preGen(
      vars: expectedVars,
      onVarsChanged: any(named: 'onVarsChanged'),
    ),
  );
  verify(
    () => generator.generate(
      any(),
      vars: expectedVars,
      logger: logger,
    ),
  ).called(1);
  verify(() => logger.created(expectedLogSummary)).called(1);
}
