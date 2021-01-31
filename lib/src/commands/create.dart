import 'package:args/command_runner.dart';
import 'package:io/io.dart';
import 'package:mason/mason.dart';

/// {@template create_command}
/// `very_good create` command creates a new very good flutter app.
/// {@endtemplate}
class CreateCommand extends Command<int> {
  /// {@macro create_command}
  CreateCommand({Logger logger}) : _logger = logger ?? Logger();

  final Logger _logger;

  @override
  final String description =
      'Creates a new very good flutter application in seconds.';

  @override
  final String name = 'create';

  @override
  Future<int> run() async {
    _logger.alert('Created a Very Good App! 🦄');
    return ExitCode.success.code;
  }
}
