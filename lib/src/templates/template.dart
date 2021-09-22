import 'package:io/ansi.dart';
import 'package:mason/mason.dart';
import 'package:universal_io/io.dart';
import 'package:very_good_cli/src/cli/cli.dart';
import 'package:very_good_cli/src/templates/templates.dart';

/// {@template template}
/// Dart class that represents a VeryGoodCLI supported template.
/// Each template consists of a [MasonBundle], name,
/// and help text describing the template.
/// {@endtemplate}
abstract class Template {
  /// {@macro template}
  const Template({
    required this.name,
    required this.bundle,
    required this.help,
  });

  /// The name associated with this template.
  final String name;

  /// The [MasonBundle] used to generate this template.
  final MasonBundle bundle;

  /// The help text shown in the usage information for the CLI.
  final String help;

  /// Callback invoked after template generation has completed.
  Future<void> onGenerateComplete(Logger logger, Directory outputDir);
}

/// {@template dart_pkg_template}
/// A Dart package template.
/// {@endtemplate}
class DartPkgTemplate extends Template {
  /// {@macro dart_pkg_template}
  DartPkgTemplate()
      : super(
          name: 'dart_pkg',
          bundle: dartPackageBundle,
          help: 'Generate a reusable Dart package.',
        );

  @override
  Future<void> onGenerateComplete(Logger logger, Directory outputDir) async {
    final isFlutterInstalled = await Flutter.installed();
    if (isFlutterInstalled) {
      final installDependenciesDone = logger.progress(
        'Running "flutter pub get" in ${outputDir.path}',
      );
      await Flutter.pubGet(cwd: outputDir.path);
      installDependenciesDone();
    }
    _logSummary(logger);
  }

  void _logSummary(Logger logger) {
    logger
      ..info('\n')
      ..alert('Created a Very Good Dart package! 🦄')
      ..info('\n');
  }
}

/// {@template flutter_pkg_template}
/// A Flutter package template.
/// {@endtemplate}
class FlutterPkgTemplate extends Template {
  /// {@macro flutter_pkg_template}
  FlutterPkgTemplate()
      : super(
            name: 'flutter_pkg',
            bundle: flutterPackageBundle,
            help: 'Generate a reusable Flutter package.');

  @override
  Future<void> onGenerateComplete(Logger logger, Directory outputDir) async {
    final isFlutterInstalled = await Flutter.installed();
    if (isFlutterInstalled) {
      final installDependenciesDone = logger.progress(
        'Running "flutter packages get" in ${outputDir.path}',
      );
      await Flutter.packagesGet(cwd: outputDir.path);
      installDependenciesDone();
    }
    _logSummary(logger);
  }

  void _logSummary(Logger logger) {
    logger
      ..info('\n')
      ..alert('Created a Very Good Flutter package! 🦄')
      ..info('\n');
  }
}

/// {@template flutter_plugin_template}
/// A Flutter plugin template.
/// {@endtemplate}
class FlutterPluginTemplate extends Template {
  /// {@macro flutter_pkg_template}
  FlutterPluginTemplate()
      : super(
          name: 'flutter_plugin',
          bundle: flutterPluginBundle,
          help: 'Generate a reusable Flutter plugin.',
        );

  @override
  Future<void> onGenerateComplete(Logger logger, Directory outputDir) async {
    final isFlutterInstalled = await Flutter.installed();
    if (isFlutterInstalled) {
      final installDependenciesDone = logger.progress(
        'Running "flutter packages get" in ${outputDir.path}',
      );
      await Flutter.packagesGet(cwd: outputDir.path, recursive: true);
      installDependenciesDone();
    }
    _logSummary(logger);
  }

  void _logSummary(Logger logger) {
    logger
      ..info('\n')
      ..alert('Created a Very Good Flutter plugin! 🦄')
      ..info('\n');
  }
}

/// {@template core_template}
/// A core Flutter app template.
/// {@endtemplate}
class CoreTemplate extends Template {
  /// {@macro core_template}
  CoreTemplate()
      : super(
          name: 'core',
          bundle: veryGoodCoreBundle,
          help: 'Generate a Very Good Flutter application.',
        );

  @override
  Future<void> onGenerateComplete(Logger logger, Directory outputDir) async {
    final isFlutterInstalled = await Flutter.installed();
    if (isFlutterInstalled) {
      final installDependenciesDone = logger.progress(
        'Running "flutter packages get" in ${outputDir.path}',
      );
      await Flutter.packagesGet(cwd: outputDir.path);
      installDependenciesDone();
    }
    _logSummary(logger);
  }

  void _logSummary(Logger logger) {
    logger
      ..info('\n')
      ..alert('Created a Very Good App! 🦄')
      ..info('\n')
      ..info(
        lightGray.wrap(
          '''
+----------------------------------------------------+
| Looking for more features?                         |
| We have an enterprise-grade solution for companies |
| called Very Good Start.                            |
|                                                    |
| For more info visit:                               |
| https://verygood.ventures/solution/very-good-start |
+----------------------------------------------------+''',
        ),
      );
  }
}
