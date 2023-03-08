@Tags(['minDartSdk'])
library min_dart_sdk_test;

import 'dart:io';

import 'package:mason/mason.dart';
import 'package:path/path.dart' as path;
import 'package:pubspec_parse/pubspec_parse.dart';
import 'package:test/test.dart';

import '../../../../helpers/helpers.dart';

void main() {
  test(
    'runs on minimum dart SDK',
    timeout: const Timeout(Duration(minutes: 2)),
    withRunner(
      (commandRunner, logger, updater, logs) async {
        final workingDirectory = Directory.current;
        final pubspecPath = path.join(workingDirectory.path, 'pubspec.yaml');
        final pubspec = Pubspec.parse(File(pubspecPath).readAsStringSync());

        final dartSdkVersionConstraint = pubspec.environment!['sdk']!;
        final minDartSdkVersion =
            (dartSdkVersionConstraint as VersionRange).min;

        final dartVersionResult = await Process.run(
          'dart',
          ['--version'],
        );
        final runningDartSdkVersion = Version.parse(
          // Current output of dart --version follows the format:
          // `Dart SDK version: 2.19.2 (stable) (Tue Feb 7 18:37:17 2023 +0000)`
          dartVersionResult.stdout.toString().split(' ')[3],
        );
        expect(
          runningDartSdkVersion,
          equals(minDartSdkVersion),
          reason: 'To ensure compatibility, the supported minimum Dart SDK '
              '($minDartSdkVersion) version should be used instead of '
              '($runningDartSdkVersion) to run this test.',
        );

        final directory = Directory.systemTemp.createTempSync('async_main');
        await copyDirectory(
          Directory('test/fixtures/async_main'),
          directory,
        );

        final pubGetResult = await Process.run(
          'flutter',
          ['pub', 'get'],
          workingDirectory: directory.path,
          runInShell: true,
        );

        expect(pubGetResult.exitCode, equals(ExitCode.success.code));
        final result = await commandRunner.run(['test', directory.path]);
        expect(result, equals(ExitCode.success.code));
      },
    ),
  );
}
