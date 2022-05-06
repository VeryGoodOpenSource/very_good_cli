import 'package:test/test.dart';
import 'package:very_good_cli/src/cli/cli.dart';

void main() {
  group('Git', () {
    group('reachable', () {
      test('completes for a reachable remote', () async {
        await expectLater(
          Git.reachable(
            Uri.parse('https://github.com/verygoodopensource/very_good_cli'),
          ),
          completes,
        );
      });

      test('throws UnreachableGitDependency for an unreachable remote',
          () async {
        await expectLater(
          Git.reachable(
            Uri.parse('https://github.com/verygoodopensource/_very_good_cli'),
          ),
          throwsA(isA<UnreachableGitDependency>()),
        );
      });
    });
  });
}
