import 'dart:async' as dart_async;

/// The dependencies a license check banned, keyed by package name, each with
/// the licenses that banned it.
typedef BannedDependencies = Map<String, Set<String>>;

/// {@template license_check_recorder}
/// Records what a license check reported beyond its exit code, for a caller
/// that needs to tell the outcomes sharing an exit code apart.
///
/// A banned license and an invalid configuration both exit with
/// `ExitCode.config`, and the banned dependencies are only printed. The MCP
/// server installs a recorder around each tool call with [runZoned], and the
/// `packages check licenses` command reports the dependencies it banned with
/// [recordBannedDependencies]. On the command line there is no recorder, so
/// nothing is recorded.
/// {@endtemplate}
class LicenseCheckRecorder {
  static final _token = Object();

  /// Returns the [LicenseCheckRecorder] of the current [dart_async.Zone].
  ///
  /// This will return `null` if the current [dart_async.Zone] does not contain
  /// any [LicenseCheckRecorder].
  ///
  /// See also:
  /// * [LicenseCheckRecorder.runZoned] to provide a [LicenseCheckRecorder] in
  ///   a fresh [dart_async.Zone].
  static LicenseCheckRecorder? get current =>
      dart_async.Zone.current[_token] as LicenseCheckRecorder?;

  /// Runs [body] in a fresh [dart_async.Zone] that records to [recorder].
  static R runZoned<R>(
    R Function() body, {
    required LicenseCheckRecorder recorder,
  }) => dart_async.runZoned(body, zoneValues: {_token: recorder});

  BannedDependencies? _bannedDependencies;

  /// The dependencies the check banned, each with the licenses that banned
  /// it, or `null` when no dependency was banned.
  ///
  /// The returned map and its sets are unmodifiable.
  BannedDependencies? get bannedDependencies => _bannedDependencies;

  /// Records the [bannedDependencies] of the check, replacing any previously
  /// recorded ones.
  void recordBannedDependencies(BannedDependencies bannedDependencies) {
    _bannedDependencies = Map.unmodifiable({
      for (final MapEntry(key: package, value: licenses)
          in bannedDependencies.entries)
        package: Set<String>.unmodifiable(licenses),
    });
  }
}
