#!/bin/bash
# Runs `mason bundle` to generate bundles for all bricks within the respective templates directories.

bricks=(very_good_core very_good_dart_package very_good_dart_cli very_good_flutter_package very_good_flutter_plugin)

for brick in "${bricks[@]}"
do
    echo "bundling $brick..."
    mason bundle -s git "https://github.com/verygoodopensource/$brick" --git-path brick -t dart -o "lib/src/commands/create/templates/$brick"
done

dart format .