# Very Good CLI — 2026 Roadmap

This document tracks where Very Good CLI is headed. It is intentionally high-level — focused on themes and milestones rather than exhaustive issue lists. Specific work lives in the [GitHub issue tracker](https://github.com/VeryGoodOpenSource/very_good_cli/issues).

> This is a directional roadmap, not a commitment. Priorities shift as we learn from the community and from our own use of the tool in client projects. If something here matters to you, open an issue or react to an existing one.

---

## How to read this roadmap

Each item carries a priority label that reflects both urgency and expected impact:

| Label     | Meaning                                                                |
| --------- | ---------------------------------------------------------------------- |
| **P0**    | Critical. Blocking users. Fix as soon as possible.                     |
| **P1**    | High priority. Significant user impact. Target the next release cycle. |
| **P2**    | Medium priority. Valuable improvement. Target upcoming quarters.       |
| **P3**    | Low priority. Backlog and nice-to-have.                                |
| **Close** | Not planned. Support questions, duplicates, or already resolved.       |

---

## Now — Stability & critical fixes

Fix what's broken and unblock users.

The first priority is always a working tool. Before investing in new capabilities, we make sure existing behavior matches what's documented. This release cycle focuses on CI integration correctness.

- Fix `flutter_plugin` CI template to respect `--platforms` · P1

---

## Next — Q2 2026: Testing, coverage & compliance

Make `very_good test` best-in-class and strengthen compliance tooling.

`very_good test` is one of the most-used commands in the CLI. We've seen teams hit coverage reporting limitations as they scale to multi-package monorepos, and the lack of workspace-aware license checking creates real friction for teams with compliance requirements. This cycle addresses both.

- Support `packages check licenses` with workspaces · P1 · [#1273](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1273)
- Single coverage report for multi-package apps · P2
- Support test sharding for CI parallelization with `test_optimizer` · P2
- Enable optimization for platform tests · P3
- Add `--no-github` flag for monorepo use cases · P3

---

## Later — Q3 2026: CLI & developer experience

Developer experience polish.

With the foundation stable, we shift focus to the quality-of-life improvements that make the CLI feel like a first-class tool. YAML-based configuration, better failure recovery, and new commands that fill gaps we hear about consistently in the community.

- Add Dart SDK version telemetry · P1
- Add `--continue-on-failure` to `packages get -r` · P2 · [#737](https://github.com/VeryGoodOpenSource/very_good_cli/issues/737)
- YAML config file for CLI parameters · P2
- `very_good changelog` command · P3
- Mason brick for `dart_cli` commands · P3

---

## Ongoing — Documentation

Reduce support burden and improve onboarding.

Good documentation is the multiplier on everything else. We're investing in versioned docs and closing the gaps that surface repeatedly in community questions — the kind of thing that shouldn't require opening an issue to figure out.

- Document app icon update process · P2 · [#768](https://github.com/VeryGoodOpenSource/very_good_cli/issues/768)
- Add versioned documentation to docs site · P2

---

## Ongoing — Infrastructure

Keep the project healthy and standards-compliant.

Tooling that keeps the codebase maintainable and the contributor experience smooth. These improvements don't ship user-facing features, but they make everything else easier to build and review.

- Add Claude Code GitHub workflows · P1
- XDG Base Directory compliance · P3 · [#706](https://github.com/VeryGoodOpenSource/very_good_cli/issues/706)
- Pass `--get-url` in git reachable check · P3

---

## Good first issues

Looking to contribute? These are well-scoped, clearly defined issues with enough context to get started without deep familiarity with the codebase:

- [#1273 — Support `packages check licenses` with workspaces](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1273)
- [#737 — Add `--continue-on-failure` to `packages get -r`](https://github.com/VeryGoodOpenSource/very_good_cli/issues/737)
- [#706 — XDG Base Directory compliance (don't clutter `$HOME`)](https://github.com/VeryGoodOpenSource/very_good_cli/issues/706)
- [#768 — Document app icon update process](https://github.com/VeryGoodOpenSource/very_good_cli/issues/768)

---

## Blocked

- [#947 — CI `test_optimizer` cache error with GitHub Actions + Melos](https://github.com/VeryGoodOpenSource/very_good_cli/issues/947) — blocked by [mason#1655](https://github.com/felangel/mason/issues/1655)

---

_Very Good CLI is maintained by [Very Good Ventures](https://verygood.ventures). Contributions welcome — see [CONTRIBUTING.md](CONTRIBUTING.md)._
