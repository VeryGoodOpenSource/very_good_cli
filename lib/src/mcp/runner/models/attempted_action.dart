/// The `attemptedAction` block shared by success and failure payloads: the
/// tool, the CLI command it ran (when known), and the working directory and
/// arguments of the call (when given).
Map<String, Object?> attemptedActionPayload({
  required String toolName,
  required String? commandString,
  required String? directory,
  required Map<String, Object?>? arguments,
}) => {
  'tool': toolName,
  'command': ?commandString,
  'directory': ?directory,
  if (arguments != null && arguments.isNotEmpty) 'arguments': arguments,
};
