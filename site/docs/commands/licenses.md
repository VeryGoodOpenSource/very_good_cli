---
sidebar_position: 3
---

# License checking 💳🕵️‍♂️

Very Good CLI offers a fast, simple and efficient license checker for dependencies hosted by [Dart's package manager][pub]. Allowing developers to easily keep track of the rights and restrictions external dependencies might pose on their projects.

## Quick Start 🚀

To get started, install [Very Good CLI](https://cli.vgv.dev/docs/overview#quick-start-) and run the following command within your Dart or Flutter project:

```sh
very_good packages check licenses
```

:::info
The license checker requires an internet connection to fetch the data from [Dart's package manager][pub].
:::

## Options ⚙️

### `allowed`

Only allows the use of certain licenses. The command will exit with an error and log the list of all the dependencies that have an unlisted license.

#### Example usage:

```sh
very_good packages check licenses --allowed=MIT,BSD-3-Clause

# ✓ Retrieved 6 licenses from 6 packages of type: BSD-3-Clause (3), MIT (1), unknown (1) and Apache-2.0 (1).
# 2 dependencies have banned licenses: html (unknown) and universal_io (Apache-2.0).
```

:::info
A comprehensive list of all the licenses allowed as options is available within the [_Supported licenses_](#supported-licenses-💳) section of this document.
:::

### `forbidden`

Deny the use of certain licenses. The command will exit with an error and log the list of all the dependencies that have a blocked license.

#### Example usage:

```sh
very_good packages check licenses --forbidden=unknown,Apache-2.0

# ✓ Retrieved 6 licenses from 6 packages of type: BSD-3-Clause (3), MIT (1), unknown (1) and Apache-2.0 (1).
# 2 dependencies have banned licenses: html (unknown) and universal_io (Apache-2.0).
```

:::warning
The `allowed` and `forbidden` options can't be used specified together.
:::

### `dependency-type`

The type of dependencies to check licenses for. There are three available types:

- [`direct-dev`](https://dart.dev/tools/pub/dependencies#dev-dependencies): Another package that your package needs during development.
- [`direct-main`](https://dart.dev/tools/pub/dependencies): Another package that your package needs to work.
- [`transitive`](https://dart.dev/tools/pub/glossary#transitive-dependency): A dependency that your package indirectly uses because one of its dependencies requires it.

When unspecified, it defaults to `direct-main`.

#### Example usage:

```sh
very_good packages check licenses --dependency-type=direct-main,transitive

# ✓ Retrieved 83 licenses from 82 packages of type: BSD-3-Clause (65), MIT (15), unknown (1), BSD-2-Clause (1) and Apache-2.0 (1).
```

:::info
The license checker only requires a [lockfile](https://dart.dev/tools/pub/glossary#lockfile) to gather dependencies. The lockfile is generated automatically for you by [pub][pub] when you run `pub get`, `pub upgrade`, or `pub downgrade`.
:::

### `skip-packages`

Skips packages from having there licenses checked.

#### Example usage:

```sh
very_good packages check licenses --skip-packages=html,universal_io

# ✓ Retrieved 83 licenses from 82 packages of type: BSD-3-Clause (65), MIT (15), unknown (1), BSD-2-Clause (1) and Apache-2.0 (1).
```

### `[no]-offline`

### `ignore-retrieval-failures`

## Supported licenses 💳


