# Local recipes (not upstream); see Makefile for project targets.

# Fetch upstream and merge upstream/main into the current branch
upstream-update:
  git fetch upstream
  git merge upstream/main
