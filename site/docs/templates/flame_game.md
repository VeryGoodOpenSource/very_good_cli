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

## Usage

```sh
# Create a new Flame game named my_game
very_good create flame_game my_game --desc "My new Flame game"
```

[blog]: https://verygood.ventures/blog/generate-a-game-with-our-new-template
[very_good_cli_link]: https://github.com/VeryGoodOpenSource/very_good_cli
[mason_link]: https://github.com/felangel/mason
[flame_link]: https://flame-engine.org/
