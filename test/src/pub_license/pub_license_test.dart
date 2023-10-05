import 'dart:io';

import 'package:html/dom.dart' as html_dom;
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:very_good_cli/src/pub_license/pub_license.dart';

class _MockClient extends Mock implements http.Client {}

class _MockResponse extends Mock implements http.Response {}

class _MockParseError extends Mock implements html_parser.ParseError {
  @override
  String toString({dynamic color}) => super.toString();
}

class _MockDocument extends Mock implements html_dom.Document {}

class _MockElement extends Mock implements html_dom.Element {}

void main() {
  group('PubLicense', () {
    late http.Client client;
    late http.Response response;

    setUpAll(() {
      registerFallbackValue(Uri.parse('https://vgv.dev/'));
    });

    setUp(() {
      response = _MockResponse();
      when(() => response.statusCode).thenReturn(200);
      when(() => response.body).thenReturn('');

      client = _MockClient();
      when(() => client.get(any())).thenAnswer((_) async => response);
    });

    test('can be instantiated', () {
      expect(PubLicense(), isA<PubLicense>());
    });

    group('getLicense', () {
      group('returns as expected', () {
        String fixturePath(String name) => path.joinAll([
              Directory.current.path,
              'test',
              'src',
              'pub_license',
              'fixtures',
              '$name.html',
            ]);

        test('when parsing a single license fixture', () async {
          final fixture = File(fixturePath('singleLicense')).readAsStringSync();
          when(() => response.body).thenReturn(fixture);

          final pubLicense = PubLicense(client: client);
          final license = await pubLicense.getLicense('very_good_cli');

          expect(license.length, equals(1));
          expect(license.first, equals('MIT'));
        });

        test('when parsing a multiple license fixture', () async {
          final fixture =
              File(fixturePath('multipleLicense')).readAsStringSync();
          when(() => response.body).thenReturn(fixture);

          final pubLicense = PubLicense(client: client);
          final license = await pubLicense.getLicense('just_audio');

          expect(license.length, equals(2));
          expect(license.first, equals('Apache-2.0'));
          expect(license.last, equals('MIT'));
        });

        test('when parsing a no license fixture', () async {
          final fixture = File(fixturePath('noLicense')).readAsStringSync();
          when(() => response.body).thenReturn(fixture);

          final pubLicense = PubLicense(client: client);
          final license = await pubLicense.getLicense(
            'music_control_notification',
          );

          expect(license.length, equals(1));
          expect(license.first, equals('unknown'));
        });
      });

      group('throws a PubLicenseException', () {
        test('when statusCode is not 200', () async {
          when(() => response.statusCode).thenReturn(404);

          final pubLicense = PubLicense(client: client);

          final errorMessage =
              '''[pub_license] Failed to retrieve the license of the package, received status code: ${response.statusCode}''';
          await expectLater(
            () => pubLicense.getLicense('very_good_cli'),
            throwsA(
              isA<PubLicenseException>().having(
                (exception) => exception.message,
                'message',
                equals(errorMessage),
              ),
            ),
          );
        });

        group('when parsing fails', () {
          test('with a ParseError', () async {
            final parseError = _MockParseError();
            final pubLicense = PubLicense(
              client: client,
              parse: (input, {encoding, generateSpans = true, sourceUrl}) =>
                  throw parseError,
            );

            final errorMessage =
                '''[pub_license] Failed to parse the response body, received error: $parseError''';
            await expectLater(
              () => pubLicense.getLicense('very_good_cli'),
              throwsA(
                isA<PubLicenseException>().having(
                  (exception) => exception.message,
                  'message',
                  equals(errorMessage),
                ),
              ),
            );
          });

          test('with an unexpected error', () async {
            const error = 'unexpected error';
            final pubLicense = PubLicense(
              client: client,
              parse: (input, {encoding, generateSpans = true, sourceUrl}) =>
                  // ignore: only_throw_errors
                  throw error,
            );

            const errorMessage =
                '''[pub_license] An unknown error occurred when trying to parse the response body, received error: $error''';
            await expectLater(
              () => pubLicense.getLicense('very_good_cli'),
              throwsA(
                isA<PubLicenseException>().having(
                  (exception) => exception.message,
                  'message',
                  equals(errorMessage),
                ),
              ),
            );
          });
        });

        group('when scraping fails', () {
          late html_dom.Document document;
          late html_dom.Element element;

          setUp(() {
            document = _MockDocument();
            element = _MockElement();
          });

          test('due to missing `.detail-info-box`', () async {
            when(() => document.querySelector('.detail-info-box'))
                .thenReturn(null);

            final pubLicense = PubLicense(
              client: client,
              parse: (input, {encoding, generateSpans = true, sourceUrl}) =>
                  document,
            );

            const errorMessage =
                '''[pub_license] Failed to scrape license because `.detail-info-box` was not found.''';
            await expectLater(
              () => pubLicense.getLicense('very_good_cli'),
              throwsA(
                isA<PubLicenseException>().having(
                  (exception) => exception.message,
                  'message',
                  equals(errorMessage),
                ),
              ),
            );
          });

          test('due to missing license header', () async {
            when(() => document.querySelector('.detail-info-box'))
                .thenReturn(element);
            when(() => element.children).thenReturn([]);

            final pubLicense = PubLicense(
              client: client,
              parse: (input, {encoding, generateSpans = true, sourceUrl}) =>
                  document,
            );

            const errorMessage =
                '''[pub_license] Failed to scrape license because the license header was not found.''';
            await expectLater(
              () => pubLicense.getLicense('very_good_cli'),
              throwsA(
                isA<PubLicenseException>().having(
                  (exception) => exception.message,
                  'message',
                  equals(errorMessage),
                ),
              ),
            );
          });
        });
      });
    });
  });
}
