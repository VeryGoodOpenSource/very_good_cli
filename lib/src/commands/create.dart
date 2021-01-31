import 'package:args/command_runner.dart';
import 'package:io/io.dart';
import 'package:mason/mason.dart';

// A valid Dart identifier that can be used for a package, i.e. no
// capital letters.
// https://dart.dev/guides/language/language-tour#important-concepts
final RegExp _identifierRegExp = RegExp('[a-z_][a-z0-9_]*');

/// {@template create_command}
/// `very_good create` command creates a new very good flutter app.
/// {@endtemplate}
class CreateCommand extends Command<int> {
  /// {@macro create_command}
  CreateCommand({Logger logger}) : _logger = logger ?? Logger() {
    argParser.addOption(
      'project-name',
      help: 'The project name for this new Flutter project. '
          'This must be a valid dart package name.',
      defaultsTo: null,
    );
  }

  final Logger _logger;

  @override
  final String description =
      'Creates a new very good flutter application in seconds.';

  @override
  final String name = 'create';

  @override
  Future<int> run() async {
    final projectName = argResults['project-name'];
    if (projectName == null) {
      throw UsageException(
        'Required: --project-name.\n\n'
        'e.g: very_good create --project-name my_app',
        usage,
      );
    }
    final isValidProjectName = _isValidPackageName(projectName);
    if (!isValidProjectName) {
      throw UsageException(
        '"$projectName" is not a valid package name.\n\n'
        'See https://dart.dev/tools/pub/pubspec#name for more information.',
        usage,
      );
    }
    _logger.alert('Created a Very Good App! 🦄');
    return ExitCode.success.code;
  }

  /// Whether [name] is a valid Dart package name.
  bool _isValidPackageName(String name) {
    final match = _identifierRegExp.matchAsPrefix(name);
    return match != null && match.end == name.length;
  }
}
