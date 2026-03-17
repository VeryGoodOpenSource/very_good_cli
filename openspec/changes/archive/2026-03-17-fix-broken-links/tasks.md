## 1. Remove Dead Code from Command Runner

- [x] 1.1 Delete the `_showThankYou()` method (lines ~149–167) from `lib/src/command_runner.dart`
- [x] 1.2 Delete the `_configDir` getter (lines ~169–183) from `lib/src/command_runner.dart`
- [x] 1.3 Delete the `_isWindows` getter and `isWindowsOverride` field (lines ~56–58) from `lib/src/command_runner.dart`
- [x] 1.4 Remove the `_showThankYou()` call (line ~130) from `runCommand()` in `lib/src/command_runner.dart`
- [x] 1.5 Remove unused imports introduced by the deleted code (e.g., `package:path/path.dart` if no longer needed)

## 2. Clean Up Tests

- [x] 2.1 Delete the `_showThankYou` test group (lines ~184–323) from `test/src/command_runner_test.dart`
- [x] 2.2 Remove mock classes used exclusively by the deleted test group (`_MockDirectory`, `_MockFile`, `_MockStdout` if unused elsewhere)
- [x] 2.3 Run `flutter test test/src/command_runner_test.dart` and confirm all remaining tests pass

## 3. Verify Analysis and Coverage

- [x] 3.1 Run `dart analyze --fatal-infos --fatal-warnings .` and confirm zero issues
- [x] 3.2 Run `flutter test -x pull-request-only -x e2e --coverage` and confirm 100% coverage for `lib/src/command_runner.dart`

## 4. Add Link-Checking CI Workflow

- [x] 4.1 Create `.github/workflows/check_links.yaml` with lychee-action, triggered on `push` to `main`, `pull_request` to `main`, and a weekly `schedule` (cron)
- [x] 4.2 Configure lychee to scan `**/*.md` and `**/*.dart` files
- [x] 4.3 Add a `.lycheeignore` file (or inline exclude patterns) for known URLs that may produce false positives (e.g., localhost, example.com, shields.io badge URLs)
- [x] 4.4 Verify the workflow YAML is valid by running `actionlint` or opening a draft PR to trigger the workflow
