import 'package:flutter/widgets.dart';
import 'package:bloc/bloc.dart';
import 'package:very_good_core/app/app.dart';
import 'package:very_good_core/app/app_bloc_observer.dart';

void main() {
  Bloc.observer = AppBlocObserver();
  runApp(const App());
}
