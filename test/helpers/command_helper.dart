import 'dart:async';

import 'package:mason/mason.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pub_updater/pub_updater.dart';
import 'package:usage/usage.dart';
import 'package:very_good_cli/src/command_runner.dart';

class MockAnalytics extends Mock implements Analytics {}

class MockLogger extends Mock implements Logger {}

class MockPubUpdater extends Mock implements PubUpdater {}

void Function() _overridePrint(void Function(List<String>) fn) {
  return () {
    final printLogs = <String>[];
    final spec = ZoneSpecification(
      print: (_, __, ___, String msg) {
        printLogs.add(msg);
      },
    );

    return Zone.current
        .fork(specification: spec)
        .run<void>(() => fn(printLogs));
  };
}

void Function() withRunner(
  FutureOr<void> Function(
    VeryGoodCommandRunner commandRunner,
    Logger logger,
    List<String> printLogs,
  )
      runnerFn,
) {
  return _overridePrint((printLogs) async {
    final analytics = MockAnalytics();
    final logger = MockLogger();
    final pubUpdater = MockPubUpdater();
    final progressLogs = <String>[];
    final commandRunner = VeryGoodCommandRunner(
      analytics: analytics,
      logger: logger,
      pubUpdater: pubUpdater,
    );

    when(() => analytics.firstRun).thenReturn(false);
    when(() => analytics.enabled).thenReturn(false);
    when(
      () => analytics.sendEvent(any(), any(), label: any(named: 'label')),
    ).thenAnswer((_) async {});
    when(
      () => analytics.waitForLastPing(timeout: any(named: 'timeout')),
    ).thenAnswer((_) async {});
    when(() => logger.progress(any())).thenReturn(
      ([_]) {
        if (_ != null) progressLogs.add(_);
      },
    );
    when(
      () => pubUpdater.isUpToDate(
        packageName: any(named: 'packageName'),
        currentVersion: any(named: 'currentVersion'),
      ),
    ).thenAnswer((_) => Future.value(true));

    await runnerFn(commandRunner, logger, printLogs);
  });
}
