#!/bin/bash
# Runs `mason bundle` to generate the bundle for the optimizer used in the test command

mason bundle --source path ./bricks/test_optimizer/ -t dart --output-dir lib/src/commands/test/templates

dart format .
