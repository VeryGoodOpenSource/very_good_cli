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
        'exclude-coverage',
        'exclude-tags',
        'min-coverage',
        'show-uncovered',
        'collect-coverage-from',
        'update-goldens',
        'fail-fast',
        'dart-define',
        'dart-define-from-file',
        'platform',
        'report-on',
        'run-skipped',
        'flavor',
        'timeout',
      ],
    );
    final val = VeryGoodTestConfig(
      coverage: $checkedConvert('coverage', (v) => v as bool?),
      optimization: $checkedConvert('optimization', (v) => v as bool?),
      concurrency: $checkedConvert('concurrency', (v) => _concurrency(v)),
      tags: $checkedConvert('tags', (v) => v as String?),
      excludeCoverage: $checkedConvert('exclude-coverage', (v) => v as String?),
      excludeTags: $checkedConvert('exclude-tags', (v) => v as String?),
      minCoverage: $checkedConvert('min-coverage', (v) => _minCoverage(v)),
      showUncovered: $checkedConvert('show-uncovered', (v) => v as bool?),
      collectCoverageFrom: $checkedConvert(
        'collect-coverage-from',
        (v) => _collectCoverageFrom(v),
      ),
      updateGoldens: $checkedConvert('update-goldens', (v) => v as bool?),
      failFast: $checkedConvert('fail-fast', (v) => v as bool?),
      dartDefine: $checkedConvert('dart-define', (v) => _stringList(v)),
      dartDefineFromFile: $checkedConvert(
        'dart-define-from-file',
        (v) => _stringList(v),
      ),
      platform: $checkedConvert('platform', (v) => v as String?),
      reportOn: $checkedConvert('report-on', (v) => _stringList(v)),
      runSkipped: $checkedConvert('run-skipped', (v) => v as bool?),
      flavor: $checkedConvert('flavor', (v) => v as String?),
      timeout: $checkedConvert('timeout', (v) => _timeout(v)),
    );
    return val;
  },
  fieldKeyMap: const {
    'excludeCoverage': 'exclude-coverage',
    'excludeTags': 'exclude-tags',
    'minCoverage': 'min-coverage',
    'showUncovered': 'show-uncovered',
    'collectCoverageFrom': 'collect-coverage-from',
    'updateGoldens': 'update-goldens',
    'failFast': 'fail-fast',
    'dartDefine': 'dart-define',
    'dartDefineFromFile': 'dart-define-from-file',
    'reportOn': 'report-on',
    'runSkipped': 'run-skipped',
  },
);
