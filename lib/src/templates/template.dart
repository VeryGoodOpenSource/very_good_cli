import 'package:mason/mason.dart';
import 'package:universal_io/io.dart';
import 'package:very_good_cli/src/flutter_cli.dart';
import 'package:very_good_cli/src/dart_cli.dart';
import 'package:very_good_cli/src/templates/dart_package_bundle.dart';
import 'package:very_good_cli/src/templates/flutter_package_bundle.dart';
import 'package:very_good_cli/src/templates/very_good_core_bundle.dart';

/// {@template template}
/// Dart class that represents a VeryGoodCLI supported template.
/// Each template consists of a [MasonBundle]
/// and help text describing the template.
/// {@endtemplate}
abstract class Template {
  /// {@macro template}
  const Template(
      {required this.name, required this.bundle, required this.help});

  /// The name associated with this template
  final String name;

  /// The MasonBundle used to generate this template.
  final MasonBundle bundle;

  /// The help text shown in the usage information for the CLI.
  final String help;

  /// The tasks to run post generation for the specific MasonBundle.
  void onGenerateComplete(Logger logger, Directory outputDir);
}

/// {@template template}
/// Dart class that represents a VeryGoodCLI dart package template.
/// {@endtemplate}
class DartPkgTemplate extends Template {
  /// {@macro template}
  DartPkgTemplate()
      : super(name: 'dart_pkg', bundle: dartPackageBundle, help: '');

  /// The tasks to run post generation for the specific MasonBundle.
  @override
  void onGenerateComplete(Logger logger, Directory outputDir) async {
    final isDartInstalled = await Dart.installed();
    if (isDartInstalled) {
      final installDependenciesDone = logger.progress(
        'Running "dart pub get" in ${outputDir.path}',
      );
      await Dart.packagesGet(outputDir.path);
      installDependenciesDone();
    }
  }
}

/// {@template template}
/// Dart class that represents a VeryGoodCLI dart package template.
/// {@endtemplate}
class FlutterPkgTemplate extends Template {
  /// {@macro template}
  FlutterPkgTemplate()
      : super(name: 'flutter_pkg', bundle: flutterPackageBundle, help: '');

  /// The tasks to run post generation for the specific MasonBundle.
  @override
  void onGenerateComplete(Logger logger, Directory outputDir) async {
    final isFlutterInstalled = await Flutter.installed();
    if (isFlutterInstalled) {
      final installDependenciesDone = logger.progress(
        'Running "flutter packages get" in ${outputDir.path}',
      );
      await Flutter.packagesGet(outputDir.path);
      installDependenciesDone();
    }
  }
}

/// {@template template}
/// Dart class that represents a VeryGoodCLI dart package template.
/// {@endtemplate}
class CoreTemplate extends Template {
  /// {@macro template}
  CoreTemplate() : super(name: 'core', bundle: veryGoodCoreBundle, help: '');

  /// The tasks to run post generation for the specific MasonBundle.
  @override
  void onGenerateComplete(Logger logger, Directory outputDir) async {
    final isFlutterInstalled = await Flutter.installed();
    if (isFlutterInstalled) {
      final installDependenciesDone = logger.progress(
        'Running "flutter packages get" in ${outputDir.path}',
      );
      await Flutter.packagesGet(outputDir.path);
      installDependenciesDone();
    }
  }
}
