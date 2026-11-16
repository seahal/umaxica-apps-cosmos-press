# Use direnv for the Development Environment

- Status: accepted
- Date: 2026-11-16

## Context

Each repository needs per-project environment variables (tool versions, local service URLs,
credentials for development) when a developer works in it. Exporting these by hand or from a shell
profile leaks values between repositories and makes the setup differ between machines.

## Decision

- This repository uses [direnv](https://direnv.net/) to load its development environment.
- The environment is defined in `.envrc` at the repository root. direnv loads it on entering the
  directory and unloads it on leaving.
- A developer runs `direnv allow` once after cloning and again after each reviewed change to
  `.envrc`.
- Files load in this order, broadest first, and a later file overrides an earlier one:
  1. `.envrc` (committed): every shared development value, including development-only placeholder
     keys and passwords such as `pass`, `test`, or `local-…`.
  2. `.envrc.credential` (git-ignored): real credentials only. It is empty by default.
  3. `.envrc.local` (git-ignored): overrides for one developer's machine.
- Rails, Vite, and Compose inherit local settings from their process environment. CI and deployment
  continue to supply their own environment.

## Consequences

Developers must install direnv and hook it into their shell. Environment variables are scoped to the
repository, so values do not carry over between repositories. Changes to `.envrc` require a fresh
`direnv allow`, which keeps unreviewed code from running automatically.
