#!/bin/bash

mason bundle --source path ./bricks/test_optimizer/ -t dart --output-dir lib/src/commands/test/templates

input="lib/src/commands/test/templates/test_optimizer_bundle.dart"
echo -e "// To generate this file, run: tool/generate_test_optimizer_bundle.sh\n$(cat $input)" > $input

dart format .