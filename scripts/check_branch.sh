#!/usr/bin/env bash
set -e

BRANCH=$(git branch --show-current)
case "$BRANCH" in
  main|master)
    echo "✅ Releasing on production branch: $BRANCH"
    ;;
  *beta*|*alpha*|*rc*|*dev*|*staging*|*release*|*pre*)
    echo "✅ Releasing on prerelease/staging branch: $BRANCH"
    ;;
  *)
    echo "❌ ERROR: Versioning is blocked on feature/fix branch '$BRANCH'!" >&2
    echo "Allowed branches: main, master, or branches matching *beta*, *alpha*, *rc*, *dev*, *staging*, *release*, *pre*" >&2
    exit 1
    ;;
esac
