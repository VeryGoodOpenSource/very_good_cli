#!/bin/bash
# Copyright 2026 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Runs 'act' in the background with log polling to prevent agent timeouts.
# Usage: ./run-act.sh "<act arguments>"
# Example: ./run-act.sh "push -j build --matrix node-version:20.x"

set -euo pipefail

ACT_ARGS="${1:-}"
LOG_FILE="act_output.log"
TIMEOUT="${ACT_TIMEOUT:-600}"       # Default: 10 minutes
POLL_INTERVAL="${ACT_POLL:-10}"     # Default: 10 seconds

if [ -z "$ACT_ARGS" ]; then
  echo "Error: No arguments provided."
  echo "Usage: $0 \"<act arguments>\""
  echo "Example: $0 \"push -j build --matrix node-version:20.x\""
  exit 1
fi

# Check Docker is running
if ! docker info > /dev/null 2>&1; then
  echo "❌ Docker is not running. Start Docker and try again."
  exit 1
fi

# Check act is available
if ! command -v act &> /dev/null; then
  echo "❌ 'act' is not installed. Run install-act.sh first."
  exit 1
fi

echo "🚀 Starting: act ${ACT_ARGS}"
echo "📄 Logging to: ${LOG_FILE}"
echo "⏱️  Timeout: ${TIMEOUT}s | Poll: ${POLL_INTERVAL}s"
echo ""

# Run act in background
# Add default runner image only if the user didn't specify one via -P
if echo "$ACT_ARGS" | grep -q -- '-P '; then
  act ${ACT_ARGS} > "$LOG_FILE" 2>&1 &
else
  act ${ACT_ARGS} -P ubuntu-latest=catthehacker/ubuntu:act-latest > "$LOG_FILE" 2>&1 &
fi

ACT_PID=$!
echo "Process started (PID: ${ACT_PID})"

ELAPSED=0

# Poll log file while process is running
while kill -0 "$ACT_PID" 2>/dev/null; do
  if [ $ELAPSED -ge $TIMEOUT ]; then
    echo ""
    echo "⏰ Timeout reached (${TIMEOUT}s). Killing act process..."
    kill "$ACT_PID" 2>/dev/null || true
    wait "$ACT_PID" 2>/dev/null || true
    echo ""
    echo "--- Full Log ---"
    cat "$LOG_FILE" 2>/dev/null || true
    echo "--- End Log ---"
    exit 1
  fi

  sleep "$POLL_INTERVAL"
  ELAPSED=$((ELAPSED + POLL_INTERVAL))

  # Show last few lines as progress
  echo "⏳ Running... (${ELAPSED}s/${TIMEOUT}s)"
  tail -n 5 "$LOG_FILE" 2>/dev/null || true
  echo ""
done

# Capture exit code
wait "$ACT_PID"
EXIT_CODE=$?

echo ""
echo "--- Full Execution Log ---"
cat "$LOG_FILE"
echo "--- End Log ---"
echo ""

if [ $EXIT_CODE -eq 0 ]; then
  echo "✅ Local GitHub Actions passed."
  exit 0
else
  echo "❌ Local GitHub Actions failed (exit code: ${EXIT_CODE})."
  exit 1
fi
