import 'package:json_annotation/json_annotation.dart';
import 'package:very_good_cli/src/commands/packages/commands/check/commands/commands.dart';
import 'package:very_good_cli/src/mcp/runner/models/test_payload.dart';

part 'license_payload.g.dart';

/// {@template license_payload}
/// The `licenses` block of a tool result: what a license check recorded.
///
/// [banned] is the total number of banned dependencies, [bannedDependencies]
/// is capped at [maxPayloadItems] entries. A reader can tell the list was
/// truncated by comparing its length against [banned].
/// {@endtemplate}
@JsonSerializable(createFactory: false, explicitToJson: true)
class const LicensePayload({
  /// The number of dependencies the check banned.
  required final int banned,

  /// The first [maxPayloadItems] banned dependencies.
  required final List<BannedDependencyPayload> bannedDependencies,
}) {
  /// {@macro license_payload}
  this;

  /// The payload for the [bannedDependencies] of a license check.
  factory of(BannedDependencies bannedDependencies) => LicensePayload(
    banned: bannedDependencies.length,
    bannedDependencies: [
      for (final MapEntry(key: package, value: licenses)
          in bannedDependencies.entries.take(maxPayloadItems))
        BannedDependencyPayload(package: package, licenses: licenses.toList()),
    ],
  );

  /// The payload for the [bannedDependencies] of a license check, or null
  /// when it banned none.
  static LicensePayload? maybeOf(BannedDependencies? bannedDependencies) =>
      bannedDependencies == null ? null : LicensePayload.of(bannedDependencies);

  /// The JSON form of this payload.
  Map<String, Object?> toJson() => _$LicensePayloadToJson(this);
}

/// {@template banned_dependency_payload}
/// One banned dependency in a [LicensePayload].
/// {@endtemplate}
@JsonSerializable(createFactory: false)
class const BannedDependencyPayload({
  /// The name of the package.
  required final String package,

  /// The licenses of the package that banned it: those in `forbidden`, or
  /// those not in `allowed`.
  required final List<String> licenses,
}) {
  /// {@macro banned_dependency_payload}
  this;

  /// The JSON form of this payload.
  Map<String, Object?> toJson() => _$BannedDependencyPayloadToJson(this);
}
