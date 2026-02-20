---
sidebar_position: 2
---

# Flutter Flame Game 🕹

This template is for a Flutter game powered by the [Flame Game Engine][flame_link]. It includes a simple demo game with the basics you'll need for game development and VGV-opinionated best practices.

:::note
Read more about this game template [in our blog][blog].
:::

## App Features ✨

- **Components** - Think of them as game objects, or anything that can render in a game.

- **Entity and Behaviors** - Entities are what manage the game objects and the behaviors handle the game logic for those objects.

- **Sprite Sheets** - Easily access and render sprites on the screen.

- **Audio** - Background music and sound effects within the game.

- **VGV Project Architecture** - This project contains a similar architecture to other VGV projects (see our [core starter app](https://github.com/VeryGoodOpenSource/very_good_core/tree/main/src/my_app)).

- **100% Test Coverage** — Each line is executed at least once by a test.

## Providing supported platforms

If you want your game to support only some platforms, pass the `platforms` option with a comma-separated list of the platforms you want to support.

If `platforms` is omitted, all platforms are enabled by default.

The values for platforms are: `android`, `ios`, `web`, `macos`, and `windows`.

## Usage

:::tip
Use `-o` or `--output-directory` to specify a custom output directory for the generated project.
:::

```sh
# Create a new Flame game named my_game
very_good create flame_game my_game --desc "My new Flame game"

# Create a new Flame game named with the name of the current directory
very_good create flame_game . --desc "My new Flame game"

# Create a new Flame game named my_game (supports only android and iOS)
very_good create flame_game my_game --platforms android,ios
```

[blog]: https://verygood.ventures/blog/generate-a-game-with-our-new-template
[flame_link]: https://flame-engine.org/
