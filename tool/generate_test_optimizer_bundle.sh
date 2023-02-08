#!/bin/bash

mason bundle --source path ./bricks/test_optimizer/ -t dart --output-dir lib/src/commands/test/templates

dart format .
