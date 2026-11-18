# Build artifacts, tracked secrets and GitHub Actions

**Decision pending.** The review found a supply-chain pinning decision and a conditional source map
publication risk. No secret in a delivered browser bundle or compromise of a CI job was observed.

## Static assets and secrets

An isolated production-mode Vite asset build from the reviewed source produced one stylesheet and
two manifests. It produced no JS or source map. Vite uses hidden source maps, which can still
generate map files when JS entries exist. The image recipe copies the entire Vite output directory.
Production Rails disables its public file server. The asset host's upload and serving rules
determine whether a future map reaches a browser. The full container image was not built in this
review. [Vite configuration](../../vite.config.ts#L21) · [Asset copy](../../Containerfile#L164) ·
[Serving configuration](../../config/environments/production.rb#L201)

The builder ignore files exclude Git metadata, local environment files, Rails master keys and
per-environment decryption keys, with an exception for environment templates. The tracked public
tree contains static assets and error documents. A limited pattern search of tracked files found no
full PEM private-key bodies or representative GitHub, AWS access-key ID and Stripe live-token
shapes. The fixed development dashboard credentials are recorded separately. These checks covered
the current tree. Git history, saved CI logs, image layers, CDN objects and artifact retention
require their own evidence. [Podman exclusions](../../.containerignore#L31) ·
[Docker exclusions](../../.dockerignore#L29) · [Public tree](../../public) ·
[Development credentials](2026-11-18-development-dashboard-credentials.md) ·
[Earlier history disclosure](2026-11-11-credential-exposure-disclosure.md)

## Workflow permissions and dependency scanning

The CI workflow defaults to read-only repository contents and explicitly disables persisted checkout
credentials in the jobs examined. The build uses the frozen Bun lockfile. Brakeman, Gitleaks,
CodeQL, Ruby/Bun audit and dependency review are configured. Several actions are referenced by
mutable version tags. Examples include setup-ruby in a job with security-event write permission and
the dependency-review action in a job with pull-request write permission. The review did not
establish that a tag had moved or that a token had been disclosed.
[CI default permissions](../../.github/workflows/ci.yml#L11) ·
[Build and security job](../../.github/workflows/ci.yml#L51) ·
[CodeQL](../../.github/workflows/codeql.yml#L17) ·
[Dependency review](../../.github/workflows/dependencyreview.yml#L11)

**Decision for build and CI owners.** Decide whether actions in write-capable jobs should be pinned
by commit, and identify who would maintain those pins. If browser JS or an asset upload step is
introduced, inspect the final public artifact list for maps and source content. The README lists no
CD system. Branch protection, workflow enforcement, the actual asset publisher and retained logs
were unverified. [Infrastructure inventory](../../README.md#infrastructure)
