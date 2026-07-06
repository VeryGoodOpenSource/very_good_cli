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

# Installs 'act' (https://github.com/nektos/act) for running GitHub Actions locally.
# Always installs the latest release.
# Usage: ./install-act.sh

set -euo pipefail

INSTALL_DIR="${HOME}/.local/bin"

echo "🔧 Installing act..."

# Detect platform
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

case "$ARCH" in
  x86_64)  ARCH="x86_64" ;;
  aarch64) ARCH="arm64" ;;
  arm64)   ARCH="arm64" ;;
  *)
    echo "❌ Unsupported architecture: $ARCH"
    exit 1
    ;;
esac

# Create install directory if it doesn't exist
mkdir -p "$INSTALL_DIR"

# Try system-wide install first, fall back to user-local
if command -v sudo &> /dev/null && sudo -n true 2>/dev/null; then
  echo "  Installing to /usr/local/bin (system-wide)..."
  curl -sL https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash -s -- -b /usr/local/bin
else
  echo "  No sudo access. Installing to ${INSTALL_DIR} (user-local)..."
  curl -sL https://raw.githubusercontent.com/nektos/act/master/install.sh | bash -s -- -b "$INSTALL_DIR"

  # Ensure install dir is on PATH
  if [[ ":$PATH:" != *":${INSTALL_DIR}:"* ]]; then
    echo "  ⚠️  ${INSTALL_DIR} is not on your PATH."
    echo "  Add this to your shell profile: export PATH=\"${INSTALL_DIR}:\$PATH\""
    export PATH="${INSTALL_DIR}:$PATH"
  fi
fi

# Verify installation
if command -v act &> /dev/null; then
  echo "✅ act installed successfully: $(act --version)"
else
  echo "❌ Installation failed. act not found on PATH."
  exit 1
fi
