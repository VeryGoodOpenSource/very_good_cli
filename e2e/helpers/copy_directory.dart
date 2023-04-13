import 'dart:io';

import 'package:path/path.dart' as path;

Future<void> copyDirectory(Directory from, Directory to) async {
  await to.create(recursive: true);
  await for (final entity in from.list(recursive: true)) {
    final toPath = path.join(
      to.path,
      path.relative(entity.path, from: from.path),
    );
    if (entity is Directory) {
      await Directory(toPath).create();
    } else if (entity is File) {
      await entity.copy(toPath);
    }
  }
}
