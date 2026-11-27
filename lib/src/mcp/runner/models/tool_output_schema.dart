import 'package:dart_mcp/server.dart';
import 'package:very_good_cli/src/mcp/runner/models/structured_tool_error.dart';
import 'package:very_good_cli/src/mcp/runner/models/structured_tool_success.dart';
import 'package:very_good_cli/src/mcp/runner/models/tool_failure.dart';

/// The schema of the structured content every tool returns, for a success
/// ([StructuredToolSuccess]) and for a failure ([StructuredToolError]) alike.
final ObjectSchema toolOutputSchema = ObjectSchema(
  properties: {
    'status': UntitledSingleSelectEnumSchema(
      description:
          '"success", or "partial_failure" when the command printed output '
          'before failing, otherwise "failure".',
      values: ['success', 'failure', 'partial_failure'],
    ),
    'attemptedAction': ObjectSchema(
      description:
          'The "tool", the "command" it ran, and the "directory" and '
          '"arguments" of the call when given.',
    ),
    'output': StringSchema(
      description: 'Success only: what the command printed.',
    ),
    'failureType': UntitledSingleSelectEnumSchema(
      description:
          'Failure only: the bucket of the failure. Only "transient" is '
          'worth an unchanged retry.',
      values: [for (final type in ToolFailureType.values) type.name],
    ),
    'failureReason': UntitledSingleSelectEnumSchema(
      description: 'Failure only: the specific cause.',
      values: [for (final reason in ToolFailureReason.values) reason.jsonName],
    ),
    'reason': StringSchema(
      description: 'Failure only: a human-readable cause.',
    ),
    'test': ObjectSchema(
      description:
          'What a test run recorded: "results" holds the passed, failed and '
          'skipped counts, the duration and the failing tests. "coverage" '
          'holds the actual and required coverage and the uncovered lines '
          'when coverage is below the threshold.',
    ),
    'licenses': ObjectSchema(
      description:
          'Failure only: what a license check recorded when it banned a '
          'dependency: the number of "banned" dependencies and the '
          '"bannedDependencies", each with its "package" and the "licenses" '
          'that banned it.',
    ),
    'partialResults': StringSchema(
      description: 'Failure only: what the command printed before failing.',
    ),
    'alternativeApproaches': ListSchema(
      description: 'Failure only: what to try next.',
      items: StringSchema(),
    ),
  },
  required: ['status', 'attemptedAction'],
);
