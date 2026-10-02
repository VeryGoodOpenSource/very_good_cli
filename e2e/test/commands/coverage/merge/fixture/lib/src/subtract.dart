/// Returns [a] - [b].
int subtract(int a, int b) {
  return a - b;
}

/// Applies [subtract] to every value of [values], never called by the tests.
int subtractAll(List<int> values) {
  return values.reduce(subtract);
}
