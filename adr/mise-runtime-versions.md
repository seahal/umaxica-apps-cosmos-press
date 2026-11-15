# Use mise for Runtime Versions

- Status: accepted
- Date: 2026-11-16

## Context

Development runs directly on the developer's machine, without a development container. Runtime
versions (for example Ruby, Node.js, pnpm, Bun) must still match between developers, CI, and
production. Relying on whatever the operating system or a global installer provides lets versions
drift between machines and repositories.

## Decision

- This repository uses [mise](https://mise.jdx.dev/) to install and select runtime and tool
  versions.
- The committed `mise.toml` at the repository root enables version file detection for Ruby and
  Node.js, and pins Bun directly. mise selects Ruby from the `ruby` line in `Gemfile` and Node.js
  from `.node-version`.
- `.ruby-version` is kept equal to the Ruby version in `Gemfile`. Bun in `mise.toml` is kept equal
  to the `packageManager` entry in `package.json`, which CI uses. The build arguments in
  `Containerfile` and the Node.js engines range in `package.json` follow the same versions.
- A developer runs `mise install` after cloning and after any runtime version changes.
- mise handles runtimes and tools only. Environment variables stay with direnv, as decided in the
  direnv ADR.

## Consequences

Developers must install mise and activate it in their shell. Each repository can use its own runtime
versions without affecting other repositories. A version upgrade changes the file that mise reads
and every other declaration of the same version in one reviewed change.
