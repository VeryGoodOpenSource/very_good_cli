/// Returns [a] + [b].
int add(int a, int b) {
  return a + b;
}

/// Applies [add] to every value of [values], never called by the tests.
int addAll(List<int> values) {
  return values.reduce(add);
}
