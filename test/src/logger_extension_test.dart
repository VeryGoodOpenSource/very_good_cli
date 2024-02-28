import 'package:mason/mason.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:universal_io/io.dart';
import 'package:very_good_cli/src/logger_extension.dart';

class _MockLogger extends Mock implements Logger {}

class _MockStdout extends Mock implements Stdout {}

void main() {
  group('LoggerX', () {
    late Logger logger;
    late Stdout stdout;

    setUp(() {
      logger = _MockLogger();
      stdout = _MockStdout();

      when(() => stdout.hasTerminal).thenReturn(true);
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

      test(
        '''defaults to `fallbackStdoutTerminalColumns` when there is no terminal''',
        () async {
          await IOOverrides.runZoned(
            stdout: () => stdout,
            () async {
              when(() => stdout.hasTerminal).thenReturn(false);
              const stdoutException = StdoutException('');
              when(() => stdout.terminalColumns).thenThrow(stdoutException);

              final longWord = Iterable.generate(
                fallbackStdoutTerminalColumns,
                (_) => '1',
              ).join();
              const shortWord = '1';

              logger.wrap('$longWord $shortWord', print: logger.info);

              verifyInOrder([
                () => logger.info(
                      any(
                        that: equals('$longWord '),
                      ),
                    ),
                () => logger.info(
                      any(that: equals('$shortWord ')),
                    ),
              ]);
            },
          );
        },
      );

      test(
        '''defaults to `terminalColumns` when there is no length''',
        () async {
          await IOOverrides.runZoned(
            stdout: () => stdout,
            () async {
              when(() => stdout.hasTerminal).thenReturn(true);
              const terminalColumns = 50;
              when(() => stdout.terminalColumns).thenReturn(terminalColumns);

              final longWord = Iterable.generate(
                terminalColumns,
                (_) => '1',
              ).join();
              const shortWord = '1';

              logger.wrap('$longWord $shortWord', print: logger.info);

              verifyInOrder([
                () => logger.info(
                      any(
                        that: equals('$longWord '),
                      ),
                    ),
                () => logger.info(
                      any(that: equals('$shortWord ')),
                    ),
              ]);
            },
          );
        },
      );

      test(
        '''throws when an unknown exception occurs when reading `stdout.terminalColumns`''',
        () async {
          await IOOverrides.runZoned(
            stdout: () => stdout,
            () async {
              final unknownException = Exception();
              when(() => stdout.terminalColumns).thenThrow(unknownException);

              expect(
                () => logger.wrap('test', print: logger.info),
                throwsA(equals(unknownException)),
              );
            },
          );
        },
      );
    });
  });
}
