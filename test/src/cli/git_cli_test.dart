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

    group('UnreachableGitDependency', () {
      test('has correct toString override', () {
        final remote =
            Uri.parse('https://github.com/verygoodopensource/_very_good_cli');
        final exception = UnreachableGitDependency(remote: remote);
        expect(
          exception.toString(),
          equals(
            '''
$remote is unreachable.
Make sure the remote exists and you have the correct access rights.''',
          ),
        );
      });
    });
  });
}
