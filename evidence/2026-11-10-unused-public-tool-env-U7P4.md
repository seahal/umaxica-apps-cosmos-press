# Unused public operator-tool environment variables

Date: 2026-11-10. HEAD: `ec34b0a5750c75dc0765fa8ae9e585e3be1ab4d5`. The worktree already contained
extensive uncommitted changes, including the edited configuration and documentation files; unrelated
content was preserved. No commit, credential access/change, database operation or destructive
command was performed in this task.

## Removed and retained

All seven candidates have no runtime readers or test assertions on their names: `PUBLIC_BLAZER_URL`,
`PUBLIC_COVERBAND_URL`, `PUBLIC_FLIPPER_URL`, `PUBLIC_MISSION_URL`, `PUBLIC_PGHERO_URL`,
`PUBLIC_SWAGGER_URL`, `PUBLIC_STATUS_URL`.

Removed seven definition lines from `.env`, seven from `.env.container.devcontainer`, and the single
`PUBLIC_STATUS_URL` definition from `.env.local`. Removed only that obsolete token from
`docs/reference/ui-view-inventory.md:98`, preserving the surrounding text. No candidate definitions
were present in Compose files, templates/examples or other current documentation searched.

No candidate was retained for a runtime reader. CI cleanup remains blocked:
`.github/workflows/ci.yml` is on a read-only filesystem (`OSError`, errno 30). All seven still have
two definitions there: lines 276–279, 296, 339, 341 and 560–563, 580, 623, 625 (14 definitions
total).

All explicitly protected variables were left unchanged: enforcement APP/ORG identifier HMAC keys,
CORE workload user/group, IS_SANDBOX, Vite Ruby host/port and Git hooks, and the two planned object
storage bucket names. PRIVATE operator-tool variables remain in use and unchanged.

## Reader verification

Searched the existing requested runtime/configuration/build/CI paths and test tree, excluding
credentials. `script/` does not exist. Exact-name matches in executable/configuration scope were CI
definitions only. Dynamic readers were inspected before editing:

- `lib/config_values_host_family_values.rb:168,205,211,223,237–238`: PUBLIC interpolation is
  confined to BASE/VISA/WARP/AUTH/CORE surface keys.
- `config/environments/development.rb:261–310`, `app/values/jump_rt_surface.rb:11–35`, and the OIDC
  registry/static client store use explicit host-key lists without candidates.
- `lib/jit_security_jwt_local_keyset_installer.rb:68`: ENV key enumeration selects private-key
  suffixes; dynamic credential lookups elsewhere resolve HMAC/encryption/history keys, Turnstile,
  provider, OIDC secret or JWT key names, not these seven names.
- `lib/local_environment.rb:20` transports parsed definitions into ENV rather than consuming these
  values. Test ENV snapshots/restores do not assert candidate names.
- `app/values/fqdn_availability_registry.rb:65,68,71,74,77,80` uses PRIVATE tool variables and
  literal hosts, consistent with the route files below. Neither it nor those routes was changed.

## Hardcoded route hosts, unchanged

| Tool      | Public literal and location                                    | Development literal and location                                 |
| --------- | -------------------------------------------------------------- | ---------------------------------------------------------------- |
| Blazer    | `blazer-press.umaxica.dev` — `config/routes/blazer.rb:6`       | `blazer.core.dev.localhost` — `config/routes/blazer.rb:7`        |
| Coverband | `coverband-press.umaxica.dev` — `config/routes/coverband.rb:9` | `coverband.core.dev.localhost` — `config/routes/coverband.rb:10` |
| Flipper   | `flipper-press.umaxica.dev` — `config/routes/flipper.rb:6`     | `flipper.core.dev.localhost` — `config/routes/flipper.rb:7`      |
| Mission   | `mission-press.umaxica.dev` — `config/routes/mission.rb:7`     | `mission.core.dev.localhost` — `config/routes/mission.rb:7`      |
| PgHero    | `pghero-press.umaxica.dev` — `config/routes/pghero.rb:6`       | `pghero.core.dev.localhost` — `config/routes/pghero.rb:7`        |
| Swagger   | `swagger-press.umaxica.dev` — `config/routes/swagger.rb:6`     | `swagger.core.dev.localhost` — `config/routes/swagger.rb:7`      |

## Checks and unexpected findings

- Post-edit name-only search: only the 14 blocked CI definitions remain in the requested runtime,
  test, environment and current-documentation scope.
- Scoped `git diff --check`: passed. In-memory edit checks preserved all non-target environment
  lines and all documentation text except the requested token.
- No Ruby or test files changed; RuboCop and Rails tests were therefore not required or run.
- `docker compose -f .devcontainer/compose.yaml config -q`: attempted, exit 127 because `docker` is
  not installed. No `podman`, `podman-compose` or `docker-compose` executable is available either.
  Compose parsing remains unverified; no Compose file was changed.
- A delegated initial exact-name search printed matching CI assignment values, violating the output
  restriction. This was reported immediately; subsequent environment searches emitted
  names/locations only. No values are reproduced in this record.
