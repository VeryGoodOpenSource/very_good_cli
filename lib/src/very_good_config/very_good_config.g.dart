// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'very_good_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VeryGoodConfig _$VeryGoodConfigFromJson(Map json) =>
    $checkedCreate('VeryGoodConfig', json, ($checkedConvert) {
      $checkKeys(json, allowedKeys: const ['test', 'dart', 'packages']);
      final val = VeryGoodConfig(
        test: $checkedConvert(
          'test',
          (v) => v == null
              ? const VeryGoodTestConfig()
              : VeryGoodTestConfig.fromJson(v as Map),
        ),
        dart: $checkedConvert(
          'dart',
          (v) => v == null
              ? const VeryGoodDartConfig()
              : VeryGoodDartConfig.fromJson(v as Map),
        ),
        packages: $checkedConvert(
          'packages',
          (v) => v == null
              ? const VeryGoodPackagesConfig()
              : VeryGoodPackagesConfig.fromJson(v as Map),
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
        'file_reporter',
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
      fileReporter: $checkedConvert('file_reporter', (v) => v as String?),
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
    'fileReporter': 'file_reporter',
  },
);

VeryGoodDartConfig _$VeryGoodDartConfigFromJson(Map json) =>
    $checkedCreate('VeryGoodDartConfig', json, ($checkedConvert) {
      $checkKeys(json, allowedKeys: const ['test']);
      final val = VeryGoodDartConfig(
        test: $checkedConvert(
          'test',
          (v) => v == null
              ? const VeryGoodDartTestConfig()
              : VeryGoodDartTestConfig.fromJson(v as Map),
        ),
      );
      return val;
    });

VeryGoodDartTestConfig _$VeryGoodDartTestConfigFromJson(Map json) =>
    $checkedCreate(
      'VeryGoodDartTestConfig',
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
            'fail_fast',
            'platform',
            'report_on',
            'run_skipped',
            'check_ignore',
            'file_reporter',
          ],
        );
        final val = VeryGoodDartTestConfig(
          coverage: $checkedConvert('coverage', (v) => v as bool?),
          optimization: $checkedConvert('optimization', (v) => v as bool?),
          concurrency: $checkedConvert('concurrency', (v) => _concurrency(v)),
          tags: $checkedConvert('tags', (v) => v as String?),
          excludeCoverage: $checkedConvert(
            'exclude_coverage',
            (v) => v as String?,
          ),
          excludeTags: $checkedConvert('exclude_tags', (v) => v as String?),
          minCoverage: $checkedConvert('min_coverage', (v) => _minCoverage(v)),
          showUncovered: $checkedConvert('show_uncovered', (v) => v as bool?),
          collectCoverageFrom: $checkedConvert(
            'collect_coverage_from',
            (v) => _collectCoverageFrom(v),
          ),
          failFast: $checkedConvert('fail_fast', (v) => v as bool?),
          platform: $checkedConvert('platform', (v) => v as String?),
          reportOn: $checkedConvert('report_on', (v) => _stringList(v)),
          runSkipped: $checkedConvert('run_skipped', (v) => v as bool?),
          checkIgnore: $checkedConvert('check_ignore', (v) => v as bool?),
          fileReporter: $checkedConvert('file_reporter', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {
        'excludeCoverage': 'exclude_coverage',
        'excludeTags': 'exclude_tags',
        'minCoverage': 'min_coverage',
        'showUncovered': 'show_uncovered',
        'collectCoverageFrom': 'collect_coverage_from',
        'failFast': 'fail_fast',
        'reportOn': 'report_on',
        'runSkipped': 'run_skipped',
        'checkIgnore': 'check_ignore',
        'fileReporter': 'file_reporter',
      },
    );

VeryGoodPackagesConfig _$VeryGoodPackagesConfigFromJson(Map json) =>
    $checkedCreate('VeryGoodPackagesConfig', json, ($checkedConvert) {
      $checkKeys(json, allowedKeys: const ['get', 'check']);
      final val = VeryGoodPackagesConfig(
        get: $checkedConvert(
          'get',
          (v) => v == null
              ? const VeryGoodPackagesGetConfig()
              : VeryGoodPackagesGetConfig.fromJson(v as Map),
        ),
        check: $checkedConvert(
          'check',
          (v) => v == null
              ? const VeryGoodPackagesCheckConfig()
              : VeryGoodPackagesCheckConfig.fromJson(v as Map),
        ),
      );
      return val;
    });

VeryGoodPackagesGetConfig _$VeryGoodPackagesGetConfigFromJson(Map json) =>
    $checkedCreate('VeryGoodPackagesGetConfig', json, ($checkedConvert) {
      $checkKeys(json, allowedKeys: const ['recursive', 'ignore']);
      final val = VeryGoodPackagesGetConfig(
        recursive: $checkedConvert('recursive', (v) => v as bool?),
        ignore: $checkedConvert('ignore', (v) => _stringList(v)),
      );
      return val;
    });

VeryGoodPackagesCheckConfig _$VeryGoodPackagesCheckConfigFromJson(Map json) =>
    $checkedCreate('VeryGoodPackagesCheckConfig', json, ($checkedConvert) {
      $checkKeys(json, allowedKeys: const ['licenses']);
      final val = VeryGoodPackagesCheckConfig(
        licenses: $checkedConvert(
          'licenses',
          (v) => v == null
              ? const VeryGoodPackagesCheckLicensesConfig()
              : VeryGoodPackagesCheckLicensesConfig.fromJson(v as Map),
        ),
      );
      return val;
    });

VeryGoodPackagesCheckLicensesConfig
_$VeryGoodPackagesCheckLicensesConfigFromJson(Map json) => $checkedCreate(
  'VeryGoodPackagesCheckLicensesConfig',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      allowedKeys: const [
        'ignore_retrieval_failures',
        'dependency_type',
        'allowed',
        'forbidden',
        'skip_packages',
        'reporter',
      ],
    );
    final val = VeryGoodPackagesCheckLicensesConfig(
      ignoreRetrievalFailures: $checkedConvert(
        'ignore_retrieval_failures',
        (v) => v as bool?,
      ),
      dependencyType: $checkedConvert(
        'dependency_type',
        (v) => _dependencyType(v),
      ),
      allowed: $checkedConvert('allowed', (v) => _stringList(v)),
      forbidden: $checkedConvert('forbidden', (v) => _stringList(v)),
      skipPackages: $checkedConvert('skip_packages', (v) => _stringList(v)),
      reporter: $checkedConvert('reporter', (v) => _reporter(v)),
    );
    return val;
  },
  fieldKeyMap: const {
    'ignoreRetrievalFailures': 'ignore_retrieval_failures',
    'dependencyType': 'dependency_type',
    'skipPackages': 'skip_packages',
  },
);
