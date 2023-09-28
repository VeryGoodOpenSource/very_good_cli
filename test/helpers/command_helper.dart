import 'dart:async';

import 'package:mason/mason.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pub_updater/pub_updater.dart';
import 'package:very_good_cli/src/command_runner.dart';

class MockLogger extends Mock implements Logger {}

class MockProgress extends Mock implements Progress {}

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
    PubUpdater pubUpdater,
    List<String> printLogs,
  ) runnerFn,
) {
  return _overridePrint((printLogs) async {
    final logger = MockLogger();
    final progress = MockProgress();
    final pubUpdater = MockPubUpdater();
    final progressLogs = <String>[];
    final commandRunner = VeryGoodCommandRunner(
      logger: logger,
      pubUpdater: pubUpdater,
      environment: {'CI': 'true'},
    );

    when(() => progress.complete(any())).thenAnswer((_) {
      final message = _.positionalArguments.elementAt(0) as String?;
      if (message != null) progressLogs.add(message);
    });
    when(() => logger.progress(any())).thenReturn(progress);
    when(
      () => pubUpdater.isUpToDate(
        packageName: any(named: 'packageName'),
        currentVersion: any(named: 'currentVersion'),
      ),
    ).thenAnswer((_) => Future.value(true));

    await runnerFn(commandRunner, logger, pubUpdater, printLogs);
  });
}
