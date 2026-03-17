## Context

`VeryGoodCommandRunner.runCommand()` calls `_showThankYou()` after every command execution. This method writes a version file to the user's config directory and, when the version changes, prints a thank-you message containing a subscription URL (`https://verygood.ventures/dev/tools/cli/subscribe`). That URL is dead — it returns a 404 — making the feature actively harmful to the user experience.

The `_configDir` getter is a platform-aware helper that resolves the config directory path (XDG on Linux/macOS, `LOCALAPPDATA` on Windows). It is only used by `_showThankYou()`.

The repository currently has no automated link-checking, so broken URLs can persist undetected.

## Goals / Non-Goals

**Goals:**
- Remove `_showThankYou()`, `_configDir`, and the call site from `lib/src/command_runner.dart`
- Remove the corresponding `_showThankYou` test group from `test/src/command_runner_test.dart`
- Add a GitHub Actions workflow (`.github/workflows/check_links.yaml`) using [lychee-action](https://github.com/lycheeverse/lychee-action) to detect broken links in markdown and source files
- Keep `dart analyze` clean and maintain 100% test coverage after the removal

**Non-Goals:**
- Replacing the thank-you message with a different mechanism
- Checking links in generated template files (bricks)
- Fixing any other broken links discovered by the new workflow (tracked separately)

## Decisions

### Decision 1: Delete `_showThankYou` and `_configDir` entirely

**Rationale:** The feature is broken and has no replacement. Keeping dead code increases maintenance burden and confuses contributors. The `_configDir` getter has no other callers, so it must also be removed to keep the codebase clean.

**Alternative considered:** Replace the broken URL with a valid one. Rejected because there is no equivalent page to link to, and the subscription mechanism no longer exists.

### Decision 2: Use lychee-action for link checking

**Rationale:** lychee-action is the de-facto standard for link checking in GitHub Actions. It supports markdown and source files, handles rate limiting, allows ignore patterns, and produces a summary report. It is already used by many open-source Dart/Flutter projects.

**Alternative considered:** `markdown-link-check` action. Rejected because it only handles markdown files, not source code comments or YAML files.

### Decision 3: Workflow triggers — push to main, pull_request, and weekly schedule

**Rationale:** Running on push/PR catches regressions immediately. The weekly schedule catches external link rot (pages that go down after a PR merges). This matches the pattern used by other VGV workflows.

### Decision 4: Scope lychee to `**/*.md` and `**/*.dart` files

**Rationale:** Markdown files contain the most user-facing links. Dart source files contain URLs in comments and string literals (like the broken one being removed). YAML workflow files are excluded from the initial scope to avoid false positives from GitHub Actions expression syntax (`${{ }}`) being misinterpreted as URLs.

## Risks / Trade-offs

- **[Risk] False positives in link checker** → Mitigation: Configure lychee with an `.lycheeignore` file or inline `--exclude` patterns for known-good URLs that may be rate-limited (e.g., `crates.io`, `shields.io`). The workflow can be set to not fail the build on the first run while the ignore list is tuned.
- **[Risk] Removing `_showThankYou` tests reduces overall test count** → Mitigation: The removal is intentional dead-code cleanup; coverage percentage is maintained because the production code is also removed.
- **[Risk] `_isWindows` and `isWindowsOverride` become unused after removal** → Mitigation: Check whether any other code uses `_isWindows`/`isWindowsOverride` before removing; if not, remove them too to keep the class clean.
