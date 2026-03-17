## ADDED Requirements

### Requirement: Broken thank-you URL is removed from command runner
The CLI SHALL NOT display any message containing the dead URL `https://verygood.ventures/dev/tools/cli/subscribe`. The `_showThankYou()` method, its call site in `runCommand()`, and the `_configDir` getter (used exclusively by `_showThankYou`) SHALL be deleted from `lib/src/command_runner.dart`. The `_isWindows` getter and `isWindowsOverride` field SHALL also be deleted as they are only used by `_configDir`.

#### Scenario: Running any CLI command does not show the broken URL
- **WHEN** a user runs any `very_good` command (e.g., `very_good --version`)
- **THEN** the output SHALL NOT contain `https://verygood.ventures/dev/tools/cli/subscribe`
- **THEN** the output SHALL NOT contain the thank-you subscription message

#### Scenario: Dead code is absent from the codebase
- **WHEN** `lib/src/command_runner.dart` is inspected
- **THEN** it SHALL NOT contain `_showThankYou`, `_configDir`, `_isWindows`, or `isWindowsOverride`

### Requirement: Test suite reflects removal of dead code
The `_showThankYou` test group in `test/src/command_runner_test.dart` SHALL be removed. Any mock classes or test helpers used exclusively by that group SHALL also be removed.

#### Scenario: Test file does not contain removed test group
- **WHEN** `test/src/command_runner_test.dart` is inspected
- **THEN** it SHALL NOT contain a `group('_showThankYou', ...)` block

#### Scenario: Test suite passes with 100% coverage after removal
- **WHEN** `flutter test` is run
- **THEN** all tests SHALL pass
- **THEN** code coverage SHALL remain at 100% for `lib/src/command_runner.dart`

### Requirement: Automated link checking workflow exists
The repository SHALL have a GitHub Actions workflow at `.github/workflows/check_links.yaml` that uses [lychee-action](https://github.com/lycheeverse/lychee-action) to detect broken URLs in markdown and Dart source files.

#### Scenario: Workflow runs on pull request to main
- **WHEN** a pull request targeting the `main` branch is opened or updated
- **THEN** the link-checking workflow SHALL run and report any broken links

#### Scenario: Workflow runs on push to main
- **WHEN** a commit is pushed to the `main` branch
- **THEN** the link-checking workflow SHALL run and report any broken links

#### Scenario: Workflow runs on weekly schedule
- **WHEN** the weekly cron schedule triggers (e.g., every Monday)
- **THEN** the link-checking workflow SHALL run to detect link rot in existing content

#### Scenario: Workflow checks markdown and Dart source files
- **WHEN** the link-checking workflow runs
- **THEN** it SHALL scan all `**/*.md` files in the repository
- **THEN** it SHALL scan all `**/*.dart` files in the repository

#### Scenario: Workflow produces a summary report
- **WHEN** the link-checking workflow completes
- **THEN** it SHALL output a summary of checked links and any failures to the GitHub Actions job summary
