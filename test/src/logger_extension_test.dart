import 'package:mason/mason.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:very_good_cli/src/logger_extension.dart';

class _MockLogger extends Mock implements Logger {}

void main() {
  group('LoggerX', () {
    late Logger logger;

    setUp(() {
      logger = _MockLogger();
    });

    test('created', () {
      logger.created('test');

      verify(
        () => logger.info(
          any(that: equals(lightCyan.wrap(styleBold.wrap('test')))),
        ),
      ).called(1);
    });

    group('wrap', () {
      test('normally across two separate prints', () {
        logger.wrap('1 2 3 4 5 1 2 3 4 5', print: logger.info, length: 10);

        verifyInOrder([
          () => logger.info(any(that: equals('1 2 3 4 5 '))),
          () => logger.info(any(that: equals('1 2 3 4 5 '))),
        ]);
      });

      test('across two separate prints while not adding in ANSI encoding', () {
        logger.wrap(
          '${lightCyan.wrap('1 2 3 4 5')} 1 2 3 4 5',
          print: logger.info,
          length: 10,
        );

        verifyInOrder([
          () => logger.info(any(that: equals(lightCyan.wrap('1 2 3 4 5 ')))),
          () => logger.info(any(that: equals('1 2 3 4 5 '))),
        ]);
      });
    });
  });
}
