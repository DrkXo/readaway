#!/usr/bin/env bash
# ReadAway Git Hooks Setup Script
# Configures Git to use version-controlled hooks from .githooks/

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Configuring ReadAway Git hooks...${NC}"

# Ensure hooks directory exists
if [ ! -d ".githooks" ]; then
  echo "Error: .githooks directory not found."
  exit 1
fi

# Make hook scripts executable
chmod +x .githooks/* 2>/dev/null || true

# Configure Git hooks path
git config core.hooksPath .githooks

echo -e "${GREEN}Git hooks path set to '.githooks'. All hooks are now active!${NC}"
