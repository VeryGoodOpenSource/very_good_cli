import 'dart:async';

import 'package:glob/glob.dart';
import 'package:lcov_parser/lcov_parser.dart';
import 'package:mason/mason.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'package:pubspec_parse/pubspec_parse.dart';
import 'package:stack_trace/stack_trace.dart';
import 'package:universal_io/io.dart';
import 'package:very_good_cli/src/commands/test/templates/test_runner_bundle.dart';
import 'package:very_good_test_runner/very_good_test_runner.dart';

part 'dart_cli.dart';
part 'flutter_cli.dart';
part 'git_cli.dart';

const _asyncRunZoned = runZoned;

/// Type definition for [Process.run].
typedef RunProcess = Future<ProcessResult> Function(
  String executable,
  List<String> arguments, {
  String? workingDirectory,
  bool runInShell,
});

/// This class facilitates overriding [Process.run].
/// It should be extended by another class in client code with overrides
/// that construct a custom implementation.
@visibleForTesting
abstract class ProcessOverrides {
  static final _token = Object();

  /// Returns the current [ProcessOverrides] instance.
  ///
  /// This will return `null` if the current [Zone] does not contain
  /// any [ProcessOverrides].
  ///
  /// See also:
  /// * [ProcessOverrides.runZoned] to provide [ProcessOverrides]
  /// in a fresh [Zone].
  ///
  static ProcessOverrides? get current {
    return Zone.current[_token] as ProcessOverrides?;
  }

  /// Runs [body] in a fresh [Zone] using the provided overrides.
  static R runZoned<R>(
    R Function() body, {
    RunProcess? runProcess,
  }) {
    final overrides = _ProcessOverridesScope(runProcess);
    return _asyncRunZoned(body, zoneValues: {_token: overrides});
  }

  /// The method used to run a [Process].
  RunProcess get runProcess => Process.run;
}

class _ProcessOverridesScope extends ProcessOverrides {
  _ProcessOverridesScope(this._runProcess);

  final ProcessOverrides? _previous = ProcessOverrides.current;
  final RunProcess? _runProcess;

  @override
  RunProcess get runProcess {
    return _runProcess ?? _previous?.runProcess ?? super.runProcess;
  }
}

/// Abstraction for running commands via command-line.
class _Cmd {
  /// Runs the specified [cmd] with the provided [args].
  static Future<ProcessResult> run(
    String cmd,
    List<String> args, {
    bool throwOnError = true,
    String? workingDirectory,
  }) async {
    final runProcess = ProcessOverrides.current?.runProcess ?? Process.run;
    final result = await runProcess(
      cmd,
      args,
      workingDirectory: workingDirectory,
      runInShell: true,
    );

    if (throwOnError) {
      _throwIfProcessFailed(result, cmd, args);
    }
    return result;
  }

  static Iterable<Future<T>> runWhere<T>({
    required Future<T> Function(FileSystemEntity) run,
    required bool Function(FileSystemEntity) where,
    String cwd = '.',
  }) {
    return Directory(cwd).listSync(recursive: true).where(where).map(run);
  }

  static void _throwIfProcessFailed(
    ProcessResult pr,
    String process,
    List<String> args,
  ) {
    if (pr.exitCode != 0) {
      final values = {
        'Standard out': pr.stdout.toString().trim(),
        'Standard error': pr.stderr.toString().trim()
      }..removeWhere((k, v) => v.isEmpty);

      var message = 'Unknown error';
      if (values.isNotEmpty) {
        message = values.entries.map((e) => '${e.key}\n${e.value}').join('\n');
      }

      throw ProcessException(process, args, message, pr.exitCode);
    }
  }
}

const _ignoredDirectories = {
  'ios',
  'android',
  'windows',
  'linux',
  'macos',
  '.symlinks',
  '.plugin_symlinks',
  '.dart_tool',
  'build',
  '.fvm',
};

bool _isPubspec(FileSystemEntity entity) {
  final segments = p.split(entity.path).toSet();
  if (segments.intersection(_ignoredDirectories).isNotEmpty) return false;
  if (entity is! File) return false;
  return p.basename(entity.path) == 'pubspec.yaml';
}
