import 'package:dart_mcp/server.dart';
import 'package:very_good_cli/src/mcp/runner/runner.dart';
import 'package:very_good_cli/src/mcp/tools/cli_arguments.dart';
import 'package:very_good_cli/src/mcp/tools/very_good_tool.dart';
import 'package:very_good_cli/src/very_good_config/very_good_config.dart';

/// {@template packages_check_licenses_tool}
/// `packages_check_licenses`: lists and checks the licenses of the
/// dependencies of a package, by running `very_good packages check licenses`.
/// {@endtemplate}
class PackagesCheckLicensesTool(super.runner) extends VeryGoodTool {
  /// {@macro packages_check_licenses_tool}
  this;

  /// The tool's name.
  static const name = 'packages_check_licenses';

  @override
  Tool get definition => Tool(
    name: name,
    description:
        'List the licenses of the dependencies of a Dart or Flutter '
        'package as SPDX identifiers (e.g. MIT, BSD-3-Clause), and fail '
        'with a "license_banned" reason, listing the banned packages under '
        '"licenses", when one is not in "allowed" or is in "forbidden". '
        'Reads pubspec.lock, so the dependencies must be installed first.',
    annotations: ToolAnnotations(
      title: 'Check package licenses',
      readOnlyHint: true,
      idempotentHint: true,
      openWorldHint: false,
    ),
    inputSchema: ObjectSchema(
      properties: {
        'directory': StringSchema(
          description:
              'The package to check, holding a pubspec.lock. Absolute, '
              'or relative to the directory the server was started in, '
              'which is the default.',
        ),
        'dependency_type': ListSchema(
          description:
              'The types of dependencies to check. Defaults to '
              '["direct-main"].',
          items: UntitledSingleSelectEnumSchema(
            values: [
              'direct-main',
              'direct-dev',
              'transitive',
              'direct-overridden',
            ],
          ),
          uniqueItems: true,
        ),
        'allowed': ListSchema(
          description:
              'The only SPDX licenses to accept (e.g. ["MIT", '
              '"BSD-3-Clause"]). Cannot be combined with "forbidden".',
          items: StringSchema(),
        ),
        'forbidden': ListSchema(
          description:
              'The SPDX licenses to reject (e.g. ["GPL-3.0-only"]). '
              'Cannot be combined with "allowed".',
          items: StringSchema(),
        ),
        'skip_packages': ListSchema(
          description: 'Names of the packages to leave unchecked.',
          items: StringSchema(),
        ),
        'ignore_retrieval_failures': BooleanSchema(
          description:
              'Whether to carry on when the license of a package cannot '
              'be retrieved. Defaults to false.',
        ),
        'reporter': UntitledSingleSelectEnumSchema(
          description:
              'How to list the licenses in the output: "text" for a '
              'plain listing, or "csv" for one row per package. Defaults '
              'to "text".',
          values: reporterAllowedValues,
        ),
      },
      additionalProperties: false,
    ),
    outputSchema: toolOutputSchema,
  );

  @override
  Future<CallToolResult> run(Map<String, Object?> arguments) => runner.run(
    [
      'packages',
      'check',
      'licenses',
      ...arguments.flag(
        'ignore_retrieval_failures',
        '--ignore-retrieval-failures',
      ),
      ...arguments.multiOption('dependency_type', '--dependency-type'),
      ...arguments.multiOption('allowed', '--allowed'),
      ...arguments.multiOption('forbidden', '--forbidden'),
      ...arguments.multiOption('skip_packages', '--skip-packages'),
      ...arguments.option('reporter', '--reporter'),
    ],
    toolName: name,
    directory: arguments['directory'] as String?,
    requestArguments: arguments,
  );
}
