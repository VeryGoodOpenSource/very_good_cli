import 'package:mason/mason.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:universal_io/io.dart';

import '../../../../helpers/helpers.dart';

void main() {
  test(
    'create flutter_plugin',
    timeout: const Timeout(Duration(minutes: 8)),
    withRunner((commandRunner, logger, updater, logs, progressLogs) async {
      final tempDirectory = Directory.systemTemp.createTempSync();
      addTearDown(() => tempDirectory.deleteSync(recursive: true));

      const pluginName = 'my_plugin';
      final pluginDirectory = path.join(tempDirectory.path, pluginName);

      final result = await commandRunner.run([
        'create',
        'flutter_plugin',
        pluginName,
        '-o',
        tempDirectory.path,
      ]);
      expect(
        result,
        equals(ExitCode.success.code),
        reason: '`very_good create flutter_plugin` failed with $result',
      );

      await expectSuccessfulProcessResult('dart', [
        'format',
      ], workingDirectory: pluginDirectory);

      // Verify pigeon generated messages.g.dart for each platform that has a
      // pigeon input file. The check is conditional so it passes when the
      // fallback bundle (without pigeon) is used.
      const pigeonPlatforms = ['android', 'ios', 'linux', 'macos', 'windows'];
      for (final platform in pigeonPlatforms) {
        final pigeonInput = File(
          path.join(
            pluginDirectory,
            '${pluginName}_$platform',
            'pigeons',
            'messages.dart',
          ),
        );
        if (pigeonInput.existsSync()) {
          final messagesFile = File(
            path.join(
              pluginDirectory,
              '${pluginName}_$platform',
              'lib',
              'src',
              'messages.g.dart',
            ),
          );
          expect(
            messagesFile.existsSync(),
            isTrue,
            reason: 'pigeon did not generate ${messagesFile.path}',
          );
        }
      }

      final analyzeResult = await expectSuccessfulProcessResult('flutter', [
        'analyze',
        '.',
      ], workingDirectory: pluginDirectory);
      expect(analyzeResult.stdout, contains('No issues found!'));

      final packageDirectories = [
        path.join(pluginDirectory, pluginName),
        path.join(pluginDirectory, '${pluginName}_android'),
        path.join(pluginDirectory, '${pluginName}_ios'),
        path.join(pluginDirectory, '${pluginName}_linux'),
        path.join(pluginDirectory, '${pluginName}_macos'),
        path.join(pluginDirectory, '${pluginName}_web'),
        path.join(pluginDirectory, '${pluginName}_windows'),
        path.join(pluginDirectory, '${pluginName}_platform_interface'),
      ];

      for (final packageDirectory in packageDirectories) {
        final testResult = await expectSuccessfulProcessResult('flutter', [
          'test',
          '--no-pub',
          '--coverage',
          '--reporter',
          'compact',
        ], workingDirectory: packageDirectory);
        expect(testResult.stdout, contains('All tests passed!'));

        final messagesGenFile = File(
          path.join(packageDirectory, 'lib', 'src', 'messages.g.dart'),
        );
        if (messagesGenFile.existsSync()) {
          await expectSuccessfulProcessResult(
            'lcov',
            [
              '--remove',
              'coverage/lcov.info',
              '*/messages.g.dart',
              '--output-file',
              'coverage/lcov.info',
            ],
            workingDirectory: packageDirectory,
            validateStderr: false,
          );
        }

        final testCoverageResult = await expectSuccessfulProcessResult(
          'genhtml',
          ['coverage/lcov.info', '-o', 'coverage'],
          workingDirectory: packageDirectory,
        );
        expect(testCoverageResult.stdout, matches(RegExp('lines(.+) 100.0%')));
      }
    }),
  );
}
