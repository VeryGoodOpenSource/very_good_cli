#!/bin/bash
# Runs `mason bundle` to generate bundles for all bricks within the respective templates directories.

bricks=(
    very_good_core
    very_good_dart_package
    very_good_dart_cli
    very_good_flutter_package
    very_good_flutter_plugin
    very_good_flame_game
    very_good_docs_site
    very_good_wear_app
)

for brick in "${bricks[@]}"
do
    echo "bundling $brick..."
    mason bundle --source hosted $brick --type dart --output-dir "lib/src/commands/create/templates/$brick/"
done

dart format lib/src/commands/create/templates