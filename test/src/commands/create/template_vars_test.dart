import 'package:mason/mason.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:very_good_cli/src/commands/create/commands/commands.dart';
import 'package:very_good_cli/src/commands/create/create.dart';

class _MockLogger extends Mock implements Logger;

void main() {
  group('template vars', () {
    final subcommands = CreateCommand(logger: _MockLogger()).subcommands.values
        .toSet()
        .cast<CreateSubCommand>();

    for (final subcommand in subcommands) {
      final templates = switch (subcommand) {
        MultiTemplates(:final templates) => templates,
        _ => [subcommand.template],
      };

      for (final template in templates) {
        final bundle = template.bundle;
        final bundleVars = bundle.vars.keys.toSet();
        final handledVars = subcommand.templateVarResolvers.keys.toSet();
        final defaultedVars = template.defaultedVars;
        final source =
            'very_good create ${subcommand.name} '
            '(template "${template.name}", bundle "${bundle.name}")';

        group('${subcommand.name} ${template.name}', () {
          test('handles every bundle var', () {
            expect(
              bundleVars.difference(handledVars).difference(defaultedVars),
              isEmpty,
              reason:
                  '$source does not pass these bundle vars. Add them to '
                  "${subcommand.runtimeType}'s templateVarResolvers, or to "
                  "${template.runtimeType}'s defaultedVars to keep the "
                  'template default.',
            );
          });

          test('only passes vars declared by the bundle', () {
            expect(
              handledVars.difference(bundleVars),
              isEmpty,
              reason:
                  '$source passes these vars, but the bundle does not '
                  'declare them. Remove them from '
                  "${subcommand.runtimeType}'s templateVarResolvers.",
            );
          });

          test('only defaults vars declared by the bundle', () {
            expect(
              defaultedVars.difference(bundleVars),
              isEmpty,
              reason:
                  '$source defaults these vars, but the bundle does not '
                  'declare them. Remove them from '
                  "${template.runtimeType}'s defaultedVars.",
            );
          });
        });
      }
    }
  });
}
