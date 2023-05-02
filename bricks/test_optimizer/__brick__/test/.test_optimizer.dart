// GENERATED CODE - DO NOT MODIFY BY HAND
// Consider adding this file to your .gitignore.

{{#isFlutter}}import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
{{/isFlutter}}{{^isFlutter}}import 'package:test/test.dart';{{/isFlutter}}

{{#tests}}import '{{{path}}}' as {{identifier}};
{{/tests}}
void main() {
{{#isFlutter}}  goldenFileComparator = _TestOptimizationAwareGoldenFileComparator();{{/isFlutter}}
{{#tests}}  group('{{{path}}}', () { {{identifier}}.main(); });
{{/tests}}}

{{#isFlutter}}
class _TestOptimizationAwareGoldenFileComparator extends LocalFileComparator {
  final List<String> goldenFilePaths;

  _TestOptimizationAwareGoldenFileComparator()
      : goldenFilePaths = _goldenFilePaths,
        super(_testFile);

  static Uri get _testFile {
    final basedir =
        (goldenFileComparator as LocalFileComparator).basedir.toString();
    return Uri.parse("$basedir/.test_optimizer.dart");
  }

  static List<String> get _goldenFilePaths =>
      Directory.fromUri((goldenFileComparator as LocalFileComparator).basedir)
          .listSync(recursive: true, followLinks: true)
          .whereType<File>()
          .map((file) => file.path)
          .where((path) => path.endsWith('.png'))
          .toList();

  @override
  Uri getTestUri(Uri key, int? version) {
    final keyString = key.toFilePath();
    return Uri.parse(goldenFilePaths
        .singleWhere((goldenFilePath) => goldenFilePath.endsWith(keyString)));
  }
}
{{/isFlutter}}