import 'package:json_annotation/json_annotation.dart';

part 'test_event.g.dart';

/// {@template test_event}
/// This is the root class of the protocol.
/// All root-level objects emitted by the JSON reporter
/// will be subclasses of [TestEvent].
/// https://github.com/dart-lang/test/blob/master/pkgs/test/doc/json_reporter.md
/// {@endtemplate}
abstract class TestEvent {
  /// {@macro test_event}
  const TestEvent({required this.type, required this.time});

  /// Converts [json] into a [TestEvent].
  static TestEvent fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    switch (type) {
      case 'start':
        return StartTestEvent.fromJson(json);
      case 'allSuites':
        return AllSuitesTestEvent.fromJson(json);
      case 'suite':
        return SuiteTestEvent.fromJson(json);
      case 'debug':
        return DebugTestEvent.fromJson(json);
      case 'group':
        return GroupTestEvent.fromJson(json);
      case 'testStart':
        return TestStartEvent.fromJson(json);
      case 'print':
        return MessageTestEvent.fromJson(json);
      case 'error':
        return ErrorTestEvent.fromJson(json);
      case 'testDone':
        return TestDoneEvent.fromJson(json);
      case 'done':
        return DoneTestEvent.fromJson(json);
      default:
        throw UnsupportedError('Unsupported type: $type');
    }
  }

  /// The type of the event.
  ///
  /// This is always one of the subclass types listed below.
  final String type;

  /// The time (in milliseconds) that has elapsed since the test runner started.
  final int time;
}

/// {@template start_test_event}
/// A single start event is emitted before any other events.
/// It indicates that the test runner has started running.
/// {@endtemplate}
@JsonSerializable()
class StartTestEvent extends TestEvent {
  /// {@macro start_test_event}
  const StartTestEvent({
    required this.protocolVersion,
    required this.runnerVersion,
    required this.pid,
    required int time,
  }) : super(type: 'start', time: time);

  /// {@macro start_test_event}
  factory StartTestEvent.fromJson(Map<String, dynamic> json) =>
      _$StartTestEventFromJson(json);

  /// The version of the JSON reporter protocol being used.
  ///
  /// This is a semantic version, but it reflects only the version of the
  /// protocol—it's not identical to the version of the test runner itself.
  final String protocolVersion;

  /// The version of the test runner being used.
  ///
  /// This is null if for some reason the version couldn't be loaded.
  final String? runnerVersion;

  /// The pid of the VM process running the tests.
  final int pid;
}

/// {@template all_suites_test_event}
/// A single suite count event is emitted once the test runner knows the total
/// number of suites that will be loaded over the course of the test run.
/// Because this is determined asynchronously, its position relative to other
/// events (except [StartTestEvent]) is not guaranteed.
/// {@endtemplate}
@JsonSerializable()
class AllSuitesTestEvent extends TestEvent {
  /// {@macro all_suites_test_event}
  const AllSuitesTestEvent({
    required this.count,
    required int time,
  }) : super(type: 'allSuites', time: time);

  /// {@macro all_suites_test_event}
  factory AllSuitesTestEvent.fromJson(Map<String, dynamic> json) =>
      _$AllSuitesTestEventFromJson(json);

  /// The total number of suites that will be loaded.
  final int count;
}

/// {@template suite_test_event}
/// A suite event is emitted before any GroupEvents for groups
/// in a given test suite.
/// This is the only event that contains the full metadata about a suite;
/// future events will refer to the suite by its opaque ID.
/// {@endtemplate}
@JsonSerializable()
class SuiteTestEvent extends TestEvent {
  /// {@macro suite_test_event}
  const SuiteTestEvent({
    required this.suite,
    required int time,
  }) : super(type: 'suite', time: time);

  /// {@macro suite_test_event}
  factory SuiteTestEvent.fromJson(Map<String, dynamic> json) =>
      _$SuiteTestEventFromJson(json);

  /// Metadata about the suite.
  final TestSuite suite;
}

/// {@template debug_test_event}
/// A debug event is emitted after (although not necessarily directly after)
/// a [SuiteTestEvent], and includes information about how to debug that suite.
/// It's only emitted if the --debug flag is passed to the test runner.
/// {@endtemplate}
@JsonSerializable()
class DebugTestEvent extends TestEvent {
  /// {@macro debug_test_event}
  const DebugTestEvent({
    required this.suiteID,
    required this.observatory,
    required this.remoteDebugger,
    required int time,
  }) : super(type: 'debug', time: time);

  /// {@macro debug_test_event}
  factory DebugTestEvent.fromJson(Map<String, dynamic> json) =>
      _$DebugTestEventFromJson(json);

  /// The suite for which debug information is reported.
  final int suiteID;

  /// The HTTP URL for the Dart Observatory, or `null` if the Observatory isn't
  /// available for this suite.
  final String? observatory;

  /// The HTTP URL for the remote debugger for this suite's host page, or `null`
  /// if no remote debugger is available for this suite.
  final String? remoteDebugger;
}

/// {@template group_test_event}
/// A group event is emitted before any
/// [TestStartEvent] for tests in a given group.
/// This is the only event that contains the full metadata about a group;
/// future events will refer to the group by its opaque ID.
/// {@endtemplate}
@JsonSerializable()
class GroupTestEvent extends TestEvent {
  /// {@macro group_test_event}
  const GroupTestEvent({
    required this.group,
    required int time,
  }) : super(type: 'group', time: time);

  /// {@macro group_test_event}
  factory GroupTestEvent.fromJson(Map<String, dynamic> json) =>
      _$GroupTestEventFromJson(json);

  /// Metadata about the group.
  final TestGroup group;
}

/// {@template test_start_event}
/// An event emitted when a test begins running.
/// This is the only event that contains the full metadata about a test;
/// future events will refer to the test by its opaque ID.
/// {@endtemplate}
@JsonSerializable()
class TestStartEvent extends TestEvent {
  /// {@macro test_start_event}
  const TestStartEvent({
    required this.test,
    required int time,
  }) : super(type: 'testStart', time: time);

  /// {@macro test_start_event}
  factory TestStartEvent.fromJson(Map<String, dynamic> json) =>
      _$TestStartEventFromJson(json);

  /// Metadata about the test that started.
  final Test test;
}

/// {@template message_test_event}
/// A MessageEvent indicates that a test emitted a message that
/// should be displayed to the user.
/// The [messageType] field indicates the precise type of this message.
/// Different message types should be visually distinguishable.
/// {@endtemplate}
@JsonSerializable()
class MessageTestEvent extends TestEvent {
  /// {@macro message_test_event}
  const MessageTestEvent({
    required this.testID,
    required this.messageType,
    required this.message,
    required int time,
  }) : super(type: 'print', time: time);

  /// {@macro message_test_event}
  factory MessageTestEvent.fromJson(Map<String, dynamic> json) =>
      _$MessageTestEventFromJson(json);

  /// The ID of the test that printed a message.
  final int testID;

  /// The type of message being printed.
  final String messageType;

  /// The message that was printed.
  final String message;
}

/// {@template error_test_event}
/// An [ErrorTestEvent] indicates that a test encountered an uncaught error.
/// Note that this may happen even after the test has completed,
/// in which case it should be considered to have failed.
/// {@endtemplate}
@JsonSerializable()
class ErrorTestEvent extends TestEvent {
  /// {@macro error_test_event}
  const ErrorTestEvent({
    required this.testID,
    required this.error,
    required this.stackTrace,
    required this.isFailure,
    required int time,
  }) : super(type: 'error', time: time);

  /// {@macro error_test_event}
  factory ErrorTestEvent.fromJson(Map<String, dynamic> json) =>
      _$ErrorTestEventFromJson(json);

  /// The ID of the test that experienced the error.
  final int testID;

  /// The result of calling toString() on the error object.
  final String error;

  /// The error's stack trace, in the stack_trace package format.
  final String stackTrace;

  /// Whether the error was a TestFailure.
  final bool isFailure;
}

/// The result of a test.
enum TestResult {
  /// the test had no errors
  success,

  /// the test had a `TestFailure` but no other errors.
  failure,

  /// the test had an error other than `TestFailure`
  error
}

/// {@template test_done_event}
/// An event emitted when a test completes.
/// The result attribute indicates the result of the test.
/// {@endtemplate}
@JsonSerializable()
class TestDoneEvent extends TestEvent {
  /// {@macro test_done_event}
  const TestDoneEvent({
    required this.testID,
    required this.result,
    required this.hidden,
    required this.skipped,
    required int time,
  }) : super(type: 'testDone', time: time);

  /// {@macro test_done_event}
  factory TestDoneEvent.fromJson(Map<String, dynamic> json) =>
      _$TestDoneEventFromJson(json);

  /// The ID of the test that completed.
  final int testID;

  /// The result of the test.
  final TestResult result;

  /// Whether the test's result should be hidden.
  final bool hidden;

  /// Whether the test (or some part of it) was skipped.
  final bool skipped;
}

/// {@template done_test_event}
/// An event indicating the result of the entire test run.
/// This will be the final event emitted by the reporter.
/// {@endtemplate}
@JsonSerializable()
class DoneTestEvent extends TestEvent {
  /// {@macro done_test_event}
  const DoneTestEvent({
    required this.success,
    required int time,
  }) : super(type: 'done', time: time);

  /// {@macro done_test_event}
  factory DoneTestEvent.fromJson(Map<String, dynamic> json) =>
      _$DoneTestEventFromJson(json);

  /// Whether all tests succeeded (or were skipped).
  ///
  /// Will be `null` if the test runner was close before all tests completed
  /// running.
  final bool? success;
}

/// {@template test_suite}
/// A test suite corresponding to a loaded test file.
/// The suite's ID is unique in the context of this test run.
/// It's used elsewhere in the protocol to refer to this suite
/// without including its full representation.

/// A suite's platform is one of the platforms that can be passed to the
/// --platform option, or null if there is no platform
/// (for example if the file doesn't exist at all).
/// Its path is either absolute or relative to the root of the current package.
/// {@endtemplate}
@JsonSerializable()
class TestSuite {
  /// {@macro test_suite}
  const TestSuite({
    required this.id,
    required this.platform,
    this.path,
  });

  /// {@macro test_suite}
  factory TestSuite.fromJson(Map<String, dynamic> json) =>
      _$TestSuiteFromJson(json);

  /// An opaque ID for the group.
  final int id;

  /// The platform on which the suite is running.
  final String platform;

  /// The path to the suite's file, or `null` if that path is unknown.
  final String? path;
}

/// {@template test_group}
/// A group containing test cases.
/// The group's ID is unique in the context of this test run.
/// It's used elsewhere in the protocol to refer to this group
/// without including its full representation.
/// {@endtemplate}
@JsonSerializable()
class TestGroup {
  /// {@macro test_group}
  const TestGroup({
    required this.id,
    required this.name,
    required this.suiteID,
    this.parentID,
    required this.testCount,
    this.line,
    this.column,
    this.url,
    required this.metadata,
  });

  /// {@macro test_group}
  factory TestGroup.fromJson(Map<String, dynamic> json) =>
      _$TestGroupFromJson(json);

  /// An opaque ID for the group.
  final int id;

  /// The name of the group, including prefixes from any containing groups.
  final String name;

  /// The ID of the suite containing this group.
  final int suiteID;

  /// The ID of the group's parent group, unless it's the root group.
  final int? parentID;

  /// The number of tests (recursively) within this group.
  final int testCount;

  /// The (1-based) line on which the group was defined, or `null`.
  final int? line;

  /// The (1-based) column on which the group was defined, or `null`.
  final int? column;

  /// The URL for the file in which the group was defined, or `null`.
  final String? url;

  /// This field is deprecated and should not be used.
  final TestMetadata metadata;
}

/// {@template test_metadata}
/// Test metadata regarding whether the test was skipped and the reason.
/// {@endtemplate}
@JsonSerializable()
class TestMetadata {
  /// {@macro test_metadata}
  TestMetadata({required this.skip, this.skipReason});

  /// {@macro test_metadata}
  factory TestMetadata.fromJson(Map<String, dynamic> json) =>
      _$TestMetadataFromJson(json);

  /// Whether the test was skipped.
  final bool skip;

  /// The reason the tests was skipped, or `null` if it wasn't skipped.
  final String? skipReason;
}

/// {@template test}
/// A single test case. The test's ID is unique in the context of this test run.
/// It's used elsewhere in the protocol to refer to this test
/// without including its full representation.
/// {@endtemplate}
@JsonSerializable()
class Test {
  /// {@macro test}
  Test({
    required this.id,
    required this.name,
    required this.suiteID,
    required this.groupIDs,
    this.line,
    this.column,
    this.url,
    this.rootLine,
    this.rootColumn,
    this.rootUrl,
    required this.metadata,
  });

  /// {@macro test}
  factory Test.fromJson(Map<String, dynamic> json) => _$TestFromJson(json);

  /// An opaque ID for the test.
  final int id;

  /// The name of the test, including prefixes from any containing groups.
  final String name;

  /// The ID of the suite containing this test.
  final int suiteID;

  /// The IDs of groups containing this test, in order from outermost to
  /// innermost.
  final List<int> groupIDs;

  /// The (1-based) line on which the test was defined, or `null`.
  final int? line;

  /// The (1-based) column on which the test was defined, or `null`.
  final int? column;

  /// The URL for the file in which the test was defined, or `null`.
  final String? url;

  /// The (1-based) line in the original test suite from which the test
  /// originated.
  ///
  /// Will only be present if `root_url` is different from `url`.
  final int? rootLine;

  /// The (1-based) line on in the original test suite from which the test
  /// originated.
  ///
  /// Will only be present if `root_url` is different from `url`.
  final int? rootColumn;

  /// The URL for the original test suite in which the test was defined.
  ///
  /// Will only be present if different from `url`.
  final String? rootUrl;

  /// This field is deprecated and should not be used.
  final TestMetadata metadata;
}
