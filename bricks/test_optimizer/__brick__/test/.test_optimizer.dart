// GENERATED CODE - DO NOT MODIFY BY HAND
// Consider adding this file to your .gitignore.

{{#isFlutter}}import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
{{/isFlutter}}{{^isFlutter}}import 'package:test/test.dart';{{/isFlutter}}

{{#tests}}import '{{{path}}}' as {{identifier}};
{{/tests}}
void main() {
{{#isFlutter}}  goldenFileComparator = _TestOptimizationAwareGoldenFileComparator(goldenFileComparator as LocalFileComparator);{{/isFlutter}}
{{#tests}}  group('{{{path}}}', () { {{identifier}}.main(); });
{{/tests}}}

{{#isFlutter}}
class _TestOptimizationAwareGoldenFileComparator extends GoldenFileComparator {
  final List<String> goldenFilePaths;
  final LocalFileComparator previousGoldenFileComparator;

  _TestOptimizationAwareGoldenFileComparator(this.previousGoldenFileComparator)
      : goldenFilePaths = _goldenFilePaths;

  static List<String> get _goldenFilePaths =>
      Directory.fromUri((goldenFileComparator as LocalFileComparator).basedir)
          .listSync(recursive: true, followLinks: true)
          .whereType<File>()
          .map((file) => file.path)
          .where((path) => path.endsWith('.png'))
          .toList();
  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden)  => previousGoldenFileComparator.compare(imageBytes, golden);

  @override
  Uri getTestUri(Uri key, int? version) {
    final keyString = key.toFilePath();
    return Uri.parse(goldenFilePaths
        .singleWhere((goldenFilePath) => goldenFilePath.endsWith(keyString)));
  }

  @override
  Future<void> update(Uri golden, Uint8List imageBytes) => previousGoldenFileComparator.update(golden, imageBytes);

}
{{/isFlutter}}