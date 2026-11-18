# Architecture Review

Branch `fix/create-workspace-root` against `main` (6e396658). Stack: a single Dart CLI package (`very_good_cli`), `args` command runner, Mason templates, `mocktail` tests, `very_good_analysis`. No companion-plugin or project-local skill covers a Dart CLI's layering, so the review applies the rules in `AGENTS.md`: few branches, injectable dependencies, no sibling dependencies within a layer.

How I checked: read every changed `lib/` file end to end with its callers (`command_runner.dart`, `mcp/tool_run.dart`, `mcp/structured_tool_error.dart`, `templates/*`), ran `dart analyze --fatal-infos --fatal-warnings` on the changed `lib/` files (clean; the four infos it prints sit in the untouched `lib/src/cli/test_run_recorder.dart`), decoded the template bundles to see which generated pubspecs carry `resolution: workspace`, and ran two scratch probes against `PubspecWorkspace` outside the repo. I ran no test file.

Layers, as the code draws them:

| Layer              | Path                                                | May depend on     |
| ------------------ | --------------------------------------------------- | ----------------- |
| Commands           | `lib/src/commands/**`, `lib/src/mcp/**`             | everything below  |
| Process wrappers   | `lib/src/cli/**`                                    | models            |
| Models and parsers | `lib/src/pubspec_workspace`, `lib/src/pubspec_lock` | `lib/src/pubspec` |
| Shared primitives  | `lib/src/pubspec`                                   | packages only     |

## Layer Separation

- Violations found: 0
- Imports added by the diff:
  - `lib/src/commands/create/commands/create_subcommand.dart:11` imports `pubspec_workspace` (command to model: downward).
  - `lib/src/pubspec_workspace/pubspec_workspace.dart:28` imports `package:yaml_edit` (model to package).
- `lib/src/pubspec_workspace` still imports neither `commands`, `mcp`, nor its sibling `pubspec_lock`; both parsers meet only in `lib/src/pubspec`.
- `lib/src/cli/cli.dart` imported `pubspec_workspace` on `main` already; the diff only renames the call at `lib/src/cli/dart_cli.dart:33`.
- `lib/src/mcp/mcp_server.dart` changes one description string.

Ownership is mostly right. Discovery (`PubspecWorkspace.enclosing`) and the YAML edit (`addMembers`) live in the model; user messages and exit codes live in the command; `licenses.dart:475-491` now owns its own fall-back-and-warn policy instead of the model logging on the command's behalf. Two pieces of workspace logic leaked upward into the command (findings 2 and 5).

## State Management Assessment

The project has no state-management library; the equivalent units are the command and the model.

### `CreateSubCommand.runCreate` (`create_subcommand.dart:237-284`): issues found

Ordering of side effects, traced:

1. `getTemplateVars()` (usage validation)
2. `PubspecWorkspace.enclosing(outputDirectory)` (read only), returns `ExitCode.config` on failure
3. `logger.progress('Bootstrapping')`
4. `hooks.preGen`
5. `generator.generate`
6. `_addToWorkspace` (writes the root pubspec)
7. `template.onGenerateComplete` (`pub get`, fixes)

Correct: validation precedes every write, it precedes the progress spinner (no dangling progress on the early return), and the root is edited before `pub get`. Remaining problems:

**Finding 1 (Important, high confidence in the facts): the workspace lookup is hard-wired.**
`create_subcommand.dart:245` calls the static factory directly. The command already injects its other collaborator through the constructor (`generatorFromBundle`, line 53), and `licenses.dart:35-40` keeps `resolveWorkspaceOverride` for the same purpose. `enclosing` walks every ancestor up to the filesystem root (`pubspec_workspace.dart:162`), so the command tests can only drive it through real directories: `create_subcommand_test.dart:1600` builds the fixture under `Directory.systemTemp`, and the tests at `:1924` and `:1956` pass only if no directory above the system temp dir holds a `pubspec.yaml` with a `workspace:` list (for `:1956`, any `pubspec.yaml` at all). `pubspec_workspace_test.dart:265` shares the assumption, which is acceptable for the unit that owns the walk; the command should not inherit it.
Fix: add a constructor parameter such as `PubspecWorkspace Function(Directory)? findWorkspace`, defaulting to `PubspecWorkspace.enclosing`, mirroring `generatorFromBundle`. Command tests then stub the lookup; the real walk stays covered in `pubspec_workspace_test.dart`.

**Finding 2 (Important, medium confidence in severity): the base command rediscovers what the generator already reported, using one template's layout.**
`_addToWorkspace` (`create_subcommand.dart:291-308`) lists the output directory and keeps the output itself or its immediate children that declare `resolution: workspace`. Its doc comment names the reason: "as the Flutter plugin template does". The generic base class now encodes the shape of one template, while `generator.generate` returns the exact generated paths at line 274 and the command uses them only for a count.
I decoded the bundles: today every template fits (single-package templates put `resolution: workspace` in the root pubspec; the plugin puts it in each first-level package; `widgetbook/` and `example/` omit it). So nothing is broken now. The cost is structural:

- templates live in another repository; a member generated two levels deep is skipped silently and the command still exits 0;
- when the output directory already existed, pre-existing first-level directories that declare `resolution: workspace` are registered although this run did not generate them;
- the function needs an `existsSync` guard (line 293), a ternary, and a sort to do what one filter over `files` does. The guard is reachable only when the generator writes nothing, which is the mocked-generator case.
  Fix: pass `files` to `_addToWorkspace` and take the parent directory of each generated `pubspec.yaml` that satisfies `PubspecWorkspace.declaresResolution`. That removes the guard and the single/multi branch, and works at any depth. If no generated package declares the resolution, warn instead of passing silently.

**Finding 3 (Important, high confidence in the facts; the triggers are uncommon): a failed edit after generation has no error path.**
The comment at `create_subcommand.dart:240-241` promises that a project unable to join a workspace "fails without leaving files behind". That holds for discovery only. `_addToWorkspace` runs after generation and `addMembers` can throw. Both cases below were reproduced with a scratch probe:

- Root `pubspec.yaml` read-only: `PathAccessException` from `readAsStringSync`/`writeAsStringSync` (`pubspec_workspace.dart:216,228`). `VeryGoodCommandRunner.run` catches only `FormatException` and `UsageException` (`command_runner.dart:69,76`), so the CLI dies with a stack trace. Through MCP, `mcp_server.dart:607` catches it and reports `permission`.
- `workspace:` written through a YAML alias (`workspace: *members`): `yaml_edit` throws `AliasException`, which extends `FormatException`. The runner's `on FormatException` handler prints the usage text and returns `ExitCode.usage` (64). `ToolRun.resultFor` (`tool_run.dart:66-74`) then tells an MCP client `validation` / `usage_error`: its arguments were wrong. They were not; the root pubspec could not be edited.
  In both cases the package is generated, the root is unchanged, and `pub get` never runs.
  Fix: catch `FileSystemException` and `FormatException` around the call at line 279, log the entry the user must add by hand, and return a non-usage exit code (`ExitCode.cantCreate` or `ExitCode.ioError`, both already mapped in `structured_tool_error.dart:70-76`). Alternatively let `addMembers` throw a dedicated `PubspecWorkspaceEditException` and map that.

Exit-code flow for the validated failures is sound: `ExitCode.config` (78) maps to `ToolFailureType.validation` / `invalid_input` (`structured_tool_error.dart:59-64`), and the `logger.err` text reaches the client as captured output. `config` matches the codebase's use for "found, but misconfigured" (`create_subcommand.dart:212`, `test_cli_runner.dart:370`).

**Finding 5 (Suggestion): the not-found message recomputes `entryFor`.**
`create_subcommand.dart:325-332` repeats the `path.posix.joinAll(path.split(path.relative(...)))` expression of `PubspecWorkspace.entryFor` (`pubspec_workspace.dart:179-185`) because no instance exists on the failure path. Two copies of the rule "how a member is spelled in `workspace:`" can drift.
Fix: extract a static `PubspecWorkspace.entry(Directory member, {required Directory root})`; have `entryFor` delegate to it and the message call it.

**Finding 8 (Suggestion): the `Workspace` mixin's doc is stale.**
`create_subcommand.dart:455-458` still says the mixin "takes care of parsing it from argResults and pass it to the brick generator". The flag now also gates discovery, a pubspec edit, and an exit code, all implemented in the base class behind `this case final Workspace command` (line 243). That matches the existing `if (this is X)` style, so I do not flag the placement; update the doc, or move the lookup into the mixin if `runCreate` gains more per-mixin steps.

### `PubspecWorkspace` (`pubspec_workspace.dart:98-299`): issues found

Compared with `PubspecLock` (`lib/src/pubspec_lock/pubspec_lock.dart`), which it cites as its model:

|              | `PubspecLock`                        | `PubspecWorkspace`                                               |
| ------------ | ------------------------------------ | ---------------------------------------------------------------- |
| Construction | `fromString(String)`, pure           | `fromDirectory` / `enclosing`, read the disk                     |
| Mutation     | none                                 | `addMembers` writes a file                                       |
| Exceptions   | one, for malformed input only        | two; `NotFound` also signals the ordinary "not a workspace" case |
| Statics      | `empty`                              | `declaresResolution`, `parsePackagePaths`                        |
| I/O owner    | the command (`_tryParsePubspecLock`) | the class                                                        |

Owning the I/O is defensible here: an ancestor walk and a comment-preserving edit need the filesystem. The shape issues are narrower.

**Finding 4 (Suggestion, verified): `addMembers` mutates the file behind an immutable snapshot.**
The class is `const`, and `addMembers` (`pubspec_workspace.dart:207-231`) documents that "this instance is a snapshot and is not updated". A second call on the same instance still consults the old `entries` and appends again; my probe produced `- packages/b` twice. The sole caller calls it once, so the defect is latent. The same staleness governs the `entries.isEmpty` branch at line 217, which chooses between replacing and appending from the snapshot while the editor reads the file fresh.
Fix: return the updated `PubspecWorkspace` (re-read, or `entries + added`) alongside the added entries, or decide `includes` from the `YamlEditor`'s parsed list so one read drives both the check and the edit.

**Finding 6 (Suggestion): `PubspecWorkspaceNotFoundException` carries three meanings and doubles as control flow.**
One type (`pubspec_workspace.dart:74-88`) means "no pubspec here" (`pubspecFile == null`), "pubspec without a workspace list" (`pubspecFile` set), and, from `enclosing`, "no ancestor is a root" (`directory` is the starting point, `pubspecFile` the closest non-root). The consumer must branch on the nullable field (`create_subcommand.dart:318`). It is also thrown for expected outcomes: once per ancestor inside `enclosing` (line 166), and on every `packages check licenses` run in a plain package (`licenses.dart:483`), where `main` returned `null`. `PubspecLockParseException` is reserved for malformed input.
Fix: add a nullable `PubspecWorkspace.tryFromDirectory` for the lookup and let `enclosing` and `licenses.dart` use it; keep a thrown exception for the parse failure and for the final "nothing encloses this directory". Splitting the two not-found states into separate types removes the null branch in `_workspaceNotFoundMessage`.

**Finding 7 (Suggestion): `parsePackagePaths` does not belong to the class.**
`pubspec_workspace.dart:292-298` parses the stdout of `dart pub workspace list --json`. It touches no instance state, its only caller is `Dart.workspacePackages` (`dart_cli.dart:33`), and it is the file's sole use of `dart:convert`. As a static it turns the class into a namespace and makes the process-wrapper layer name the model class to decode its own command's output. The import direction predates this branch; the refactor made the coupling a class dependency.
Fix: keep it a top-level function, or move it beside `Dart.workspacePackages` as a private helper with its tests.

**Also in finding 8 (Suggestion): the library doc contradicts itself.** `pubspec_workspace.dart:1` now opens "A small model of a Pub workspace", and lines 14-15 still close "It is not a general workspace model." Rewrite the header to describe the class: root, entries, membership edit, dependency resolver.

Design note, not a finding: `_workspaceFile` (`pubspec_workspace.dart:234-247`) re-derives which file declares `workspace:` with its own `loadYaml`, apart from `_tryParsePubspecWithOverrides` (`:311-346`). I tried to make the two disagree (malformed `workspace` or `dependency_overrides` in `pubspec_overrides.yaml`) and could not; lenient parsing kept them consistent. Recording the source file once, when the pubspec is parsed, would remove the second derivation.

### `licenses.dart`: correct

`_tryResolveWorkspaceDependencies` (`:475-491`) preserves the old behavior (missing pubspec or empty list returns `null`; unparseable root warns, then returns `null`) and moves the warning to the command, which owns the logger and the fallback policy. `licenses_test.dart` adds the unparseable-root case. Finding 6 would turn its `on PubspecWorkspaceNotFoundException` into a null check.

## Dependency Direction

- Direction violations: 0
- Clean dependencies:
  - `commands/create` -> `pubspec_workspace` -> `pubspec`
  - `commands/packages/check/licenses` -> `pubspec_workspace`, `pubspec_lock` -> `pubspec`
  - `cli` -> `pubspec_workspace` (pre-existing; see finding 7)
  - `mcp` -> `command_runner` -> `commands` (unchanged)
- No cycle: nothing under `lib/src/pubspec*` imports `commands`, `cli`, or `mcp`.
- No new sibling dependency: `pubspec_workspace` and `pubspec_lock` remain independent.

## Package Structure

- `very_good_cli` (`pubspec.yaml`): complete
  - `yaml_edit: ^2.2.4` sits in `dependencies` in alphabetical order with the caret style of its neighbors. A runtime dependency is correct: the published CLI edits pubspecs.
  - One file imports it (`pubspec_workspace.dart:28`), so the edit concern has a single owner.
  - It adds no new transitive package: its dependencies (`collection`, `meta`, `source_span`, `yaml`) are already resolved here. Maintained by the Dart team, BSD-3-Clause, SDK `^3.1.0`.
  - Justified over string surgery: `addMembers` must preserve comments and layout, and `pubspec_workspace_test.dart:369` asserts it.
  - `pubspec.lock` is git-ignored, so no lock change is expected.
  - Note for finding 3: `yaml_edit` reports failures as `FormatException` subtypes and `ArgumentError` subtypes (`PathError`), which this runner treats as usage errors or lets crash.
- Tests exist for the new unit (`test/src/pubspec_workspace/pubspec_workspace_test.dart`) and for the command paths (`create_subcommand_test.dart:1803-1998`).

## Verdict

Architecture is clean at the layer level: no cross-layer or circular imports, the new dependency is justified, and side effects run in the right order. Fix three Important items before merging: inject the workspace lookup (1), derive members from the generated files (2), and give the post-generation edit an error path (3). The five Suggestions tighten the `PubspecWorkspace` shape and remove a duplicated rule.
