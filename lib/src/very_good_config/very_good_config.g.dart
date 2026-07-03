// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'very_good_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VeryGoodConfig _$VeryGoodConfigFromJson(Map json) =>
    $checkedCreate('VeryGoodConfig', json, ($checkedConvert) {
      $checkKeys(json, allowedKeys: const ['test']);
      final val = VeryGoodConfig(
        test: $checkedConvert(
          'test',
          (v) => v == null
              ? const VeryGoodTestConfig()
              : VeryGoodTestConfig.fromJson(v as Map),
        ),
      );
      return val;
    });

VeryGoodTestConfig _$VeryGoodTestConfigFromJson(Map json) => $checkedCreate(
  'VeryGoodTestConfig',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      allowedKeys: const [
        'coverage',
        'optimization',
        'concurrency',
        'tags',
        'exclude_coverage',
        'exclude_tags',
        'min_coverage',
        'show_uncovered',
        'collect_coverage_from',
        'update_goldens',
        'fail_fast',
        'dart_define',
        'dart_define_from_file',
        'platform',
        'report_on',
        'run_skipped',
        'flavor',
        'timeout',
      ],
    );
    final val = VeryGoodTestConfig(
      coverage: $checkedConvert('coverage', (v) => v as bool?),
      optimization: $checkedConvert('optimization', (v) => v as bool?),
      concurrency: $checkedConvert('concurrency', (v) => _concurrency(v)),
      tags: $checkedConvert('tags', (v) => v as String?),
      excludeCoverage: $checkedConvert('exclude_coverage', (v) => v as String?),
      excludeTags: $checkedConvert('exclude_tags', (v) => v as String?),
      minCoverage: $checkedConvert('min_coverage', (v) => _minCoverage(v)),
      showUncovered: $checkedConvert('show_uncovered', (v) => v as bool?),
      collectCoverageFrom: $checkedConvert(
        'collect_coverage_from',
        (v) => _collectCoverageFrom(v),
      ),
      updateGoldens: $checkedConvert('update_goldens', (v) => v as bool?),
      failFast: $checkedConvert('fail_fast', (v) => v as bool?),
      dartDefine: $checkedConvert('dart_define', (v) => _stringList(v)),
      dartDefineFromFile: $checkedConvert(
        'dart_define_from_file',
        (v) => _stringList(v),
      ),
      platform: $checkedConvert('platform', (v) => v as String?),
      reportOn: $checkedConvert('report_on', (v) => _stringList(v)),
      runSkipped: $checkedConvert('run_skipped', (v) => v as bool?),
      flavor: $checkedConvert('flavor', (v) => v as String?),
      timeout: $checkedConvert('timeout', (v) => _timeout(v)),
    );
    return val;
  },
  fieldKeyMap: const {
    'excludeCoverage': 'exclude_coverage',
    'excludeTags': 'exclude_tags',
    'minCoverage': 'min_coverage',
    'showUncovered': 'show_uncovered',
    'collectCoverageFrom': 'collect_coverage_from',
    'updateGoldens': 'update_goldens',
    'failFast': 'fail_fast',
    'dartDefine': 'dart_define',
    'dartDefineFromFile': 'dart_define_from_file',
    'reportOn': 'report_on',
    'runSkipped': 'run_skipped',
  },
);
