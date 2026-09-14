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

Two active bugs shape this cycle. The MCP `test` tool has been classifying deterministic failures as transient, which pushes agents to retry work that will never pass. The test optimizer silently drops library-level annotations (`@Skip`, `@Tags`, `@Timeout`), so opt-outs and other metadata that authors rely on quietly stop taking effect once tests run through the optimized bundle. Both directly undermine trust in the tool.

- Fix `test_optimizer` dropping library-level annotations (`@Skip`, `@Tags`, `@Timeout`) · P1 [#1723](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1723)
- Fix MCP `test` tool classifying deterministic failures as transient · P1 [#1722](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1722)

---

## Next — Q3 2026: MCP experience & test optimizer polish

Round out the MCP server and give the test optimizer finer-grained control.

The MCP server shipped earlier this year and agent adoption keeps growing. This cycle closes the gaps that show up most often when driving the CLI from an agent: live progress signalling for long-running commands, and richer configuration for which files land in the optimized test bundle. In parallel, `test_optimizer` gains sharding so large CI pipelines can parallelize across runners.

- Stream MCP `notifications/progress` from long-running tools · P1 [#1616](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1616)
- Allow excluding files from optimized bundles via `very_good.yaml` · P2 [#1713](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1713)
- Support test sharding for CI parallelization with `test_optimizer` · P1 [#1538](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1538)

---

## Later — Q4 2026: Developer experience, monorepo & telemetry

Improve the day-to-day CLI experience and broaden monorepo support.

With MCP and testing stable, focus shifts to the CLI surface itself: better ergonomics for monorepo teams, telemetry that informs which Dart SDK versions we support, and the next round of test-runner improvements aimed at very large projects.

- Add Dart SDK version telemetry · P1 [#682](https://github.com/VeryGoodOpenSource/very_good_cli/issues/682)
- Add `--no-github` flag for monorepo use cases · P2 [#567](https://github.com/VeryGoodOpenSource/very_good_cli/issues/567)
- Enable optimization for platform tests · P2 [#1363](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1363)
- Improve the test runner on large apps and projects · P2 [#1695](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1695)

---

## Good first issues

Looking to contribute? These are well-scoped, clearly defined issues with enough context to get started without deep familiarity with the codebase:

- [#567 — Add `--no-github` flag for monorepo use cases](https://github.com/VeryGoodOpenSource/very_good_cli/issues/567)
- [#1363 — Enable optimization for platform tests](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1363)
- [#1723 — Fix `test_optimizer` dropping library-level annotations](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1723)

---

## Blocked

- [#947 — CI `test_optimizer` cache error with GitHub Actions + Melos](https://github.com/VeryGoodOpenSource/very_good_cli/issues/947) — blocked by [mason#1655](https://github.com/felangel/mason/issues/1655)

---

_Very Good CLI is maintained by [Very Good Ventures](https://verygood.ventures). Contributions welcome — see [CONTRIBUTING.md](CONTRIBUTING.md)._
