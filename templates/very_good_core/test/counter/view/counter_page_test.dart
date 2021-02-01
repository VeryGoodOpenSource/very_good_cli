import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:very_good_core/counter/counter.dart';

import '../../helpers/helpers.dart';

class MockCounterBloc extends MockBloc<CounterEvent, int>
    implements CounterBloc {}

void main() {
  group('CounterPage', () {
    testWidgets('renders CounterView', (tester) async {
      await tester.pumpApp(CounterPage());
      expect(find.byType(CounterView), findsOneWidget);
    });
  });

  group('CounterView', () {
    const incrementButtonKey = Key(
      'counterView_increment_floatingActionButton',
    );
    const decrementButtonKey = Key(
      'counterView_decrement_floatingActionButton',
    );

    late CounterBloc counterBloc;

    setUp(() {
      counterBloc = MockCounterBloc();
    });

    testWidgets('renders current count', (tester) async {
      const state = 42;
      when(counterBloc).calls(#state).thenReturn(state);
      await tester.pumpApp(
        BlocProvider.value(
          value: counterBloc,
          child: CounterView(),
        ),
      );
      expect(find.text('$state'), findsOneWidget);
    });

    testWidgets('calls add(CounterEvent.increment) when increment is tapped',
        (tester) async {
      when(counterBloc).calls(#state).thenReturn(0);
      when(counterBloc).calls(#add).thenReturn();
      await tester.pumpApp(
        BlocProvider.value(
          value: counterBloc,
          child: CounterView(),
        ),
      );
      await tester.tap(find.byKey(incrementButtonKey));
      verify(counterBloc).called(#add).withArgs(
        positional: [CounterEvent.increment],
      ).once();
    });

    testWidgets('calls add(CounterEvent.decrement) when decrement is tapped',
        (tester) async {
      when(counterBloc).calls(#state).thenReturn(0);
      when(counterBloc).calls(#add).thenReturn();
      await tester.pumpApp(
        BlocProvider.value(
          value: counterBloc,
          child: CounterView(),
        ),
      );
      await tester.tap(find.byKey(decrementButtonKey));
      verify(counterBloc).called(#add).withArgs(
        positional: [CounterEvent.decrement],
      ).once();
    });
  });
}
