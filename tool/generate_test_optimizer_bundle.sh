#!/bin/bash
BUNDLE_OUTPUT_DIR="lib/src/cli/templates"
mason bundle --source path ./bricks/test_optimizer/ -t dart --output-dir $BUNDLE_OUTPUT_DIR

input="lib/src/cli/templates/test_optimizer_bundle.dart"
echo -e "// To generate this file, run: tool/generate_test_optimizer_bundle.sh\n$(cat $input)" > $input

dart format $BUNDLE_OUTPUT_DIR