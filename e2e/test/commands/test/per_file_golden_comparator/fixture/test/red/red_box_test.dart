import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('resolves goldens next to this file', () {
    final comparator = goldenFileComparator;
    expect(comparator, isA<LocalFileComparator>());
    expect(
      (comparator as LocalFileComparator).basedir.path,
      endsWith('/test/red/'),
    );
  });

  testWidgets('renders a red box', (tester) async {
    await tester.pumpWidget(
      const Center(
        child: ColoredBox(
          color: Color(0xFFFF0000),
          child: SizedBox.square(dimension: 20),
        ),
      ),
    );

    await expectLater(find.byType(ColoredBox), matchesGoldenFile('box.png'));
  });
}
