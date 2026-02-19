# Very Good Ventures

At its core, VGV prefers code that embodies clear, concise mental models. We prefer to think deeply about the problem we are solving and find the solution that best fits.

- Example 1: a file with many boolean variables might be implemented more cleanly as a state machine (using a bloc, cubit, or other package/pattern).
- Example 2: a file with a series of complex async operations may be better described as a series of stream transforms, an observable primitive, or even a composite.

If you recognize a key insight that would clean something up but do not have what you need on hand to implement it, please just say so. Adding a package reference is easy.

Our criteria for good code also enables us to achieve 100% test coverage.

Good code has...

- As few branches as possible
- Injectable dependencies
- Well-named identifiers
- No sibling dependencies in the same architectural layer

To avoid sibling dependencies, state must either be lifted up to a common ancestor and passed down, or pushed down and subscribed to.

See @CONTRIBUTING.md for development details.

## Project Overview

Very Good CLI is a Dart command-line tool by Very Good Ventures for generating scalable project templates and running developer commands. It is published on pub.dev as `very_good_cli`.

## Common Commands

```bash
# Install dependencies
dart pub get && cd bricks/test_optimizer && dart pub get && cd ../../

# Run unit tests (excludes expensive pull-request-only and e2e tests)
flutter test -x pull-request-only -x e2e

# Run a single test file
flutter test test/src/commands/create/create_test.dart

# Format code
dart format lib test

# Analyze code (strict: warnings and infos are fatal)
dart analyze --fatal-infos --fatal-warnings .

# Auto-fix lint issues
dart fix --apply

# Activate local dev version
dart pub global activate --source path .
```

## Architecture

### Command Runner Pattern

Entry point: `bin/very_good.dart` → `VeryGoodCommandRunner` (extends `CompletionCommandRunner<int>`).

All commands return `Future<int>` (exit codes from `universal_io`'s `ExitCode`). Top-level commands: `create`, `test`, `packages`, `dart`, `update`, `mcp`.

### Create Command System

`CreateCommand` has subcommands for each template type (flutter_app, dart_package, dart_cli, docs_site, flame_game, flutter_package, flutter_plugin).

All subcommands extend `CreateSubCommand` and use mixins for optional features:
- `OrgName` — adds `--org-name` flag
- `MultiTemplates` — supports `--template` flag with multiple template choices
- `Publishable` — adds `--publishable` flag

Templates use Mason for code generation. Each template has a bundle, a `Template` class, and an `onGenerateComplete` hook. Template source code lives in separate repos under `VeryGoodOpenSource/very_good_templates`.

### CLI Abstraction Layer (`lib/src/cli/`)

- `DartCli`, `FlutterCli`, `GitCli` — wrappers around shell commands
- `ProcessOverrides` — zone-based dependency injection for mocking `Process.run` in tests
- `TestCliRunner` — test execution logic with coverage collection

### Testing Patterns

- **100% test coverage required** for all PRs
- Mocking with `mocktail`
- Constructor injection for dependencies (`Logger`, `PubUpdater`, generators)
- `@visibleForTesting` used for test-only overrides (e.g., `argResultOverrides`)
- Test tags in `dart_test.yaml`: `pull-request-only` for expensive CI-only tests
- E2E tests in `e2e/` create real projects and run full workflows
- Test optimizer brick in `bricks/test_optimizer/` generates optimized test entry points

## Code Conventions

- Linting: `very_good_analysis` (strict Dart analysis rules)
- Dartdoc templates: `/// {@template name}...{@endtemplate}` / `/// {@macro name}`
- Commits follow [Conventional Commits](https://www.conventionalcommits.org/) (used by release-please for automated versioning)
- `lib/src/version.dart` is auto-generated — do not edit manually
