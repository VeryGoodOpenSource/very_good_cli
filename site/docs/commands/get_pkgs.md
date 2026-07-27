---
sidebar_position: 2
---

# Get Packages 📦

Get packages in a Dart or Flutter project with `very_good packages get`.

## Usage

```sh
very_good packages get [arguments]
-h, --help         Print this usage information.
-r, --recursive    Install dependencies recursively for all nested packages.
    --ignore       Exclude packages from installing dependencies.

Run "very_good help" to see global options.
```

### Configuring defaults with `very_good.yaml`

To avoid repeating flags every time you run `very_good packages get` locally or on CI, you may create a `very_good.yaml` file at the root of your project. The `packages.get` section accepts the same names as the CLI flags in snake_case. Values from `very_good.yaml` are used as defaults; anything you pass on the command line takes precedence.

```yaml
# very_good.yaml
packages:
  get:
    recursive: true
    ignore:
      - example
```

With the file above, running `very_good packages get` behaves the same as running `very_good packages get --recursive --ignore=example`. You can still override any of these values on the command line.

The `very_good.yaml` file is looked up starting from the directory where the command runs and walking up through its ancestors. The closest file wins; configuration from ancestor directories is not merged.
