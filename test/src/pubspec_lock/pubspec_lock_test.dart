// ignore_for_file: prefer_const_constructors

import 'package:test/test.dart';
import 'package:very_good_cli/src/pubspec_lock/pubspec_lock.dart';

void main() {
  group('$PubspecLock', () {
    group('fromString', () {
      test('parses correctly', () {
        final pubspecLock = PubspecLock.fromString(_pubspecLockContent);

        expect(
          pubspecLock.packages,
          equals(
            const [
              PubspecLockPackage(
                name: 'very_good_test_runner',
                type: PubspecLockPackageDependencyType.directMain,
                isPubHosted: true,
              ),
              PubspecLockPackage(
                name: 'very_good_analysis',
                type: PubspecLockPackageDependencyType.directDev,
                isPubHosted: true,
              ),
              PubspecLockPackage(
                name: 'yaml',
                type: PubspecLockPackageDependencyType.transitive,
                isPubHosted: true,
              ),
              PubspecLockPackage(
                name: 'path',
                type: PubspecLockPackageDependencyType.directOverridden,
                isPubHosted: true,
              ),
              PubspecLockPackage(
                name: 'foo',
                type: PubspecLockPackageDependencyType.directMain,
                isPubHosted: false,
              ),
              PubspecLockPackage(
                name: 'yaml2',
                type: PubspecLockPackageDependencyType.transitive,
                isPubHosted: false,
              ),
            ],
          ),
        );
      });

      test('throws a $PubspecLockParseException when content is empty', () {
        expect(
          () => PubspecLock.fromString(''),
          throwsA(isA<PubspecLockParseException>()),
        );
      });

      test('returns empty PubspecLock when content has no packages entry', () {
        final pubspecLock = PubspecLock.fromString(_emptyPubspecLockContent);
        expect(pubspecLock.packages, isEmpty);
      });
    });
  });

  group('$PubspecLockPackage', () {
    test('can be instantiated', () {
      expect(
        PubspecLockPackage(
          name: 'foo',
          type: PubspecLockPackageDependencyType.directMain,
          isPubHosted: true,
        ),
        isA<PubspecLockPackage>(),
      );
    });

    test('supports value equality', () {
      final package1 = PubspecLockPackage(
        name: 'foo',
        type: PubspecLockPackageDependencyType.directMain,
        isPubHosted: true,
      );
      final package2 = PubspecLockPackage(
        name: 'foo',
        type: PubspecLockPackageDependencyType.directMain,
        isPubHosted: true,
      );
      final package3 = PubspecLockPackage(
        name: 'bar',
        type: PubspecLockPackageDependencyType.transitive,
        isPubHosted: false,
      );

      expect(package1, equals(package2));
      expect(package1, isNot(equals(package3)));
      expect(package2, isNot(equals(package3)));
    });
  });

  group('$PubspecLockPackageDependencyType', () {
    group('parse', () {
      test('parses successfully `direct main`', () {
        expect(
          PubspecLockPackageDependencyType.parse('direct main'),
          equals(PubspecLockPackageDependencyType.directMain),
        );
      });

      test('parses successfully `direct dev`', () {
        expect(
          PubspecLockPackageDependencyType.parse('direct dev'),
          equals(PubspecLockPackageDependencyType.directDev),
        );
      });

      test('parses successfully `direct overridden`', () {
        expect(
          PubspecLockPackageDependencyType.parse('direct overridden'),
          equals(PubspecLockPackageDependencyType.directOverridden),
        );
      });

      test('parses successfully `transitive`', () {
        expect(
          PubspecLockPackageDependencyType.parse('transitive'),
          equals(PubspecLockPackageDependencyType.transitive),
        );
      });

      test('throws a $ArgumentError when type is invalid', () {
        expect(
          () => PubspecLockPackageDependencyType.parse('invalid'),
          throwsA(isA<ArgumentError>()),
        );
      });
    });
  });
}

/// An example pubspec.lock content used to test the [PubspecLock] class.
///
/// It has been artificially crafted to include:
/// - one pub hosted direct package entry
/// - one pub hosted direct dev package entry
/// - one pub hosted transitive package entry
/// - one pub hosted overridden package entry
/// - one invalid package entry
/// - one not pub hosted transitive package entry
const _pubspecLockContent = '''
packages:
  very_good_test_runner:
    dependency: "direct main"
    description:
      name: very_good_test_runner
      sha256: "4d41e5d7677d259b9a1599c78645ac2d36bc2bd6ff7773507bcb0bab41417fe2"
      url: "https://pub.dev"
    source: hosted
    version: "0.1.2"
  very_good_analysis:
    dependency: "direct dev"
    description:
      name: very_good_analysis
      sha256: "9ae7f3a3bd5764fb021b335ca28a34f040cd0ab6eec00a1b213b445dae58a4b8"
      url: "https://pub.dev"
    source: hosted
    version: "5.1.0"
  yaml:
    dependency: transitive
    description:
      name: yaml
      sha256: "75769501ea3489fca56601ff33454fe45507ea3bfb014161abc3b43ae25989d5"
      url: "https://pub.dev"
    source: hosted
    version: "3.1.2"
  path:
    dependency: "direct overridden"
    description:
      name: path
      sha256: "087ce49c3f0dc39180befefc60fdb4acd8f8620e5682fe2476afd0b3688bb4af"
      url: "https://pub.dev"
    source: hosted
    version: "1.9.0"
  foo:
    dependency: "direct main"
    description:
      path: "packages/foo"
      relative: true
    source: path
    version: "1.0.0+1"
  yaml2:
    dependency: transitive
    description:
      name: yaml
      sha256: "75769501ea3489fca56601ff33454fe45507ea3bfb014161abc3b43ae25989d5"
      url: "https://not-pub.dev"
    source: hosted
    version: "3.1.2"
  bad_package:
    not_dependency: "bad"
sdks:
  dart: ">=3.1.0 <4.0.0"

''';

/// A valid pubspec lock file with no packages.
const _emptyPubspecLockContent = '''
sdks:
  dart: ">=3.1.0 <4.0.0"

''';
