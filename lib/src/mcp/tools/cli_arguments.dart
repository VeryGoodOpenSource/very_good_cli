/// Turns the arguments of an MCP tool call into Very Good CLI arguments.
extension CliArguments on Map<String, Object?> {
  /// Returns `[flag]` when `this[key]` is `true`, else nothing.
  List<String> flag(String key, String flag) =>
      this[key] == true ? [flag] : const [];

  /// Returns `[--name]` when `this[key]` is `true`, `[--no-name]` when it is
  /// `false`, and nothing when it is not set.
  List<String> negatableFlag(String key, String name) => switch (this[key]) {
    true => ['--$name'],
    false => ['--no-$name'],
    _ => const [],
  };

  /// Returns `[option, value]` when `this[key]` is set, else nothing.
  List<String> option(String key, String option) => switch (this[key]) {
    final value? => [option, '$value'],
    null => const [],
  };

  /// Returns `[option, value]` for each value of the `this[key]` list.
  List<String> multiOption(String key, String option) => [
    for (final value in this[key] as List<Object?>? ?? const []) ...[
      option,
      '$value',
    ],
  ];
}
