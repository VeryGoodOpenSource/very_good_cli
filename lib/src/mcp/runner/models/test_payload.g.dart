// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'test_payload.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Map<String, dynamic> _$TestPayloadToJson(TestPayload instance) =>
    <String, dynamic>{
      'results': ?instance.results?.toJson(),
      'coverage': ?instance.coverage?.toJson(),
    };

Map<String, dynamic> _$TestResultsPayloadToJson(TestResultsPayload instance) =>
    <String, dynamic>{
      'passed': instance.passed,
      'failed': instance.failed,
      'skipped': instance.skipped,
      'durationMs': instance.durationMs,
      'failingTests': instance.failingTests.map((e) => e.toJson()).toList(),
    };

Map<String, dynamic> _$FailingTestPayloadToJson(FailingTestPayload instance) =>
    <String, dynamic>{
      'file': instance.file,
      'name': instance.name,
      'error': instance.error,
    };

Map<String, dynamic> _$CoveragePayloadToJson(CoveragePayload instance) =>
    <String, dynamic>{
      'actual': instance.actual,
      'required': instance.requiredCoverage,
      'uncoveredLines': instance.uncoveredLines.map((e) => e.toJson()).toList(),
      'uncoveredLinesTruncated': instance.uncoveredLinesTruncated,
    };

Map<String, dynamic> _$UncoveredFilePayloadToJson(
  UncoveredFilePayload instance,
) => <String, dynamic>{'file': instance.file, 'lines': instance.lines};
