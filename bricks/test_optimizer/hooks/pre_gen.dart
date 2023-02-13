import 'package:mason/mason.dart';

import 'lib/pre_gen.dart' as pre_gen;

Future<void> run(HookContext context) async {
  await pre_gen.run(context);
}
