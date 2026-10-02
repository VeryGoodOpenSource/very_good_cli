/// Returns [a] * [b].
int multiply(int a, int b) {
  return a * b;
}

/// Applies [multiply] to every value of [values], never called by the tests.
int multiplyAll(List<int> values) {
  return values.reduce(multiply);
}
