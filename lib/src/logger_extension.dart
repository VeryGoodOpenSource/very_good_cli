import 'package:mason_logger/mason_logger.dart';
import 'package:universal_io/io.dart';

/// Extension on the Logger class for custom styled logging.
extension LoggerX on Logger {
  /// Log a message in the "created" style of the CLI.
  void created(String message) {
    info(lightCyan.wrap(styleBold.wrap(message)));
  }

  /// Wrap the [text] to fit perfectly within the width of the terminal when
  /// [print]ed.
  ///
  /// To overwrite the width you can use [length].
  void wrap(
    String? text, {
    required void Function(String?) print,
    int? length,
  }) {
    final maxLength = length ?? stdout.terminalColumns;
    for (final sentence in text?.split('/n') ?? <String>[]) {
      final words = sentence.split(' ');

      final currentLine = StringBuffer();
      for (final word in words) {
        // Replace all ANSI sequences so we can get the true character length.
        final charLength = word
            .replaceAll(RegExp('\x1B(?:[@-Z\\-_]|[[0-?]*[ -/]*[@-~])'), '')
            .length;

        if (currentLine.length + charLength > maxLength) {
          print(currentLine.toString());
          currentLine.clear();
        }
        currentLine.write('$word ');
      }

      print(currentLine.toString());
    }
  }
}
