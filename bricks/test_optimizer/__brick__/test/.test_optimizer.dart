// GENERATED CODE - DO NOT MODIFY BY HAND
// Consider adding this file to your .gitignore.

{{#isFlutter}}import 'package:flutter_test/flutter_test.dart' hide group;
import 'package:test_api/scaffolding.dart' show group;
{{/isFlutter}}{{^isFlutter}}import 'package:test/test.dart';{{/isFlutter}}

{{#tests}}import '{{{path}}}' as {{identifier}};
{{/tests}}
void main() {
{{#isFlutter}}  final rootGoldenFileComparator = goldenFileComparator;
{{/isFlutter}}{{#tests}}  group('{{{path}}}', () {
{{#isFlutter}}    late final GoldenFileComparator fileGoldenFileComparator;
    setUpAll(() => goldenFileComparator = fileGoldenFileComparator);
    goldenFileComparator = _goldenFileComparatorFor(rootGoldenFileComparator, '{{{path}}}');
{{/isFlutter}}    {{identifier}}.main();
{{#isFlutter}}    fileGoldenFileComparator = goldenFileComparator;
{{/isFlutter}}  }{{{groupArguments}}});
{{/tests}}}
{{#isFlutter}}
/// The comparator `flutter test` would give the test file at [path] if it ran
/// on its own: a [LocalFileComparator] that resolves goldens next to that
/// file. Any other comparator, such as one set in `flutter_test_config.dart`,
/// is kept as it is.
GoldenFileComparator _goldenFileComparatorFor(
  GoldenFileComparator root,
  String path,
) =>
    root is LocalFileComparator
        ? LocalFileComparator(root.basedir.resolveUri(Uri(path: path)))
        : root;
{{/isFlutter}}