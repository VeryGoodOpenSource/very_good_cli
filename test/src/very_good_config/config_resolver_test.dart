import 'package:args/args.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:very_good_cli/src/very_good_config/config_resolver.dart';

class _MockArgResults extends Mock implements ArgResults {}

void main() {
  group('$ConfigResolver', () {
    late ArgResults argResults;
    late ConfigResolver resolver;

    setUp(() {
      argResults = _MockArgResults();
      resolver = ConfigResolver(argResults);
    });

    test('uses the config value when the argument was not parsed', () {
      when(() => argResults.wasParsed('min-coverage')).thenReturn(false);

      expect(resolver.resolve<String?>('min-coverage', '90'), '90');
    });

    test('uses the parsed argument over the config value', () {
      when(() => argResults.wasParsed('min-coverage')).thenReturn(true);
      when<dynamic>(() => argResults['min-coverage']).thenReturn('50');

      expect(resolver.resolve<String?>('min-coverage', '90'), '50');
    });

    test('uses the argument value when there is no config value', () {
      when(() => argResults.wasParsed('tags')).thenReturn(false);
      when<dynamic>(() => argResults['tags']).thenReturn('unit');

      expect(resolver.resolve<String?>('tags', null), 'unit');
    });

    test('falls back when neither argument nor config provide a value', () {
      when(
        () => argResults.wasParsed('collect-coverage-from'),
      ).thenReturn(false);
      when<dynamic>(() => argResults['collect-coverage-from']).thenReturn(null);

      expect(
        resolver.resolve<String>(
          'collect-coverage-from',
          null,
          fallbackValue: 'imports',
        ),
        'imports',
      );
    });
  });
}
