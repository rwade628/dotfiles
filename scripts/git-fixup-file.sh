#!/usr/bin/env bash

set -e

FILE="$1"

if [ -z "$FILE" ]; then
    echo "Usage: $0 <filename>"
    exit 1
fi

# Get current branch name
BRANCH=$(git rev-parse --abbrev-ref HEAD)

if [ "$BRANCH" = "HEAD" ]; then
    echo "Error: You're in detached HEAD state. Please checkout a branch first."
    exit 1
fi

# Find the merge-base with origin/main (or origin/master)
if git rev-parse --verify origin/main >/dev/null 2>&1; then
    BASE_BRANCH="origin/main"
elif git rev-parse --verify origin/master >/dev/null 2>&1; then
    BASE_BRANCH="origin/master"
else
    echo "Error: Can't find origin/main or origin/master"
    exit 1
fi

MERGE_BASE=$(git merge-base HEAD $BASE_BRANCH)
echo "Removing '$FILE' from commits since branching from $BASE_BRANCH"
echo "Processing commits from $(git rev-parse --short $MERGE_BASE) to HEAD"

# Save the remote URL
REMOTE_URL=$(git config --get remote.origin.url 2>/dev/null || echo "")

# Filter only commits since branching from main
git filter-repo \
    --invert-paths \
    --path "$FILE" \
    --refs "$MERGE_BASE..HEAD" \
    --partial \
    --force

# Re-add the remote
if [ -n "$REMOTE_URL" ]; then
    git remote add origin "$REMOTE_URL" 2>/dev/null || true
fi

echo "✓ File '$FILE' has been purged from your branch commits only"
echo "  Use 'git push --force-lease origin $BRANCH' to update the remote"
