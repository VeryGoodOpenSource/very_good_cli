import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:http/http.dart' as http;
import 'package:mason/mason.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../pre_gen.dart' as pre_gen;

class _MockClient extends Mock implements http.Client {}

class _MockResponse extends Mock implements http.Response {}

class _MockZipDecoder extends Mock implements ZipDecoder {}

class _MockArchive extends Mock implements Archive {}

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
  group('pre_gen', () {
    late HookContext context;
    late http.Client client;
    late http.Response response;
    late Logger logger;
    late Progress progress;
    late ZipDecoder zipDecoder;
    late Archive archive;

    setUp(() {
      progress = _MockProgress();

      logger = _MockLogger();
      registerFallbackValue('');
      when(() => logger.progress(any())).thenReturn(progress);

      context = _TestHookContext(logger: logger);

      response = _MockResponse();
      when(() => response.statusCode).thenReturn(200);

      client = _MockClient();
      registerFallbackValue(Uri());
      when(() => client.get(any())).thenAnswer((_) async => response);

      zipDecoder = _MockZipDecoder();

      archive = _MockArchive();
    });

    group('run', () {
      test('downloads licenses successfully', tags: ['pull-request-only'],
          () async {
        await pre_gen.run(context);

        expect(context.vars['total'], greaterThan(0));
        expect(
          (context.vars['licenses'] as List).length,
          equals(context.vars['total']),
        );
      });
    });

    group('sets vars correctly', () {
      test('when licenses are provided', () async {
        context.vars['licenses'] = ['MIT', 'BSD'];

        await pre_gen.preGen(context);

        expect(context.vars['total'], 2);
        expect(context.vars['licenses'], [
          {'license': 'MIT', 'identifier': r'$MIT'},
          {'license': 'BSD', 'identifier': r'$BSD'},
        ]);
      });

      test('with valid Dart identifiers', () async {
        const name = '     0+.M I-T     ';
        context.vars['licenses'] = [name];

        await pre_gen.preGen(context);

        expect(context.vars['total'], 1);
        expect(context.vars['licenses'], [
          {'license': name, 'identifier': r'$0plus_MI_T'},
        ]);
      });
    });

    group('progress', () {
      test('starts with valid message', () async {
        when(() => response.statusCode).thenReturn(404);

        await pre_gen.preGen(context, client: client);

        const message =
            '''Starting to download the SPDX license list, this might take some time''';
        verify(() => logger.progress(message)).called(1);
      });

      test('completes when finished decoding', () async {
        final bodyBytes = Uint8List.fromList([]);
        when(() => response.bodyBytes).thenReturn(bodyBytes);
        when(() => zipDecoder.decodeBytes(bodyBytes)).thenReturn(archive);
        when(() => archive.files).thenReturn([]);

        await pre_gen.preGen(
          context,
          client: client,
          zipDecoder: zipDecoder,
        );

        verify(() => progress.complete('Found 0 SPDX licenses')).called(1);
      });

      group('is cancelled', () {
        test('when fails to download list', () async {
          when(() => response.statusCode).thenReturn(404);

          await pre_gen.preGen(context, client: client);

          verify(() => progress.cancel()).called(1);
        });

        test('when fails to decode list', () async {
          final bodyBytes = Uint8List.fromList([]);
          when(() => response.bodyBytes).thenReturn(bodyBytes);
          when(() => zipDecoder.decodeBytes(bodyBytes)).thenThrow('error');

          await pre_gen.preGen(
            context,
            client: client,
            zipDecoder: zipDecoder,
          );

          verify(() => progress.cancel()).called(1);
        });
      });
    });

    group('logs', () {
      test('when fails to download list', () async {
        when(() => response.statusCode).thenReturn(404);

        await pre_gen.preGen(context, client: client);

        final errorMessage =
            '''[spdx_license] Failed to download the SPDX license list, received response with status code: ${response.statusCode}''';

        verify(() => context.logger.err(errorMessage)).called(1);
      });

      test('when fails to decode list', () async {
        final bodyBytes = Uint8List.fromList([]);
        when(() => response.bodyBytes).thenReturn(bodyBytes);
        const error = 'an error';
        when(() => zipDecoder.decodeBytes(bodyBytes)).thenThrow(error);

        await pre_gen.preGen(
          context,
          client: client,
          zipDecoder: zipDecoder,
        );

        const errorMessage =
            '''[spdx_license] Failed to decode the SPDX license list, received error: $error''';

        verify(() => context.logger.err(errorMessage)).called(1);
      });

      test('when an unknown error is raised', () async {
        const error = 'error';
        when(() => client.get(any())).thenThrow(error);

        await pre_gen.preGen(context, client: client);

        verify(
          () => context.logger.err(
            '[spdx_license] An unknown error occurred, received error: $error',
          ),
        ).called(1);
      });
    });
  });
}
