## Why

The `_showThankYou()` method in `VeryGoodCommandRunner` displays a subscription link (`https://verygood.ventures/dev/tools/cli/subscribe`) that no longer exists, resulting in a broken URL shown to users on install or upgrade. Additionally, the repository has no automated mechanism to detect broken links, allowing similar issues to go unnoticed in the future.

## What Changes

- Remove the `_showThankYou()` method from `lib/src/command_runner.dart` (lines ~149–167)
- Remove the `_configDir` getter from `lib/src/command_runner.dart` (lines ~169–183), which is only used by `_showThankYou()`
- Remove the `_showThankYou()` call from `runCommand()` in `lib/src/command_runner.dart` (line ~130)
- Remove the `_showThankYou` test group from `test/src/command_runner_test.dart` (lines ~184–323)
- Add `.github/workflows/check_links.yaml` — a CI workflow using [lychee-action](https://github.com/lycheeverse/lychee-action) to automatically detect broken links in markdown and source files on push, pull request, and a weekly schedule

## Capabilities

### New Capabilities

- `link-checking-workflow`: A GitHub Actions workflow that scans the repository for broken URLs in markdown and source files, running on push, pull request, and weekly schedule using lychee-action

### Modified Capabilities

<!-- No existing spec-level requirements are changing -->

## Impact

- **`lib/src/command_runner.dart`**: ~35 lines removed (`_showThankYou`, `_configDir`, and the call site)
- **`test/src/command_runner_test.dart`**: ~140 lines removed (the `_showThankYou` test group and associated mock setup)
- **`.github/workflows/check_links.yaml`**: New file added
- No public API changes; no breaking changes for CLI users
- Reduces test surface area and removes dead code
