import 'package:mason/mason.dart';
import 'package:path/path.dart' as path;
import 'package:universal_io/io.dart';
import 'package:very_good_cli/src/commands/create/templates/templates.dart';
import 'package:very_good_cli/src/logger_extension.dart';

/// {@template very_good_core_template}
/// A core Flutter app template.
/// {@endtemplate}
class VeryGoodCoreTemplate extends Template {
  /// {@macro very_good_core_template}
  VeryGoodCoreTemplate()
      : super(
          name: 'core',
          bundle: veryGoodCoreBundle,
          help: 'Generate a Very Good Flutter application.',
        );

  @override
  Future<void> onGenerateComplete(Logger logger, Directory outputDir) async {
    await installFlutterPackages(logger, outputDir);
    await applyDartFixes(logger, outputDir);
    _logSummary(logger, outputDir);
  }

  void _logSummary(Logger logger, Directory outputDir) {
    
    logger
      ..info('\n')
      ..created('Created a Very Good App! 🦄')
      ..info('\n')
      ..info('To get started refer to ${outputDir.path}\\README.md')
      ..info('\n')
      ..info('Your project code is in ${Directory.current.path}.')
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
