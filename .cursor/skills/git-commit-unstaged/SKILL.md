---
name: git-commit-unstaged
description: >-
  Helps the agent create Conventional Commits when changes are not yet staged.
  Use when the user has working tree changes, needs to inspect and group them,
  then stage and commit them as well-structured Conventional Commits.
---

# Git Commit (Unstaged Changes)

## Purpose

Use this skill when **changes are not yet staged** and you need to:

- See which files have changed
- Group changes into logical units
- Commit each group using Conventional Commits format

This skill covers the full flow: **stage → generate message → commit**.

## Commit message rules

Commit messages created with this skill must follow the project-wide standards
defined in `commit-message-standards.mdc` (Conventional Commits in English).

- Use the `type`, `scope`, summary, and body style described in that rule file.
- Do not redefine or override those standards here; keep this skill focused on
  the workflow for unstaged changes.

## Workflow (unstaged changes)

1. **Get current change status**

   - Run `git status --short` to list changed files
   - Run `git diff` to see unstaged changes

2. **Group changes into logical units**

   Read the diff and group by:

   - **Feature scope**: one feature addition or fix per group
   - **Change type**: separate `feat`, `fix`, `docs`, `chore`, etc.
   - **Impact area**: per directory, module, or component

   Example groups:

   - Group A: License file and README license section update → `chore(license)`
   - Group B: New API addition → `feat(api)`
   - Group C: Test fixes → `test`

3. **Stage each group**

   For each group:

   - If whole files belong to one group:

     ```bash
     git add path/to/file1 path/to/file2
     ```

   - If multiple groups are mixed in one file, use `git add -p`:

     ```bash
     git add -p path/to/file
     ```

   - After staging, run `git diff --cached` to verify the diff

4. **Create commit message for each group**

   For each staged group:

   - Decide `type` and `scope`
   - Write a one-line summary
   - Add body if needed

   Messages should cover both **what changed** and **why**.

5. **Execute commit**

   For each group:

   - Confirm staged content with `git diff --cached`
   - Commit using Conventional Commits format:

     ```bash
     git commit -m "type(scope): summary"
     ```

   - If there is a body:

     ```bash
     git commit -m "type(scope): summary" -m "Detailed description..."
     ```

   Or:

     ```bash
     git commit -m "$(cat <<'EOF'
     type(scope): summary

     Detailed description...
     EOF
     )"
     ```

6. **Repeat if more changes remain**

   - Run `git status --short` to see if anything is left uncommitted
   - If so, repeat steps 2–5

## Skill selection

- If changes are already staged, prefer **`git-commit-staged`**
- If changes are mainly unstaged, use **this skill** to start with grouping and staging

## Example

### Example: Documentation update (from unstaged)

1. `git status --short`:

   ```text
   M README.md
   M CONTRIBUTING.md
   ```

2. Review the diff; both changes relate to setup instructions, so group them together.

3. Stage:

   ```bash
   git add README.md CONTRIBUTING.md
   ```

4. Message:

   - type: `docs`
   - scope: `readme`
   - summary: `clarify development setup`

5. Commit:

   ```bash
   git commit -m "docs(readme): clarify development setup"
   ```
