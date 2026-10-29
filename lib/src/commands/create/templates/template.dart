import 'package:mason/mason.dart';
import 'package:universal_io/io.dart';

/// {@template template}
/// Dart class that represents a VeryGoodCLI supported template.
/// Each template consists of a [MasonBundle], name,
/// and help text describing the template.
/// {@endtemplate}
abstract class const Template({
  /// The name associated with this template.
  required final String name,

  /// The [MasonBundle] used to generate this template.
  required final MasonBundle bundle,

  /// The help text shown in the usage information for the CLI.
  required final String help,
}) {
  /// {@macro template}
  this;

  /// The [bundle] vars intentionally left to the template's default value.
  ///
  /// Every bundle var must either be passed by the `very_good create`
  /// subcommand that uses this template or be listed here.
  Set<String> get defaultedVars => const {};

  /// Callback invoked after template generation has completed.
  Future<void> onGenerateComplete(Logger logger, Directory outputDir);
}
