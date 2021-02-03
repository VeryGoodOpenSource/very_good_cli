import 'package:flutter/widgets.dart';
import 'package:bloc/bloc.dart';
import 'package:{{project_name}}/app/app.dart';
import 'package:{{project_name}}/app/app_bloc_observer.dart';

void main() {
  Bloc.observer = AppBlocObserver();
  runApp(const App());
}
