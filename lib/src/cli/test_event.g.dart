// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: implicit_dynamic_parameter, cast_nullable_to_non_nullable, require_trailing_commas, lines_longer_than_80_chars

part of 'test_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StartTestEvent _$StartTestEventFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'StartTestEvent',
      json,
      ($checkedConvert) {
        final val = StartTestEvent(
          protocolVersion:
              $checkedConvert('protocolVersion', (v) => v as String),
          runnerVersion: $checkedConvert('runnerVersion', (v) => v as String?),
          pid: $checkedConvert('pid', (v) => v as int),
          time: $checkedConvert('time', (v) => v as int),
        );
        return val;
      },
    );

AllSuitesTestEvent _$AllSuitesTestEventFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'AllSuitesTestEvent',
      json,
      ($checkedConvert) {
        final val = AllSuitesTestEvent(
          count: $checkedConvert('count', (v) => v as int),
          time: $checkedConvert('time', (v) => v as int),
        );
        return val;
      },
    );

SuiteTestEvent _$SuiteTestEventFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'SuiteTestEvent',
      json,
      ($checkedConvert) {
        final val = SuiteTestEvent(
          suite: $checkedConvert(
              'suite', (v) => TestSuite.fromJson(v as Map<String, dynamic>)),
          time: $checkedConvert('time', (v) => v as int),
        );
        return val;
      },
    );

DebugTestEvent _$DebugTestEventFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'DebugTestEvent',
      json,
      ($checkedConvert) {
        final val = DebugTestEvent(
          suiteID: $checkedConvert('suiteID', (v) => v as int),
          observatory: $checkedConvert('observatory', (v) => v as String?),
          remoteDebugger:
              $checkedConvert('remoteDebugger', (v) => v as String?),
          time: $checkedConvert('time', (v) => v as int),
        );
        return val;
      },
    );

GroupTestEvent _$GroupTestEventFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'GroupTestEvent',
      json,
      ($checkedConvert) {
        final val = GroupTestEvent(
          group: $checkedConvert(
              'group', (v) => TestGroup.fromJson(v as Map<String, dynamic>)),
          time: $checkedConvert('time', (v) => v as int),
        );
        return val;
      },
    );

TestStartEvent _$TestStartEventFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'TestStartEvent',
      json,
      ($checkedConvert) {
        final val = TestStartEvent(
          test: $checkedConvert(
              'test', (v) => Test.fromJson(v as Map<String, dynamic>)),
          time: $checkedConvert('time', (v) => v as int),
        );
        return val;
      },
    );

MessageTestEvent _$MessageTestEventFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'MessageTestEvent',
      json,
      ($checkedConvert) {
        final val = MessageTestEvent(
          testID: $checkedConvert('testID', (v) => v as int),
          messageType: $checkedConvert('messageType', (v) => v as String),
          message: $checkedConvert('message', (v) => v as String),
          time: $checkedConvert('time', (v) => v as int),
        );
        return val;
      },
    );

ErrorTestEvent _$ErrorTestEventFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'ErrorTestEvent',
      json,
      ($checkedConvert) {
        final val = ErrorTestEvent(
          testID: $checkedConvert('testID', (v) => v as int),
          error: $checkedConvert('error', (v) => v as String),
          stackTrace: $checkedConvert('stackTrace', (v) => v as String),
          isFailure: $checkedConvert('isFailure', (v) => v as bool),
          time: $checkedConvert('time', (v) => v as int),
        );
        return val;
      },
    );

TestDoneEvent _$TestDoneEventFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'TestDoneEvent',
      json,
      ($checkedConvert) {
        final val = TestDoneEvent(
          testID: $checkedConvert('testID', (v) => v as int),
          result: $checkedConvert(
              'result', (v) => $enumDecode(_$TestResultEnumMap, v)),
          hidden: $checkedConvert('hidden', (v) => v as bool),
          skipped: $checkedConvert('skipped', (v) => v as bool),
          time: $checkedConvert('time', (v) => v as int),
        );
        return val;
      },
    );

const _$TestResultEnumMap = {
  TestResult.success: 'success',
  TestResult.failure: 'failure',
  TestResult.error: 'error',
};

DoneTestEvent _$DoneTestEventFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'DoneTestEvent',
      json,
      ($checkedConvert) {
        final val = DoneTestEvent(
          success: $checkedConvert('success', (v) => v as bool?),
          time: $checkedConvert('time', (v) => v as int),
        );
        return val;
      },
    );

TestSuite _$TestSuiteFromJson(Map<String, dynamic> json) => $checkedCreate(
      'TestSuite',
      json,
      ($checkedConvert) {
        final val = TestSuite(
          id: $checkedConvert('id', (v) => v as int),
          platform: $checkedConvert('platform', (v) => v as String),
          path: $checkedConvert('path', (v) => v as String?),
        );
        return val;
      },
    );

TestGroup _$TestGroupFromJson(Map<String, dynamic> json) => $checkedCreate(
      'TestGroup',
      json,
      ($checkedConvert) {
        final val = TestGroup(
          id: $checkedConvert('id', (v) => v as int),
          name: $checkedConvert('name', (v) => v as String),
          suiteID: $checkedConvert('suiteID', (v) => v as int),
          parentID: $checkedConvert('parentID', (v) => v as int?),
          testCount: $checkedConvert('testCount', (v) => v as int),
          line: $checkedConvert('line', (v) => v as int?),
          column: $checkedConvert('column', (v) => v as int?),
          url: $checkedConvert('url', (v) => v as String?),
          metadata: $checkedConvert('metadata',
              (v) => TestMetadata.fromJson(v as Map<String, dynamic>)),
        );
        return val;
      },
    );

TestMetadata _$TestMetadataFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'TestMetadata',
      json,
      ($checkedConvert) {
        final val = TestMetadata(
          skip: $checkedConvert('skip', (v) => v as bool),
          skipReason: $checkedConvert('skipReason', (v) => v as String?),
        );
        return val;
      },
    );

Test _$TestFromJson(Map<String, dynamic> json) => $checkedCreate(
      'Test',
      json,
      ($checkedConvert) {
        final val = Test(
          id: $checkedConvert('id', (v) => v as int),
          name: $checkedConvert('name', (v) => v as String),
          suiteID: $checkedConvert('suiteID', (v) => v as int),
          groupIDs: $checkedConvert('groupIDs',
              (v) => (v as List<dynamic>).map((e) => e as int).toList()),
          line: $checkedConvert('line', (v) => v as int?),
          column: $checkedConvert('column', (v) => v as int?),
          url: $checkedConvert('url', (v) => v as String?),
          rootLine: $checkedConvert('rootLine', (v) => v as int?),
          rootColumn: $checkedConvert('rootColumn', (v) => v as int?),
          rootUrl: $checkedConvert('rootUrl', (v) => v as String?),
          metadata: $checkedConvert('metadata',
              (v) => TestMetadata.fromJson(v as Map<String, dynamic>)),
        );
        return val;
      },
    );
