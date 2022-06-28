// ignore_for_file: implicit_dynamic_list_literal, lines_longer_than_80_chars

const passingJsonOutput = [
  {
    'protocolVersion': '0.1.1',
    'runnerVersion': '1.21.1',
    'pid': 74133,
    'type': 'start',
    'time': 0
  },
  {
    'suite': {
      'id': 0,
      'platform': 'vm',
      'path': '/my_app/test/app/view/app_test.dart'
    },
    'type': 'suite',
    'time': 0
  },
  {
    'test': {
      'id': 1,
      'name': 'loading /my_app/test/app/view/app_test.dart',
      'suiteID': 0,
      'groupIDs': [],
      'metadata': {'skip': false, 'skipReason': null},
      'line': null,
      'column': null,
      'url': null
    },
    'type': 'testStart',
    'time': 1
  },
  {
    'suite': {
      'id': 2,
      'platform': 'vm',
      'path': '/my_app/test/counter/cubit/counter_cubit_test.dart'
    },
    'type': 'suite',
    'time': 9
  },
  {
    'test': {
      'id': 3,
      'name': 'loading /my_app/test/counter/cubit/counter_cubit_test.dart',
      'suiteID': 2,
      'groupIDs': [],
      'metadata': {'skip': false, 'skipReason': null},
      'line': null,
      'column': null,
      'url': null
    },
    'type': 'testStart',
    'time': 9
  },
  {
    'suite': {
      'id': 4,
      'platform': 'vm',
      'path': '/my_app/test/counter/view/counter_page_test.dart'
    },
    'type': 'suite',
    'time': 10
  },
  {
    'test': {
      'id': 5,
      'name': 'loading /my_app/test/counter/view/counter_page_test.dart',
      'suiteID': 4,
      'groupIDs': [],
      'metadata': {'skip': false, 'skipReason': null},
      'line': null,
      'column': null,
      'url': null
    },
    'type': 'testStart',
    'time': 10
  },
  {'count': 3, 'time': 11, 'type': 'allSuites'},
  {
    'testID': 1,
    'result': 'success',
    'skipped': false,
    'hidden': true,
    'type': 'testDone',
    'time': 2496
  },
  {
    'group': {
      'id': 6,
      'suiteID': 0,
      'parentID': null,
      'name': '',
      'metadata': {'skip': false, 'skipReason': null},
      'testCount': 1,
      'line': null,
      'column': null,
      'url': null
    },
    'type': 'group',
    'time': 2501
  },
  {
    'group': {
      'id': 7,
      'suiteID': 0,
      'parentID': 6,
      'name': 'App',
      'metadata': {'skip': false, 'skipReason': null},
      'testCount': 1,
      'line': 13,
      'column': 3,
      'url': 'file:///my_app/test/app/view/app_test.dart'
    },
    'type': 'group',
    'time': 2502
  },
  {
    'test': {
      'id': 8,
      'name': 'App renders CounterPage',
      'suiteID': 0,
      'groupIDs': [6, 7],
      'metadata': {'skip': false, 'skipReason': null},
      'line': 153,
      'column': 5,
      'url': 'package:flutter_test/src/widget_tester.dart',
      'root_line': 14,
      'root_column': 5,
      'root_url': 'file:///my_app/test/app/view/app_test.dart'
    },
    'type': 'testStart',
    'time': 2502
  },
  {
    'testID': 3,
    'result': 'success',
    'skipped': false,
    'hidden': true,
    'type': 'testDone',
    'time': 2578
  },
  {
    'group': {
      'id': 9,
      'suiteID': 2,
      'parentID': null,
      'name': '',
      'metadata': {'skip': false, 'skipReason': null},
      'testCount': 3,
      'line': null,
      'column': null,
      'url': null
    },
    'type': 'group',
    'time': 2579
  },
  {
    'group': {
      'id': 10,
      'suiteID': 2,
      'parentID': 9,
      'name': 'CounterCubit',
      'metadata': {'skip': false, 'skipReason': null},
      'testCount': 3,
      'line': 14,
      'column': 3,
      'url': 'file:///my_app/test/counter/cubit/counter_cubit_test.dart'
    },
    'type': 'group',
    'time': 2579
  },
  {
    'test': {
      'id': 11,
      'name': 'CounterCubit initial state is 0',
      'suiteID': 2,
      'groupIDs': [9, 10],
      'metadata': {'skip': false, 'skipReason': null},
      'line': 15,
      'column': 5,
      'url': 'file:///my_app/test/counter/cubit/counter_cubit_test.dart'
    },
    'type': 'testStart',
    'time': 2579
  },
  {
    'testID': 11,
    'result': 'success',
    'skipped': false,
    'hidden': false,
    'type': 'testDone',
    'time': 2614
  },
  {
    'test': {
      'id': 12,
      'name': 'CounterCubit emits [1] when increment is called',
      'suiteID': 2,
      'groupIDs': [9, 10],
      'metadata': {'skip': false, 'skipReason': null},
      'line': 153,
      'column': 8,
      'url': 'package:bloc_test/src/bloc_test.dart',
      'root_line': 19,
      'root_column': 5,
      'root_url': 'file:///my_app/test/counter/cubit/counter_cubit_test.dart'
    },
    'type': 'testStart',
    'time': 2615
  },
  {
    'testID': 12,
    'result': 'success',
    'skipped': false,
    'hidden': false,
    'type': 'testDone',
    'time': 2633
  },
  {
    'test': {
      'id': 13,
      'name': 'CounterCubit emits [-1] when decrement is called',
      'suiteID': 2,
      'groupIDs': [9, 10],
      'metadata': {'skip': false, 'skipReason': null},
      'line': 153,
      'column': 8,
      'url': 'package:bloc_test/src/bloc_test.dart',
      'root_line': 26,
      'root_column': 5,
      'root_url': 'file:///my_app/test/counter/cubit/counter_cubit_test.dart'
    },
    'type': 'testStart',
    'time': 2634
  },
  {
    'testID': 13,
    'result': 'success',
    'skipped': false,
    'hidden': false,
    'type': 'testDone',
    'time': 2638
  },
  {
    'testID': 5,
    'result': 'success',
    'skipped': false,
    'hidden': true,
    'type': 'testDone',
    'time': 2836
  },
  {
    'group': {
      'id': 14,
      'suiteID': 4,
      'parentID': null,
      'name': '',
      'metadata': {'skip': false, 'skipReason': null},
      'testCount': 4,
      'line': null,
      'column': null,
      'url': null
    },
    'type': 'group',
    'time': 2836
  },
  {
    'group': {
      'id': 15,
      'suiteID': 4,
      'parentID': 14,
      'name': 'CounterPage',
      'metadata': {'skip': false, 'skipReason': null},
      'testCount': 1,
      'line': 21,
      'column': 3,
      'url': 'file:///my_app/test/counter/view/counter_page_test.dart'
    },
    'type': 'group',
    'time': 2836
  },
  {
    'test': {
      'id': 16,
      'name': 'CounterPage renders CounterView',
      'suiteID': 4,
      'groupIDs': [14, 15],
      'metadata': {'skip': false, 'skipReason': null},
      'line': 153,
      'column': 5,
      'url': 'package:flutter_test/src/widget_tester.dart',
      'root_line': 22,
      'root_column': 5,
      'root_url': 'file:///my_app/test/counter/view/counter_page_test.dart'
    },
    'type': 'testStart',
    'time': 2836
  },
  {
    'testID': 8,
    'result': 'success',
    'skipped': false,
    'hidden': false,
    'type': 'testDone',
    'time': 3433
  },
  {
    'testID': 16,
    'result': 'success',
    'skipped': false,
    'hidden': false,
    'type': 'testDone',
    'time': 3750
  },
  {
    'group': {
      'id': 17,
      'suiteID': 4,
      'parentID': 14,
      'name': 'CounterView',
      'metadata': {'skip': false, 'skipReason': null},
      'testCount': 3,
      'line': 28,
      'column': 3,
      'url': 'file:///my_app/test/counter/view/counter_page_test.dart'
    },
    'type': 'group',
    'time': 3750
  },
  {
    'test': {
      'id': 18,
      'name': 'CounterView renders current count',
      'suiteID': 4,
      'groupIDs': [14, 17],
      'metadata': {'skip': false, 'skipReason': null},
      'line': 153,
      'column': 5,
      'url': 'package:flutter_test/src/widget_tester.dart',
      'root_line': 35,
      'root_column': 5,
      'root_url': 'file:///my_app/test/counter/view/counter_page_test.dart'
    },
    'type': 'testStart',
    'time': 3750
  },
  {
    'testID': 18,
    'result': 'success',
    'skipped': false,
    'hidden': false,
    'type': 'testDone',
    'time': 3825
  },
  {
    'test': {
      'id': 19,
      'name': 'CounterView calls increment when increment button is tapped',
      'suiteID': 4,
      'groupIDs': [14, 17],
      'metadata': {'skip': false, 'skipReason': null},
      'line': 153,
      'column': 5,
      'url': 'package:flutter_test/src/widget_tester.dart',
      'root_line': 47,
      'root_column': 5,
      'root_url': 'file:///my_app/test/counter/view/counter_page_test.dart'
    },
    'type': 'testStart',
    'time': 3825
  },
  {
    'testID': 19,
    'result': 'success',
    'skipped': false,
    'hidden': false,
    'type': 'testDone',
    'time': 3955
  },
  {
    'test': {
      'id': 20,
      'name': 'CounterView calls decrement when decrement button is tapped',
      'suiteID': 4,
      'groupIDs': [14, 17],
      'metadata': {'skip': false, 'skipReason': null},
      'line': 153,
      'column': 5,
      'url': 'package:flutter_test/src/widget_tester.dart',
      'root_line': 61,
      'root_column': 5,
      'root_url': 'file:///my_app/test/counter/view/counter_page_test.dart'
    },
    'type': 'testStart',
    'time': 3955
  },
  {
    'testID': 20,
    'result': 'success',
    'skipped': false,
    'hidden': false,
    'type': 'testDone',
    'time': 3997
  },
  {'success': true, 'type': 'done', 'time': 4015},
];

const failingJsonOutput = [
  {
    'protocolVersion': '0.1.1',
    'runnerVersion': '1.21.1',
    'pid': 70841,
    'type': 'start',
    'time': 0
  },
  {
    'suite': {
      'id': 0,
      'platform': 'vm',
      'path': '/my_app/test/app/view/app_test.dart'
    },
    'type': 'suite',
    'time': 0
  },
  {
    'test': {
      'id': 1,
      'name': 'loading /my_app/test/app/view/app_test.dart',
      'suiteID': 0,
      'groupIDs': [],
      'metadata': {'skip': false, 'skipReason': null},
      'line': null,
      'column': null,
      'url': null
    },
    'type': 'testStart',
    'time': 2
  },
  {
    'suite': {
      'id': 2,
      'platform': 'vm',
      'path': '/my_app/test/counter/cubit/counter_cubit_test.dart'
    },
    'type': 'suite',
    'time': 8
  },
  {
    'test': {
      'id': 3,
      'name': 'loading /my_app/test/counter/cubit/counter_cubit_test.dart',
      'suiteID': 2,
      'groupIDs': [],
      'metadata': {'skip': false, 'skipReason': null},
      'line': null,
      'column': null,
      'url': null
    },
    'type': 'testStart',
    'time': 8
  },
  {
    'suite': {
      'id': 4,
      'platform': 'vm',
      'path': '/my_app/test/counter/view/counter_page_test.dart'
    },
    'type': 'suite',
    'time': 10
  },
  {
    'test': {
      'id': 5,
      'name': 'loading /my_app/test/counter/view/counter_page_test.dart',
      'suiteID': 4,
      'groupIDs': [],
      'metadata': {'skip': false, 'skipReason': null},
      'line': null,
      'column': null,
      'url': null
    },
    'type': 'testStart',
    'time': 10
  },
  {'count': 3, 'time': 10, 'type': 'allSuites'},
  {
    'testID': 1,
    'result': 'success',
    'skipped': false,
    'hidden': true,
    'type': 'testDone',
    'time': 10947
  },
  {
    'group': {
      'id': 6,
      'suiteID': 0,
      'parentID': null,
      'name': '',
      'metadata': {'skip': false, 'skipReason': null},
      'testCount': 1,
      'line': null,
      'column': null,
      'url': null
    },
    'type': 'group',
    'time': 10953
  },
  {
    'group': {
      'id': 7,
      'suiteID': 0,
      'parentID': 6,
      'name': 'App',
      'metadata': {'skip': false, 'skipReason': null},
      'testCount': 1,
      'line': 13,
      'column': 3,
      'url': 'file:///my_app/test/app/view/app_test.dart'
    },
    'type': 'group',
    'time': 10954
  },
  {
    'test': {
      'id': 8,
      'name': 'App renders CounterPage',
      'suiteID': 0,
      'groupIDs': [6, 7],
      'metadata': {'skip': false, 'skipReason': null},
      'line': 153,
      'column': 5,
      'url': 'package:flutter_test/src/widget_tester.dart',
      'root_line': 14,
      'root_column': 5,
      'root_url': 'file:///my_app/test/app/view/app_test.dart'
    },
    'type': 'testStart',
    'time': 10954
  },
  {
    'testID': 3,
    'result': 'success',
    'skipped': false,
    'hidden': true,
    'type': 'testDone',
    'time': 11237
  },
  {
    'group': {
      'id': 9,
      'suiteID': 2,
      'parentID': null,
      'name': '',
      'metadata': {'skip': false, 'skipReason': null},
      'testCount': 3,
      'line': null,
      'column': null,
      'url': null
    },
    'type': 'group',
    'time': 11238
  },
  {
    'group': {
      'id': 10,
      'suiteID': 2,
      'parentID': 9,
      'name': 'CounterCubit',
      'metadata': {'skip': false, 'skipReason': null},
      'testCount': 3,
      'line': 14,
      'column': 3,
      'url': 'file:///my_app/test/counter/cubit/counter_cubit_test.dart'
    },
    'type': 'group',
    'time': 11238
  },
  {
    'test': {
      'id': 11,
      'name': 'CounterCubit initial state is 0',
      'suiteID': 2,
      'groupIDs': [9, 10],
      'metadata': {'skip': false, 'skipReason': null},
      'line': 15,
      'column': 5,
      'url': 'file:///my_app/test/counter/cubit/counter_cubit_test.dart'
    },
    'type': 'testStart',
    'time': 11238
  },
  {
    'testID': 11,
    'error': 'Expected: <1>\n  Actual: <0>\n',
    'stackTrace':
        'package:test_api                                    expect\npackage:flutter_test/src/widget_tester.dart 455:16  expect\ntest/counter/cubit/counter_cubit_test.dart 16:7     main.<fn>.<fn>\n',
    'isFailure': true,
    'type': 'error',
    'time': 11305
  },
  {
    'testID': 11,
    'result': 'failure',
    'skipped': false,
    'hidden': false,
    'type': 'testDone',
    'time': 11306
  },
  {
    'test': {
      'id': 12,
      'name': 'CounterCubit emits [1] when increment is called',
      'suiteID': 2,
      'groupIDs': [9, 10],
      'metadata': {'skip': false, 'skipReason': null},
      'line': 153,
      'column': 8,
      'url': 'package:bloc_test/src/bloc_test.dart',
      'root_line': 19,
      'root_column': 5,
      'root_url': 'file:///my_app/test/counter/cubit/counter_cubit_test.dart'
    },
    'type': 'testStart',
    'time': 11306
  },
  {
    'testID': 12,
    'result': 'success',
    'skipped': false,
    'hidden': false,
    'type': 'testDone',
    'time': 11321
  },
  {
    'test': {
      'id': 13,
      'name': 'CounterCubit emits [-1] when decrement is called',
      'suiteID': 2,
      'groupIDs': [9, 10],
      'metadata': {'skip': false, 'skipReason': null},
      'line': 153,
      'column': 8,
      'url': 'package:bloc_test/src/bloc_test.dart',
      'root_line': 26,
      'root_column': 5,
      'root_url': 'file:///my_app/test/counter/cubit/counter_cubit_test.dart'
    },
    'type': 'testStart',
    'time': 11322
  },
  {
    'testID': 13,
    'result': 'success',
    'skipped': false,
    'hidden': false,
    'type': 'testDone',
    'time': 11326
  },
  {
    'testID': 5,
    'result': 'success',
    'skipped': false,
    'hidden': true,
    'type': 'testDone',
    'time': 11543
  },
  {
    'group': {
      'id': 14,
      'suiteID': 4,
      'parentID': null,
      'name': '',
      'metadata': {'skip': false, 'skipReason': null},
      'testCount': 4,
      'line': null,
      'column': null,
      'url': null
    },
    'type': 'group',
    'time': 11543
  },
  {
    'group': {
      'id': 15,
      'suiteID': 4,
      'parentID': 14,
      'name': 'CounterPage',
      'metadata': {'skip': false, 'skipReason': null},
      'testCount': 1,
      'line': 21,
      'column': 3,
      'url': 'file:///my_app/test/counter/view/counter_page_test.dart'
    },
    'type': 'group',
    'time': 11544
  },
  {
    'test': {
      'id': 16,
      'name': 'CounterPage renders CounterView',
      'suiteID': 4,
      'groupIDs': [14, 15],
      'metadata': {'skip': false, 'skipReason': null},
      'line': 153,
      'column': 5,
      'url': 'package:flutter_test/src/widget_tester.dart',
      'root_line': 22,
      'root_column': 5,
      'root_url': 'file:///my_app/test/counter/view/counter_page_test.dart'
    },
    'type': 'testStart',
    'time': 11544
  },
  {
    'testID': 8,
    'result': 'success',
    'skipped': false,
    'hidden': false,
    'type': 'testDone',
    'time': 11990
  },
  {
    'testID': 16,
    'result': 'success',
    'skipped': false,
    'hidden': false,
    'type': 'testDone',
    'time': 12481
  },
  {
    'group': {
      'id': 17,
      'suiteID': 4,
      'parentID': 14,
      'name': 'CounterView',
      'metadata': {'skip': false, 'skipReason': null},
      'testCount': 3,
      'line': 28,
      'column': 3,
      'url': 'file:///my_app/test/counter/view/counter_page_test.dart'
    },
    'type': 'group',
    'time': 12481
  },
  {
    'test': {
      'id': 18,
      'name': 'CounterView renders current count',
      'suiteID': 4,
      'groupIDs': [14, 17],
      'metadata': {'skip': false, 'skipReason': null},
      'line': 153,
      'column': 5,
      'url': 'package:flutter_test/src/widget_tester.dart',
      'root_line': 35,
      'root_column': 5,
      'root_url': 'file:///my_app/test/counter/view/counter_page_test.dart'
    },
    'type': 'testStart',
    'time': 12481
  },
  {
    'testID': 18,
    'result': 'success',
    'skipped': false,
    'hidden': false,
    'type': 'testDone',
    'time': 12554
  },
  {
    'test': {
      'id': 19,
      'name': 'CounterView calls increment when increment button is tapped',
      'suiteID': 4,
      'groupIDs': [14, 17],
      'metadata': {'skip': false, 'skipReason': null},
      'line': 153,
      'column': 5,
      'url': 'package:flutter_test/src/widget_tester.dart',
      'root_line': 47,
      'root_column': 5,
      'root_url': 'file:///my_app/test/counter/view/counter_page_test.dart'
    },
    'type': 'testStart',
    'time': 12554
  },
  {
    'testID': 19,
    'result': 'success',
    'skipped': false,
    'hidden': false,
    'type': 'testDone',
    'time': 12684
  },
  {
    'test': {
      'id': 20,
      'name': 'CounterView calls decrement when decrement button is tapped',
      'suiteID': 4,
      'groupIDs': [14, 17],
      'metadata': {'skip': false, 'skipReason': null},
      'line': 153,
      'column': 5,
      'url': 'package:flutter_test/src/widget_tester.dart',
      'root_line': 61,
      'root_column': 5,
      'root_url': 'file:///my_app/test/counter/view/counter_page_test.dart'
    },
    'type': 'testStart',
    'time': 12684
  },
  {
    'testID': 20,
    'result': 'success',
    'skipped': false,
    'hidden': false,
    'type': 'testDone',
    'time': 12728
  },
  {'success': false, 'type': 'done', 'time': 12745},
];

const skipExceptionMessageJsonOuput = [
  {
    'protocolVersion': '0.1.1',
    'runnerVersion': '1.21.1',
    'pid': 90255,
    'type': 'start',
    'time': 0
  },
  {
    'suite': {
      'id': 0,
      'platform': 'vm',
      'path': '/my_app/test/app/view/app_test.dart'
    },
    'type': 'suite',
    'time': 0
  },
  {
    'test': {
      'id': 1,
      'name': 'loading /my_app/test/app/view/app_test.dart',
      'suiteID': 0,
      'groupIDs': [],
      'metadata': {'skip': false, 'skipReason': null},
      'line': null,
      'column': null,
      'url': null
    },
    'type': 'testStart',
    'time': 1
  },
  {
    'suite': {
      'id': 2,
      'platform': 'vm',
      'path': '/my_app/test/counter/cubit/counter_cubit_test.dart'
    },
    'type': 'suite',
    'time': 8
  },
  {
    'test': {
      'id': 3,
      'name': 'loading /my_app/test/counter/cubit/counter_cubit_test.dart',
      'suiteID': 2,
      'groupIDs': [],
      'metadata': {'skip': false, 'skipReason': null},
      'line': null,
      'column': null,
      'url': null
    },
    'type': 'testStart',
    'time': 8
  },
  {
    'suite': {
      'id': 4,
      'platform': 'vm',
      'path': '/my_app/test/counter/view/long_name_test.dart'
    },
    'type': 'suite',
    'time': 9
  },
  {
    'test': {
      'id': 5,
      'name': 'loading /my_app/test/counter/view/long_name_test.dart',
      'suiteID': 4,
      'groupIDs': [],
      'metadata': {'skip': false, 'skipReason': null},
      'line': null,
      'column': null,
      'url': null
    },
    'type': 'testStart',
    'time': 9
  },
  {
    'suite': {
      'id': 6,
      'platform': 'vm',
      'path': '/my_app/test/counter/view/counter_page_test.dart'
    },
    'type': 'suite',
    'time': 9
  },
  {
    'test': {
      'id': 7,
      'name': 'loading /my_app/test/counter/view/counter_page_test.dart',
      'suiteID': 6,
      'groupIDs': [],
      'metadata': {'skip': false, 'skipReason': null},
      'line': null,
      'column': null,
      'url': null
    },
    'type': 'testStart',
    'time': 9
  },
  {
    'suite': {
      'id': 8,
      'platform': 'vm',
      'path': '/my_app/test/counter/view/other_test.dart'
    },
    'type': 'suite',
    'time': 10
  },
  {
    'test': {
      'id': 9,
      'name': 'loading /my_app/test/counter/view/other_test.dart',
      'suiteID': 8,
      'groupIDs': [],
      'metadata': {'skip': false, 'skipReason': null},
      'line': null,
      'column': null,
      'url': null
    },
    'type': 'testStart',
    'time': 11
  },
  {'count': 5, 'time': 11, 'type': 'allSuites'},
  {
    'testID': 9,
    'result': 'success',
    'skipped': false,
    'hidden': true,
    'type': 'testDone',
    'time': 109
  },
  {
    'group': {
      'id': 10,
      'suiteID': 8,
      'parentID': null,
      'name': '',
      'metadata': {
        'skip': true,
        'skipReason': 'currently failing (see issue 1234)'
      },
      'testCount': 1,
      'line': null,
      'column': null,
      'url': null
    },
    'type': 'group',
    'time': 113
  },
  {
    'test': {
      'id': 11,
      'name': '(suite)',
      'suiteID': 8,
      'groupIDs': [10],
      'metadata': {
        'skip': true,
        'skipReason': 'currently failing (see issue 1234)'
      },
      'line': null,
      'column': null,
      'url': null
    },
    'type': 'testStart',
    'time': 113
  },
  {
    'testID': 11,
    'messageType': 'skip',
    'message': 'Skip: currently failing (see issue 1234)',
    'type': 'print',
    'time': 114
  },
  {
    'testID': 11,
    'result': 'success',
    'skipped': true,
    'hidden': false,
    'type': 'testDone',
    'time': 114
  },
  {
    'testID': 3,
    'result': 'success',
    'skipped': false,
    'hidden': true,
    'type': 'testDone',
    'time': 2724
  },
  {
    'group': {
      'id': 12,
      'suiteID': 2,
      'parentID': null,
      'name': '',
      'metadata': {'skip': false, 'skipReason': null},
      'testCount': 3,
      'line': null,
      'column': null,
      'url': null
    },
    'type': 'group',
    'time': 2724
  },
  {
    'group': {
      'id': 13,
      'suiteID': 2,
      'parentID': 12,
      'name': 'CounterCubit',
      'metadata': {'skip': false, 'skipReason': null},
      'testCount': 3,
      'line': 14,
      'column': 3,
      'url': 'file:///my_app/test/counter/cubit/counter_cubit_test.dart'
    },
    'type': 'group',
    'time': 2725
  },
  {
    'test': {
      'id': 14,
      'name': 'CounterCubit initial state is 0',
      'suiteID': 2,
      'groupIDs': [12, 13],
      'metadata': {'skip': true, 'skipReason': null},
      'line': 15,
      'column': 5,
      'url': 'file:///my_app/test/counter/cubit/counter_cubit_test.dart'
    },
    'type': 'testStart',
    'time': 2725
  },
  {
    'testID': 14,
    'result': 'success',
    'skipped': true,
    'hidden': false,
    'type': 'testDone',
    'time': 2725
  },
  {
    'test': {
      'id': 15,
      'name': 'CounterCubit emits [1] when increment is called',
      'suiteID': 2,
      'groupIDs': [12, 13],
      'metadata': {'skip': false, 'skipReason': null},
      'line': 153,
      'column': 8,
      'url': 'package:bloc_test/src/bloc_test.dart',
      'root_line': 23,
      'root_column': 5,
      'root_url': 'file:///my_app/test/counter/cubit/counter_cubit_test.dart'
    },
    'type': 'testStart',
    'time': 2726
  },
  {
    'testID': 5,
    'result': 'success',
    'skipped': false,
    'hidden': true,
    'type': 'testDone',
    'time': 2757
  },
  {
    'group': {
      'id': 16,
      'suiteID': 4,
      'parentID': null,
      'name': '',
      'metadata': {'skip': false, 'skipReason': null},
      'testCount': 1,
      'line': null,
      'column': null,
      'url': null
    },
    'type': 'group',
    'time': 2757
  },
  {
    'test': {
      'id': 17,
      'name':
          'this is a really long test name that should get truncated by very_good test',
      'suiteID': 4,
      'groupIDs': [16],
      'metadata': {'skip': false, 'skipReason': null},
      'line': 4,
      'column': 3,
      'url': 'file:///my_app/test/counter/view/long_name_test.dart'
    },
    'type': 'testStart',
    'time': 2757
  },
  {
    'testID': 15,
    'result': 'success',
    'skipped': false,
    'hidden': false,
    'type': 'testDone',
    'time': 2789
  },
  {
    'test': {
      'id': 18,
      'name': 'CounterCubit emits [-1] when decrement is called',
      'suiteID': 2,
      'groupIDs': [12, 13],
      'metadata': {'skip': false, 'skipReason': null},
      'line': 153,
      'column': 8,
      'url': 'package:bloc_test/src/bloc_test.dart',
      'root_line': 30,
      'root_column': 5,
      'root_url': 'file:///my_app/test/counter/cubit/counter_cubit_test.dart'
    },
    'type': 'testStart',
    'time': 2789
  },
  {
    'testID': 18,
    'result': 'success',
    'skipped': false,
    'hidden': false,
    'type': 'testDone',
    'time': 2801
  },
  {
    'testID': 17,
    'result': 'success',
    'skipped': false,
    'hidden': false,
    'type': 'testDone',
    'time': 2813
  },
  {
    'testID': 1,
    'result': 'success',
    'skipped': false,
    'hidden': true,
    'type': 'testDone',
    'time': 2819
  },
  {
    'group': {
      'id': 19,
      'suiteID': 0,
      'parentID': null,
      'name': '',
      'metadata': {'skip': false, 'skipReason': null},
      'testCount': 1,
      'line': null,
      'column': null,
      'url': null
    },
    'type': 'group',
    'time': 2820
  },
  {
    'group': {
      'id': 20,
      'suiteID': 0,
      'parentID': 19,
      'name': 'App',
      'metadata': {'skip': false, 'skipReason': null},
      'testCount': 1,
      'line': 13,
      'column': 3,
      'url': 'file:///my_app/test/app/view/app_test.dart'
    },
    'type': 'group',
    'time': 2820
  },
  {
    'test': {
      'id': 21,
      'name': 'App renders CounterPage',
      'suiteID': 0,
      'groupIDs': [19, 20],
      'metadata': {'skip': false, 'skipReason': null},
      'line': 153,
      'column': 5,
      'url': 'package:flutter_test/src/widget_tester.dart',
      'root_line': 14,
      'root_column': 5,
      'root_url': 'file:///my_app/test/app/view/app_test.dart'
    },
    'type': 'testStart',
    'time': 2820
  },
  {
    'testID': 7,
    'result': 'success',
    'skipped': false,
    'hidden': true,
    'type': 'testDone',
    'time': 3113
  },
  {
    'group': {
      'id': 22,
      'suiteID': 6,
      'parentID': null,
      'name': '',
      'metadata': {'skip': false, 'skipReason': null},
      'testCount': 4,
      'line': null,
      'column': null,
      'url': null
    },
    'type': 'group',
    'time': 3113
  },
  {
    'group': {
      'id': 23,
      'suiteID': 6,
      'parentID': 22,
      'name': 'CounterPage',
      'metadata': {'skip': false, 'skipReason': null},
      'testCount': 1,
      'line': 21,
      'column': 3,
      'url': 'file:///my_app/test/counter/view/counter_page_test.dart'
    },
    'type': 'group',
    'time': 3113
  },
  {
    'test': {
      'id': 24,
      'name': 'CounterPage renders CounterView',
      'suiteID': 6,
      'groupIDs': [22, 23],
      'metadata': {'skip': false, 'skipReason': null},
      'line': 153,
      'column': 5,
      'url': 'package:flutter_test/src/widget_tester.dart',
      'root_line': 22,
      'root_column': 5,
      'root_url': 'file:///my_app/test/counter/view/counter_page_test.dart'
    },
    'type': 'testStart',
    'time': 3113
  },
  {
    'testID': 21,
    'messageType': 'print',
    'message':
        '══╡ EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK ╞════════════════════════════════════════════════════\nThe following _Exception was thrown running a test:\nException: oops\n\nWhen the exception was thrown, this was the stack:\n#0      main.<anonymous closure>.<anonymous closure> (file:///my_app/test/app/view/app_test.dart:15:7)\n#1      main.<anonymous closure>.<anonymous closure> (file:///my_app/test/app/view/app_test.dart:14:40)\n#2      testWidgets.<anonymous closure>.<anonymous closure> (package:flutter_test/src/widget_tester.dart:170:29)\n<asynchronous suspension>\n<asynchronous suspension>\n(elided one frame from package:stack_trace)\n\nThe test description was:\n  renders CounterPage\n════════════════════════════════════════════════════════════════════════════════════════════════════',
    'type': 'print',
    'time': 3142
  },
  {
    'testID': 21,
    'error':
        'Test failed. See exception logs above.\nThe test description was: renders CounterPage',
    'stackTrace': '',
    'isFailure': false,
    'type': 'error',
    'time': 3147
  },
  {
    'testID': 21,
    'result': 'error',
    'skipped': false,
    'hidden': false,
    'type': 'testDone',
    'time': 3151
  },
  {
    'testID': 24,
    'messageType': 'print',
    'message': 'hello',
    'type': 'print',
    'time': 3341
  },
  {
    'testID': 24,
    'result': 'success',
    'skipped': false,
    'hidden': false,
    'type': 'testDone',
    'time': 4019
  },
  {
    'group': {
      'id': 25,
      'suiteID': 6,
      'parentID': 22,
      'name': 'CounterView',
      'metadata': {'skip': false, 'skipReason': null},
      'testCount': 3,
      'line': 29,
      'column': 3,
      'url': 'file:///my_app/test/counter/view/counter_page_test.dart'
    },
    'type': 'group',
    'time': 4019
  },
  {
    'test': {
      'id': 26,
      'name': 'CounterView renders current count',
      'suiteID': 6,
      'groupIDs': [22, 25],
      'metadata': {'skip': false, 'skipReason': null},
      'line': 153,
      'column': 5,
      'url': 'package:flutter_test/src/widget_tester.dart',
      'root_line': 36,
      'root_column': 5,
      'root_url': 'file:///my_app/test/counter/view/counter_page_test.dart'
    },
    'type': 'testStart',
    'time': 4020
  },
  {
    'testID': 26,
    'result': 'success',
    'skipped': false,
    'hidden': false,
    'type': 'testDone',
    'time': 4092
  },
  {
    'test': {
      'id': 27,
      'name': 'CounterView calls increment when increment button is tapped',
      'suiteID': 6,
      'groupIDs': [22, 25],
      'metadata': {'skip': false, 'skipReason': null},
      'line': 153,
      'column': 5,
      'url': 'package:flutter_test/src/widget_tester.dart',
      'root_line': 51,
      'root_column': 5,
      'root_url': 'file:///my_app/test/counter/view/counter_page_test.dart'
    },
    'type': 'testStart',
    'time': 4092
  },
  {
    'testID': 27,
    'result': 'success',
    'skipped': false,
    'hidden': false,
    'type': 'testDone',
    'time': 4212
  },
  {
    'test': {
      'id': 28,
      'name': 'CounterView calls decrement when decrement button is tapped',
      'suiteID': 6,
      'groupIDs': [22, 25],
      'metadata': {'skip': false, 'skipReason': null},
      'line': 153,
      'column': 5,
      'url': 'package:flutter_test/src/widget_tester.dart',
      'root_line': 65,
      'root_column': 5,
      'root_url': 'file:///my_app/test/counter/view/counter_page_test.dart'
    },
    'type': 'testStart',
    'time': 4213
  },
  {
    'testID': 28,
    'result': 'success',
    'skipped': false,
    'hidden': false,
    'type': 'testDone',
    'time': 4248
  },
  {'success': false, 'type': 'done', 'time': 4266},
];
