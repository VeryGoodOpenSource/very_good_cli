// ignore_for_file: prefer_const_constructors

import 'package:compilation_error/compilation_error.dart';
import 'package:test/test.dart';

void main() {
  test('can be instantiated', () {
    expect(Thing(thing: true), isNull);
  });
}
