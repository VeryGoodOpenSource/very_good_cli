---
sidebar_position: 3
---

# Check licenses 👨‍⚖️

Very Good CLI offers a simple and straightforward license checker for dependencies hosted by [Dart's package manager][pub]. Allowing developers to easily keep track of the rights and restrictions external dependencies might impose on their projects.

## Quick Start 🚀

To get started, install [Very Good CLI](https://cli.vgv.dev/docs/overview#quick-start-) and run the following command within your Dart or Flutter project:

```sh
very_good packages check licenses
```

:::info
We do not collect any information about your project or dependencies. The license checker doesn't require an internet connection, it detects licenses locally using [Dart's package analyzer](https://pub.dev/packages/pana) license detector.
:::

## Arguments ⚙️

### `allowed`

Only allows the use of certain licenses. The command will exit with an error and log the list of all the dependencies that have an unlisted license.

#### Example usage:

```sh
very_good packages check licenses --allowed=MIT,BSD-3-Clause

# ✓ Retrieved 6 licenses from 6 packages of type: BSD-3-Clause (3), MIT (1), unknown (1) and Apache-2.0 (1).
# 2 dependencies have banned licenses: html (unknown) and universal_io (Apache-2.0).
```

:::info
A comprehensive list of all the licenses allowed as options is available within the [_Supported licenses_](#supported-licenses-) section of this document.
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
The `allowed` and `forbidden` options can't be used at the same time. Typical organization usage dictates which licenses are allowed or forbidden, hence optimizing for that use case.
:::

### `dependency-type`

The type of dependencies to check licenses for. There are three available types:

- [`direct-dev`](https://dart.dev/tools/pub/dependencies#dev-dependencies): Another package that your package needs during development.
- [`direct-main`](https://dart.dev/tools/pub/dependencies): Another package that your package needs to work.
- [`direct-overridden`](https://dart.dev/tools/pub/dependencies#dependency-overrides): A dependency that your package overrides that is not already a `direct-main` or `direct-dev` dependency.
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

Skips packages from having their licenses checked. Skipped packages will not be checked against `allowed` or `forbidden` licenses.

#### Example usage:

```sh
very_good packages check licenses --skip-packages=html,universal_io

# ✓ Retrieved 4 licenses from 4 packages of type: BSD-3-Clause (3) and MIT (1).
```

### `ignore-retrieval-failures`

Avoids terminating if the license of a dependency could not be retrieved; this may happen if something went wrong when retrieving the license for a package. When enabled, those packages' licenses will fallback to unknown.

#### Example usage:

```sh
very_good packages check licenses --ignore-retrieval-failures

# ✓ Retrieved 6 licenses from 6 packages of type: BSD-3-Clause (3), MIT (1), unknown (1) and Apache-2.0 (1).
```

## Supported licenses 💳

The license detection is processed by [Dart's package analyzer](https://pub.dev/packages/pana), which reports commonly found licenses (SPDX licenses). The list of accepted licenses can be seen in the [SPDX GitHub repository](https://github.com/spdx/license-list-data/tree/main/text) or in the [SPDX License enumeration](https://github.com/VeryGoodOpenSource/very_good_cli/blob/main/lib/src/pub_license/spdx_license.gen.dart). Therefore, when specifying a license within arguments it must strictly match with the SPDX license name.

If a license file is incorrectly formatted or is not a commonly found license, then it might be reported as `unknown`. If the former is true, we suggest notifying the package maintainer about the issue.

[pub]: https://pub.dev/
