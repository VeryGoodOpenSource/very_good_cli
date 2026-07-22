@Tags(['pull-request-only'])
// Building the code generators with AOT compilation can take longer than the
// default 30 second test timeout on CI, so allow additional time.
@Timeout(Duration(minutes: 5))
library;

import 'package:build_verify/build_verify.dart';
import 'package:test/test.dart';

void main() {
  test('ensure_build', expectBuildClean);
}
