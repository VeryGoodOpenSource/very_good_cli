// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'structured_tool_error.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Map<String, dynamic> _$TestPayloadToJson(_TestPayload instance) =>
    <String, dynamic>{
      'results': ?instance.results?.toJson(),
      'coverage': ?instance.coverage?.toJson(),
    };

Map<String, dynamic> _$TestResultsPayloadToJson(_TestResultsPayload instance) =>
    <String, dynamic>{
      'passed': instance.passed,
      'failed': instance.failed,
      'skipped': instance.skipped,
      'durationMs': instance.durationMs,
      'failingTests': instance.failingTests.map((e) => e.toJson()).toList(),
    };

Map<String, dynamic> _$FailingTestPayloadToJson(_FailingTestPayload instance) =>
    <String, dynamic>{
      'file': instance.file,
      'name': instance.name,
      'error': instance.error,
    };

Map<String, dynamic> _$CoveragePayloadToJson(_CoveragePayload instance) =>
    <String, dynamic>{
      'actual': instance.actual,
      'required': instance.requiredCoverage,
      'uncoveredLines': instance.uncoveredLines.map((e) => e.toJson()).toList(),
      'uncoveredLinesTruncated': instance.uncoveredLinesTruncated,
    };

Map<String, dynamic> _$UncoveredFilePayloadToJson(
  _UncoveredFilePayload instance,
) => <String, dynamic>{'file': instance.file, 'lines': instance.lines};
