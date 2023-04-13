@Tags(['e2e'])
library spaced_golden_file_name_test;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders SizedBox', (tester) async {
    final widget = SizedBox.shrink();
    await tester.pumpWidget(widget);

    await expectLater(
      find.byWidget(widget),
      matchesGoldenFile('sized box.png'),
    );
  });
}
