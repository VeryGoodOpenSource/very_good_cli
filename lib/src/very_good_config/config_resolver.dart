import 'package:args/args.dart';

/// {@template config_resolver}
/// Merges command line [ArgResults] with `very_good.yaml` configuration values.
///
/// Resolution follows a fixed precedence, from highest to lowest:
///
/// 1. A command line argument that was explicitly parsed.
/// 2. A value declared in the configuration file.
/// 3. A fallback value (typically the argument's command line default).
///
/// Centralizing the rule here keeps every command's argument/configuration
/// merge consistent and independently testable.
/// {@endtemplate}
class ConfigResolver {
  /// {@macro config_resolver}
  const ConfigResolver(this.argResults);

  /// The parsed command line arguments.
  final ArgResults argResults;

  /// Resolves the value for the argument named [name].
  ///
  /// [configValue] is the corresponding value from the configuration file, if
  /// any. [fallbackValue] is used when neither the command line nor the
  /// configuration provide a value.
  T resolve<T>(String name, T? configValue, {T? fallbackValue}) {
    final value = configValue != null && !argResults.wasParsed(name)
        ? configValue
        : argResults[name] as T?;
    return (value ?? fallbackValue) as T;
  }
}
