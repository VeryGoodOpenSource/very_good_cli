import 'dart:io';
import 'package:mason_logger/mason_logger.dart';
import 'package:meta/meta.dart';
import 'package:universal_io/io.dart';

/// The fallback number of columns of the terminal.
///
/// Used when the terminal number of columns (width) cannot be determined. For
/// example, when running in Azure DevOps, see relevant issue:
/// https://github.com/VeryGoodOpenSource/very_good_cli/issues/866 .
@visibleForTesting
const fallbackStdoutTerminalColumns = 80;

/// Extension on the Logger class for custom styled logging.
extension LoggerX on Logger {
  /// Log a message in the "created" style of the CLI.
  void created(String message) {
    info(lightCyan.wrap(styleBold.wrap(message)));
  }

  /// Wrap the [text] to fit perfectly within the width of the terminal when
  /// [print]ed.
  ///
  /// The text will wrap around the terminal width, and will not break words. If
  /// the terminal width cannot be determined, the text will wrap around the
  /// [fallbackStdoutTerminalColumns].
  ///
  /// To completely overwrite the width you can use [length].
  void wrap(
    String? text, {
    required void Function(String?) print,
    int? length,
  }) {
    late final int maxLength;
    if (length != null) {
      maxLength = length;
    } else if (stdout.hasTerminal) {
      maxLength = stdout.terminalColumns;
    } else {
      maxLength = fallbackStdoutTerminalColumns;
    }

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
