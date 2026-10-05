part of 'cli.dart';

/// Prints the progress of a test run as its [TestEvent]s arrive, and keeps
/// the tally of passing, skipped and failing tests the summary is made of.
class _TestEventReporter {
  new({
    required this.stdout,
    required this.stderr,
    required this.optimization,
    required this.cwd,
  });

  final void Function(String) stdout;
  final void Function(String) stderr;
  final TestOptimization optimization;
  final String cwd;

  final _suites = <int, TestSuite>{};
  final _groups = <int, TestGroup>{};
  final _tests = <int, Test>{};
  final _failedTestErrorMessages = <String, List<String>>{};

  var _successCount = 0;
  var _skipCount = 0;

  void report(TestEvent event) {
    switch (event) {
      case SuiteTestEvent(:final suite):
        _suites[suite.id] = suite;
      case GroupTestEvent(:final group):
        _groups[group.id] = group;
      case TestStartEvent(:final test):
        _tests[test.id] = test;
      case MessageTestEvent():
        _reportMessage(event);
      case ErrorTestEvent():
        _reportError(event);
      case TestDoneEvent():
        _reportTestDone(event);
      case DoneTestEvent():
        _reportDone(event);
    }
  }

  void _reportMessage(MessageTestEvent event) {
    final message = event.message;
    if (message.startsWith('Skip:')) {
      stdout('$_clearLine${lightYellow.wrap(message)}\n');
    } else if (message.contains('EXCEPTION')) {
      stderr('$_clearLine$message');
    } else {
      stdout('$_clearLine$message\n');
    }
  }

  void _reportError(ErrorTestEvent event) {
    stderr('$_clearLine${event.error}');

    if (event.stackTrace.trim().isNotEmpty) {
      stderr('$_clearLine${event.stackTrace}');
    }

    final report = _resolveReport(event.testID);
    final prefix = event.isFailure ? '[FAILED]' : '[ERROR]';

    final relativeTestPath = p.relative(report.path, from: cwd);
    _failedTestErrorMessages[relativeTestPath] = [
      ...?_failedTestErrorMessages[relativeTestPath],
      '$prefix ${report.name}',
    ];
  }

  void _reportTestDone(TestDoneEvent event) {
    if (event.hidden) return;

    final (:path, :name) = _resolveReport(event.testID);
    _tallyResult(event, testPath: path, testName: name);

    final timeElapsed = Duration(milliseconds: event.time).formatted();
    final stats = _stats();
    final truncatedTestName = name.toSingleLine().truncated(
      _lineLength - (timeElapsed.length + stats.length + 2),
    );
    stdout('''$_clearLine$timeElapsed $stats: $truncatedTestName''');
  }

  void _tallyResult(
    TestDoneEvent event, {
    required String testPath,
    required String testName,
  }) {
    if (event.skipped) {
      stdout(
        '''$_clearLine${lightYellow.wrap('$testName $testPath (SKIPPED)')}\n''',
      );
      _skipCount++;
    } else if (event.result == TestResult.success) {
      _successCount++;
    } else {
      stderr('$_clearLine$testName $testPath (FAILED)');
    }
  }

  void _reportDone(DoneTestEvent event) {
    final timeElapsed = Duration(milliseconds: event.time).formatted();
    final stats = _stats();
    final success = event.success ?? false;
    final summary = success
        ? lightGreen.wrap('All tests passed!')!
        : lightRed.wrap('Some tests failed.')!;

    stdout('$_clearLine${darkGray.wrap(timeElapsed)} $stats: $summary\n');

    if (success) return;

    assert(
      _failedTestErrorMessages.isNotEmpty,
      'Invalid state: test event report as failed '
      'but no failed tests were gathered',
    );
    stderr(_failingTestsSummary());
  }

  String _failingTestsSummary() {
    final title = styleBold.wrap('Failing Tests:');

    final lines = StringBuffer('$_clearLine$title\n');
    for (final MapEntry(key: testPath, value: errorMessages)
        in _failedTestErrorMessages.entries) {
      lines.writeln('$_clearLine - $testPath ');

      for (final errorMessage in errorMessages) {
        lines.writeln('$_clearLine \t- $errorMessage');
      }
    }

    return lines.toString();
  }

  /// The file and name [testID] is reported under, once the bundling of the
  /// test optimizer is undone.
  ({String path, String name}) _resolveReport(int testID) {
    final test = _tests[testID]!;
    final suite = _suites[test.suiteID]!;

    return optimization.resolveReport(
      suitePath: suite.path!,
      testName: test.name,
      groupName: _topGroupName(test, _groups),
    );
  }

  String _stats() {
    final passingTests = _successCount.formatSuccess();
    final failingTests = _failedTestErrorMessages.values
        .expand((e) => e)
        .length
        .formatFailure();
    final skippedTests = _skipCount.formatSkipped();
    final result = [passingTests, failingTests, skippedTests]
      ..removeWhere((element) => element.isEmpty);
    return result.join(' ');
  }
}

/// The name of the outermost non-empty group [test] belongs to.
///
/// For a test running inside the optimized bundle this is the path of the file
/// it was written in, relative to `test`, which is what
/// [TestOptimization.resolveReport] needs to undo the bundling.
String? _topGroupName(Test test, Map<int, TestGroup> groups) => test.groupIDs
    .map((groupID) => groups[groupID]?.name)
    .firstWhereOrNull((groupName) => groupName?.isNotEmpty ?? false);

final int _lineLength = () {
  try {
    return stdout.terminalColumns;
  } on StdoutException {
    return 80;
  }
}();
