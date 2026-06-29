import 'package:test/test.dart';
import 'package:very_good_cli/src/workspace/workspace.dart';

void main() {
  group('WorkspaceContext', () {
    test('supports value equality', () {
      const a = WorkspaceContext(rootPath: '/ws', members: ['packages/a']);
      const b = WorkspaceContext(rootPath: '/ws', members: ['packages/a']);
      const c = WorkspaceContext(rootPath: '/other', members: ['packages/a']);

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('exposes rootPath and members', () {
      const context = WorkspaceContext(
        rootPath: '/ws',
        members: ['apps/app', 'packages/pkg'],
      );

      expect(context.rootPath, equals('/ws'));
      expect(context.members, equals(['apps/app', 'packages/pkg']));
    });
  });
}
