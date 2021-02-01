import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:very_good_core/counter/counter.dart';

void main() {
  group('CounterBloc', () {
    test('initial state is 0', () {
      expect(CounterBloc().state, equals(0));
    });

    blocTest<CounterBloc, int>(
      'emits [1] when CounterEvent.increment is added',
      build: () => CounterBloc(),
      act: (bloc) => bloc.add(CounterEvent.increment),
      expect: () => [equals(1)],
    );

    blocTest<CounterBloc, int>(
      'emits [-1] when CounterEvent.decrement is added',
      build: () => CounterBloc(),
      act: (bloc) => bloc.add(CounterEvent.decrement),
      expect: () => [equals(-1)],
    );
  });
}
