import 'package:mason_logger/mason_logger.dart';

/// Extension on the Logger class for custom styled logging.
extension LoggerX on Logger {
  /// Log a message in the "created" style of the CLI.
  void created(String message) {
    info(lightCyan.wrap(styleBold.wrap(message)));
  }
}
