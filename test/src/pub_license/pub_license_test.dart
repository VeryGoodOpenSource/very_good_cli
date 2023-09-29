import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:very_good_cli/src/pub_license/pub_license.dart';

class _MockClient extends Mock implements http.Client {}

class _MockResponse extends Mock implements http.Response {}

void main() {
  group('PubLicense', () {
    test('can be instantiated', () {
      expect(PubLicense(), isA<PubLicense>());
    });

    group('getLicense', () {
      late http.Client client;
      late http.Response response;

      setUpAll(() {
        registerFallbackValue(Uri.parse('https://vgv.dev/'));
      });

      setUp(() {
        response = _MockResponse();
        when(() => response.statusCode).thenReturn(200);

        client = _MockClient();
        when(() => client.get(any())).thenAnswer((_) async => response);
      });

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
    });
  });
}
