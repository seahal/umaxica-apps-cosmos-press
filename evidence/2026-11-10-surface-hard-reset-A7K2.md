# Press surface hard reset evidence

Date: 2026-11-10 `git rev-parse HEAD`: `ec34b0a5750c75dc0765fa8ae9e585e3be1ab4d5` Uncommitted
changes affected the results: **yes**. This worktree was already substantially dirty before this
task; the checks below ran against the full current worktree. The deletion totals are cumulative
diffs against HEAD and do not isolate task-only changes. No commit was created.

No database was dropped. The model/database inventory is a static source scan; the requested Rails
test run used configured test databases. No models or migrations were deleted.

## 1. Surface and route inventory

README.md identifies the owned application surfaces as Edit ORG and Docs, Help, Info, and News for
APP/COM/ORG, plus Mission, Flipper, Blazer, PgHero, Swagger, and Coverband. This inventory was
checked against that list. Route counts below are grouped by source host constraint; resolved host
values are omitted so no environment values enter the record. Counts include mounted engine routes
where emitted by `bin/rails routes`.

| Host-constraint group    | Classification                 |                                 Routes |
| ------------------------ | ------------------------------ | -------------------------------------: |
| Docs APP / COM / ORG     | OWN                            |                     11 each (33 total) |
| Help APP / COM / ORG     | OWN                            |                     11 each (33 total) |
| Info APP / COM / ORG     | OWN                            |                     11 each (33 total) |
| News APP / COM / ORG     | OWN                            |                     11 each (33 total) |
| Edit ORG                 | OWN                            |                                    163 |
| Mission Control Jobs     | OWN operator tool              |      25 (mount plus 24 engine actions) |
| Flipper                  | OWN operator tool              |                           1 Rack mount |
| Blazer                   | OWN operator tool              |      32 (mount plus 31 engine actions) |
| PgHero                   | OWN operator tool              |      26 (mount plus 25 engine actions) |
| Swagger API/UI           | OWN operator tool              |   2 mounts; no internal routes emitted |
| Coverband                | OWN operator tool, conditional | 0 emitted by the current route command |
| Unknown-host fallback    | OWN boundary handler           |                       1, unconstrained |
| **Total emitted routes** |                                |                                **382** |

The final `bin/rails routes` run passed. A three-route Turbo Rails Native navigation set was found
in the earlier development route output. The app has no caller for those endpoints;
`config/application.rb` now disables that framework route set, and obsolete test path exclusions
were removed. The final route listing contains no Turbo navigation routes. Active Storage routes
remain disabled.

### Controller namespace inventory

| Namespace / controller area                                            | Classification                                   | State                                                       |
| ---------------------------------------------------------------------- | ------------------------------------------------ | ----------------------------------------------------------- |
| `docs`                                                                 | OWN                                              | 33 controller files                                         |
| `edit`                                                                 | OWN                                              | 57 controller files                                         |
| `help`                                                                 | OWN                                              | 33 controller files                                         |
| `info`                                                                 | OWN                                              | 33 controller files                                         |
| `news`                                                                 | OWN                                              | 33 controller files                                         |
| `ApplicationController`                                                | OWN shared base                                  | Root controller, no direct route target                     |
| `UnknownHostsController`                                               | OWN boundary handler                             | Root controller for the one fallback route                  |
| `concerns`                                                             | OWN shared code                                  | 68 current controller concerns; not a route namespace       |
| Mission Control Jobs, Flipper, Blazer, PgHero, Rswag API/UI, Coverband | OWN operator tools                               | Mounted or conditional tool routes as listed above          |
| `auth`, `base`, `core`, `guid`, `palm`, `tech`, `visa`, `warp`         | FOREIGN/RETIRED                                  | Controller roots removed; no current route rows target them |
| Turbo Native navigation                                                | FOREIGN framework route set for this application | Disabled; no current route entries or app callers           |

Deleted route source files: `auth.rb`, `base.rb`, `core.rb`, `guid.rb`, `performance.rb`, `palm.rb`,
`tech.rb`, `visa.rb`, and `warp.rb`. The full current route-by-route listing, including methods,
paths, targets, names, source files, and host-constraint groups, follows.

# Current route and controller inventory

Snapshot from bin/rails routes in the current worktree. Environment-derived host values are not
included. Host source expressions and route-file line references identify each constraint; the Rails
command output does not show host constraints, so application rows are grouped by matching route
source and controller namespace.

## Host-constraint groups

| Host group                            | Source                        | Constraint inputs (resolved values omitted)                                                                                           | Listed route entries |
| ------------------------------------- | ----------------------------- | ------------------------------------------------------------------------------------------------------------------------------------- | -------------------: |
| Docs app host constraint              | config/routes/docs.rb:7-60    | boot_config hosts.docs_service.host; fixed aliases are declared in that block                                                         |                   11 |
| Docs com host constraint              | config/routes/docs.rb:61-112  | boot_config hosts.docs_corporate.host; fixed aliases are declared in that block                                                       |                   11 |
| Docs org host constraint              | config/routes/docs.rb:113-end | boot_config hosts.docs_staff.host; fixed aliases are declared in that block                                                           |                   11 |
| Help app host constraint              | config/routes/help.rb:7-58    | boot_config hosts.help_service.host; fixed aliases are declared in that block                                                         |                   11 |
| Help com host constraint              | config/routes/help.rb:59-110  | boot_config hosts.help_corporate.host; fixed aliases are declared in that block                                                       |                   11 |
| Help org host constraint              | config/routes/help.rb:111-end | boot_config hosts.help_staff.host; fixed aliases are declared in that block                                                           |                   11 |
| Info app host constraint              | config/routes/info.rb:7-43    | boot_config hosts.info_service.host; fixed aliases are declared in that block                                                         |                   11 |
| Info com host constraint              | config/routes/info.rb:44-80   | boot_config hosts.info_corporate.host; fixed aliases are declared in that block                                                       |                   11 |
| Info org host constraint              | config/routes/info.rb:81-end  | boot_config hosts.info_staff.host; fixed aliases are declared in that block                                                           |                   11 |
| News app host constraint              | config/routes/news.rb:7-60    | boot_config hosts.news_service.host; fixed aliases are declared in that block                                                         |                   11 |
| News com host constraint              | config/routes/news.rb:61-114  | boot_config hosts.news_corporate.host; fixed aliases are declared in that block                                                       |                   11 |
| News org host constraint              | config/routes/news.rb:115-end | boot_config hosts.news_staff.host; fixed aliases are declared in that block                                                           |                   11 |
| Edit org host constraint              | config/routes/edit.rb:7-end   | boot_config hosts.edit_staff.host; ENV keys PUBLIC_EDIT_STAFF_URL and PRIVATE_EDIT_STAFF_URL; fixed aliases are declared in the block |                  163 |
| Mission operator-tool host constraint | config/routes/mission.rb:7    | ENV key PRIVATE_MISSION_URL; fixed aliases are declared in the block                                                                  |                   25 |
| Flipper operator-tool host constraint | config/routes/flipper.rb:6    | ENV key PRIVATE_FLIPPER_URL; fixed aliases are declared in the block                                                                  |                    1 |
| Blazer operator-tool host constraint  | config/routes/blazer.rb:6     | ENV key PRIVATE_BLAZER_URL; fixed aliases are declared in the block                                                                   |                   32 |
| PgHero operator-tool host constraint  | config/routes/pghero.rb:6     | ENV key PRIVATE_PGHERO_URL; fixed aliases are declared in the block                                                                   |                   26 |
| Swagger operator-tool host constraint | config/routes/swagger.rb:6    | ENV key PRIVATE_SWAGGER_URL; fixed aliases are declared in the block                                                                  |                    2 |
| Unknown-host fallback (unconstrained) | config/routes.rb: final route | No host constraint                                                                                                                    |                    1 |
| Framework-generated hostless route    | None in current route listing | No host constraint                                                                                                                    |                    0 |

Each row below is one verb/path/target from the route command. Repeated routes appear separately for
each audience host constraint.

### Docs app host constraint (11 entries)

| Verb | Path                                 | Target                                | Route name                    |
| ---- | ------------------------------------ | ------------------------------------- | ----------------------------- |
| GET  | /                                    | docs/app/roots#index                  | docs_app_root                 |
| GET  | /revision                            | docs/app/revisions#show               | docs_app_revision             |
| GET  | /health                              | docs/app/healths#show                 | docs_app_health               |
| GET  | /health/liveness                     | docs/app/health/livenesses#show       | docs_app_health_liveness      |
| GET  | /health/readiness                    | docs/app/health/readinesses#show      | docs_app_health_readiness     |
| GET  | /health/startup                      | docs/app/health/startups#show         | docs_app_health_startup       |
| POST | /csp-violation-report(.:format)      | docs/app/csp_violation_reports#create | docs_app_csp_violation_report |
| GET  | /api/v0/entries(.:format)            | docs/app/api/v0/entries#index         | docs_app_api_v0_entries       |
| GET  | /api/v0/entries/:public_id(.:format) | docs/app/api/v0/entries#show          | docs_app_api_v0_entry         |
| GET  | /api/v0/health.json                  | docs/app/api/v0/healths#show          | docs_app_api_v0_health        |
| GET  | /api/v0/revision.json                | docs/app/api/v0/revisions#show        | docs_app_api_v0_revision      |

### Docs com host constraint (11 entries)

| Verb | Path                                 | Target                                | Route name                    |
| ---- | ------------------------------------ | ------------------------------------- | ----------------------------- |
| GET  | /                                    | docs/com/roots#index                  | docs_com_root                 |
| GET  | /revision                            | docs/com/revisions#show               | docs_com_revision             |
| GET  | /health                              | docs/com/healths#show                 | docs_com_health               |
| GET  | /health/liveness                     | docs/com/health/livenesses#show       | docs_com_health_liveness      |
| GET  | /health/readiness                    | docs/com/health/readinesses#show      | docs_com_health_readiness     |
| GET  | /health/startup                      | docs/com/health/startups#show         | docs_com_health_startup       |
| POST | /csp-violation-report(.:format)      | docs/com/csp_violation_reports#create | docs_com_csp_violation_report |
| GET  | /api/v0/entries(.:format)            | docs/com/api/v0/entries#index         | docs_com_api_v0_entries       |
| GET  | /api/v0/entries/:public_id(.:format) | docs/com/api/v0/entries#show          | docs_com_api_v0_entry         |
| GET  | /api/v0/health.json                  | docs/com/api/v0/healths#show          | docs_com_api_v0_health        |
| GET  | /api/v0/revision.json                | docs/com/api/v0/revisions#show        | docs_com_api_v0_revision      |

### Docs org host constraint (11 entries)

| Verb | Path                                 | Target                                | Route name                    |
| ---- | ------------------------------------ | ------------------------------------- | ----------------------------- |
| GET  | /                                    | docs/org/roots#index                  | docs_org_root                 |
| GET  | /revision                            | docs/org/revisions#show               | docs_org_revision             |
| GET  | /health                              | docs/org/healths#show                 | docs_org_health               |
| GET  | /health/liveness                     | docs/org/health/livenesses#show       | docs_org_health_liveness      |
| GET  | /health/readiness                    | docs/org/health/readinesses#show      | docs_org_health_readiness     |
| GET  | /health/startup                      | docs/org/health/startups#show         | docs_org_health_startup       |
| POST | /csp-violation-report(.:format)      | docs/org/csp_violation_reports#create | docs_org_csp_violation_report |
| GET  | /api/v0/entries(.:format)            | docs/org/api/v0/entries#index         | docs_org_api_v0_entries       |
| GET  | /api/v0/entries/:public_id(.:format) | docs/org/api/v0/entries#show          | docs_org_api_v0_entry         |
| GET  | /api/v0/health.json                  | docs/org/api/v0/healths#show          | docs_org_api_v0_health        |
| GET  | /api/v0/revision.json                | docs/org/api/v0/revisions#show        | docs_org_api_v0_revision      |

### Help app host constraint (11 entries)

| Verb | Path                                 | Target                                | Route name                    |
| ---- | ------------------------------------ | ------------------------------------- | ----------------------------- |
| GET  | /                                    | help/app/roots#index                  | help_app_root                 |
| GET  | /revision                            | help/app/revisions#show               | help_app_revision             |
| GET  | /health                              | help/app/healths#show                 | help_app_health               |
| GET  | /health/liveness                     | help/app/health/livenesses#show       | help_app_health_liveness      |
| GET  | /health/readiness                    | help/app/health/readinesses#show      | help_app_health_readiness     |
| GET  | /health/startup                      | help/app/health/startups#show         | help_app_health_startup       |
| POST | /csp-violation-report(.:format)      | help/app/csp_violation_reports#create | help_app_csp_violation_report |
| GET  | /api/v0/entries(.:format)            | help/app/api/v0/entries#index         | help_app_api_v0_entries       |
| GET  | /api/v0/entries/:public_id(.:format) | help/app/api/v0/entries#show          | help_app_api_v0_entry         |
| GET  | /api/v0/health.json                  | help/app/api/v0/healths#show          | help_app_api_v0_health        |
| GET  | /api/v0/revision.json                | help/app/api/v0/revisions#show        | help_app_api_v0_revision      |

### Help com host constraint (11 entries)

| Verb | Path                                 | Target                                | Route name                    |
| ---- | ------------------------------------ | ------------------------------------- | ----------------------------- |
| GET  | /                                    | help/com/roots#index                  | help_com_root                 |
| GET  | /revision                            | help/com/revisions#show               | help_com_revision             |
| GET  | /health                              | help/com/healths#show                 | help_com_health               |
| GET  | /health/liveness                     | help/com/health/livenesses#show       | help_com_health_liveness      |
| GET  | /health/readiness                    | help/com/health/readinesses#show      | help_com_health_readiness     |
| GET  | /health/startup                      | help/com/health/startups#show         | help_com_health_startup       |
| POST | /csp-violation-report(.:format)      | help/com/csp_violation_reports#create | help_com_csp_violation_report |
| GET  | /api/v0/entries(.:format)            | help/com/api/v0/entries#index         | help_com_api_v0_entries       |
| GET  | /api/v0/entries/:public_id(.:format) | help/com/api/v0/entries#show          | help_com_api_v0_entry         |
| GET  | /api/v0/health.json                  | help/com/api/v0/healths#show          | help_com_api_v0_health        |
| GET  | /api/v0/revision.json                | help/com/api/v0/revisions#show        | help_com_api_v0_revision      |

### Help org host constraint (11 entries)

| Verb | Path                                 | Target                                | Route name                    |
| ---- | ------------------------------------ | ------------------------------------- | ----------------------------- |
| GET  | /                                    | help/org/roots#index                  | help_org_root                 |
| GET  | /revision                            | help/org/revisions#show               | help_org_revision             |
| GET  | /health                              | help/org/healths#show                 | help_org_health               |
| GET  | /health/liveness                     | help/org/health/livenesses#show       | help_org_health_liveness      |
| GET  | /health/readiness                    | help/org/health/readinesses#show      | help_org_health_readiness     |
| GET  | /health/startup                      | help/org/health/startups#show         | help_org_health_startup       |
| POST | /csp-violation-report(.:format)      | help/org/csp_violation_reports#create | help_org_csp_violation_report |
| GET  | /api/v0/entries(.:format)            | help/org/api/v0/entries#index         | help_org_api_v0_entries       |
| GET  | /api/v0/entries/:public_id(.:format) | help/org/api/v0/entries#show          | help_org_api_v0_entry         |
| GET  | /api/v0/health.json                  | help/org/api/v0/healths#show          | help_org_api_v0_health        |
| GET  | /api/v0/revision.json                | help/org/api/v0/revisions#show        | help_org_api_v0_revision      |

### Info app host constraint (11 entries)

| Verb | Path                                 | Target                                | Route name                    |
| ---- | ------------------------------------ | ------------------------------------- | ----------------------------- |
| GET  | /                                    | info/app/roots#index                  | info_app_root                 |
| GET  | /revision                            | info/app/revisions#show               | info_app_revision             |
| GET  | /health                              | info/app/healths#show                 | info_app_health               |
| GET  | /health/liveness                     | info/app/health/livenesses#show       | info_app_health_liveness      |
| GET  | /health/readiness                    | info/app/health/readinesses#show      | info_app_health_readiness     |
| GET  | /health/startup                      | info/app/health/startups#show         | info_app_health_startup       |
| POST | /csp-violation-report(.:format)      | info/app/csp_violation_reports#create | info_app_csp_violation_report |
| GET  | /api/v0/entries(.:format)            | info/app/api/v0/entries#index         | info_app_api_v0_entries       |
| GET  | /api/v0/entries/:public_id(.:format) | info/app/api/v0/entries#show          | info_app_api_v0_entry         |
| GET  | /api/v0/health.json                  | info/app/api/v0/healths#show          | info_app_api_v0_health        |
| GET  | /api/v0/revision.json                | info/app/api/v0/revisions#show        | info_app_api_v0_revision      |

### Info com host constraint (11 entries)

| Verb | Path                                 | Target                                | Route name                    |
| ---- | ------------------------------------ | ------------------------------------- | ----------------------------- |
| GET  | /                                    | info/com/roots#index                  | info_com_root                 |
| GET  | /revision                            | info/com/revisions#show               | info_com_revision             |
| GET  | /health                              | info/com/healths#show                 | info_com_health               |
| GET  | /health/liveness                     | info/com/health/livenesses#show       | info_com_health_liveness      |
| GET  | /health/readiness                    | info/com/health/readinesses#show      | info_com_health_readiness     |
| GET  | /health/startup                      | info/com/health/startups#show         | info_com_health_startup       |
| POST | /csp-violation-report(.:format)      | info/com/csp_violation_reports#create | info_com_csp_violation_report |
| GET  | /api/v0/entries(.:format)            | info/com/api/v0/entries#index         | info_com_api_v0_entries       |
| GET  | /api/v0/entries/:public_id(.:format) | info/com/api/v0/entries#show          | info_com_api_v0_entry         |
| GET  | /api/v0/health.json                  | info/com/api/v0/healths#show          | info_com_api_v0_health        |
| GET  | /api/v0/revision.json                | info/com/api/v0/revisions#show        | info_com_api_v0_revision      |

### Info org host constraint (11 entries)

| Verb | Path                                 | Target                                | Route name                    |
| ---- | ------------------------------------ | ------------------------------------- | ----------------------------- |
| GET  | /                                    | info/org/roots#index                  | info_org_root                 |
| GET  | /revision                            | info/org/revisions#show               | info_org_revision             |
| GET  | /health                              | info/org/healths#show                 | info_org_health               |
| GET  | /health/liveness                     | info/org/health/livenesses#show       | info_org_health_liveness      |
| GET  | /health/readiness                    | info/org/health/readinesses#show      | info_org_health_readiness     |
| GET  | /health/startup                      | info/org/health/startups#show         | info_org_health_startup       |
| POST | /csp-violation-report(.:format)      | info/org/csp_violation_reports#create | info_org_csp_violation_report |
| GET  | /api/v0/entries(.:format)            | info/org/api/v0/entries#index         | info_org_api_v0_entries       |
| GET  | /api/v0/entries/:public_id(.:format) | info/org/api/v0/entries#show          | info_org_api_v0_entry         |
| GET  | /api/v0/health.json                  | info/org/api/v0/healths#show          | info_org_api_v0_health        |
| GET  | /api/v0/revision.json                | info/org/api/v0/revisions#show        | info_org_api_v0_revision      |

### News app host constraint (11 entries)

| Verb | Path                                 | Target                                | Route name                    |
| ---- | ------------------------------------ | ------------------------------------- | ----------------------------- |
| GET  | /                                    | news/app/roots#index                  | news_app_root                 |
| GET  | /revision                            | news/app/revisions#show               | news_app_revision             |
| GET  | /health                              | news/app/healths#show                 | news_app_health               |
| GET  | /health/liveness                     | news/app/health/livenesses#show       | news_app_health_liveness      |
| GET  | /health/readiness                    | news/app/health/readinesses#show      | news_app_health_readiness     |
| GET  | /health/startup                      | news/app/health/startups#show         | news_app_health_startup       |
| POST | /csp-violation-report(.:format)      | news/app/csp_violation_reports#create | news_app_csp_violation_report |
| GET  | /api/v0/entries(.:format)            | news/app/api/v0/entries#index         | news_app_api_v0_entries       |
| GET  | /api/v0/entries/:public_id(.:format) | news/app/api/v0/entries#show          | news_app_api_v0_entry         |
| GET  | /api/v0/health.json                  | news/app/api/v0/healths#show          | news_app_api_v0_health        |
| GET  | /api/v0/revision.json                | news/app/api/v0/revisions#show        | news_app_api_v0_revision      |

### News com host constraint (11 entries)

| Verb | Path                                 | Target                                | Route name                    |
| ---- | ------------------------------------ | ------------------------------------- | ----------------------------- |
| GET  | /                                    | news/com/roots#index                  | news_com_root                 |
| GET  | /revision                            | news/com/revisions#show               | news_com_revision             |
| GET  | /health                              | news/com/healths#show                 | news_com_health               |
| GET  | /health/liveness                     | news/com/health/livenesses#show       | news_com_health_liveness      |
| GET  | /health/readiness                    | news/com/health/readinesses#show      | news_com_health_readiness     |
| GET  | /health/startup                      | news/com/health/startups#show         | news_com_health_startup       |
| POST | /csp-violation-report(.:format)      | news/com/csp_violation_reports#create | news_com_csp_violation_report |
| GET  | /api/v0/entries(.:format)            | news/com/api/v0/entries#index         | news_com_api_v0_entries       |
| GET  | /api/v0/entries/:public_id(.:format) | news/com/api/v0/entries#show          | news_com_api_v0_entry         |
| GET  | /api/v0/health.json                  | news/com/api/v0/healths#show          | news_com_api_v0_health        |
| GET  | /api/v0/revision.json                | news/com/api/v0/revisions#show        | news_com_api_v0_revision      |

### News org host constraint (11 entries)

| Verb | Path                                 | Target                                | Route name                    |
| ---- | ------------------------------------ | ------------------------------------- | ----------------------------- |
| GET  | /                                    | news/org/roots#index                  | news_org_root                 |
| GET  | /revision                            | news/org/revisions#show               | news_org_revision             |
| GET  | /health                              | news/org/healths#show                 | news_org_health               |
| GET  | /health/liveness                     | news/org/health/livenesses#show       | news_org_health_liveness      |
| GET  | /health/readiness                    | news/org/health/readinesses#show      | news_org_health_readiness     |
| GET  | /health/startup                      | news/org/health/startups#show         | news_org_health_startup       |
| POST | /csp-violation-report(.:format)      | news/org/csp_violation_reports#create | news_org_csp_violation_report |
| GET  | /api/v0/entries(.:format)            | news/org/api/v0/entries#index         | news_org_api_v0_entries       |
| GET  | /api/v0/entries/:public_id(.:format) | news/org/api/v0/entries#show          | news_org_api_v0_entry         |
| GET  | /api/v0/health.json                  | news/org/api/v0/healths#show          | news_org_api_v0_health        |
| GET  | /api/v0/revision.json                | news/org/api/v0/revisions#show        | news_org_api_v0_revision      |

### Edit org host constraint (163 entries)

| Verb   | Path                                                                                                   | Target                                                            | Route name                                      |
| ------ | ------------------------------------------------------------------------------------------------------ | ----------------------------------------------------------------- | ----------------------------------------------- |
| GET    | /                                                                                                      | edit/org/roots#index                                              | edit_org_root                                   |
| GET    | /dashboard(.:format)                                                                                   | edit/org/dashboards#show                                          | edit_org_dashboard                              |
| GET    | /revision                                                                                              | edit/org/revisions#show                                           | edit_org_revision                               |
| GET    | /health                                                                                                | edit/org/healths#show                                             | edit_org_health                                 |
| GET    | /health/liveness                                                                                       | edit/org/health/livenesses#show                                   | edit_org_health_liveness                        |
| GET    | /health/readiness                                                                                      | edit/org/health/readinesses#show                                  | edit_org_health_readiness                       |
| GET    | /health/startup                                                                                        | edit/org/health/startups#show                                     | edit_org_health_startup                         |
| POST   | /csp-violation-report(.:format)                                                                        | edit/org/csp_violation_reports#create                             | edit_org_csp_violation_report                   |
| GET    | /api/v0/health.json                                                                                    | edit/org/api/v0/healths#show                                      | edit_org_api_v0_health                          |
| GET    | /api/v0/revision.json                                                                                  | edit/org/api/v0/revisions#show                                    | edit_org_api_v0_revision                        |
| POST   | /api/v0/publishing/:surface/:audience/entries/:entry_entry_ref/publications(.:format)                  | edit/org/api/v0/publishing/publications#create {surface: /docs\\  | help\\                                          | info\\ | news/, audience: /app\\ | com\\ | org/} | edit_org_api_v0_publishing_entry_publications |
| DELETE | /api/v0/publishing/:surface/:audience/entries/:entry_entry_ref/publications/:publication_ref(.:format) | edit/org/api/v0/publishing/publications#destroy {surface: /docs\\ | help\\                                          | info\\ | news/, audience: /app\\ | com\\ | org/} | edit_org_api_v0_publishing_entry_publication  |
| DELETE | /api/v0/publishing/:surface/:audience/entries/:entry_entry_ref/archive(.:format)                       | edit/org/api/v0/publishing/archives#destroy {surface: /docs\\     | help\\                                          | info\\ | news/, audience: /app\\ | com\\ | org/} | edit_org_api_v0_publishing_entry_archive      |
| POST   | /api/v0/publishing/:surface/:audience/entries/:entry_entry_ref/archive(.:format)                       | edit/org/api/v0/publishing/archives#create {surface: /docs\\      | help\\                                          | info\\ | news/, audience: /app\\ | com\\ | org/} | —                                             |
| GET    | /api/v0/publishing/:surface/:audience/entries(.:format)                                                | edit/org/api/v0/publishing/entries#index {surface: /docs\\        | help\\                                          | info\\ | news/, audience: /app\\ | com\\ | org/} | edit_org_api_v0_publishing_entries            |
| POST   | /api/v0/publishing/:surface/:audience/entries(.:format)                                                | edit/org/api/v0/publishing/entries#create {surface: /docs\\       | help\\                                          | info\\ | news/, audience: /app\\ | com\\ | org/} | —                                             |
| GET    | /api/v0/publishing/:surface/:audience/entries/:entry_ref(.:format)                                     | edit/org/api/v0/publishing/entries#show {surface: /docs\\         | help\\                                          | info\\ | news/, audience: /app\\ | com\\ | org/} | edit_org_api_v0_publishing_entry              |
| PATCH  | /api/v0/publishing/:surface/:audience/entries/:entry_ref(.:format)                                     | edit/org/api/v0/publishing/entries#update {surface: /docs\\       | help\\                                          | info\\ | news/, audience: /app\\ | com\\ | org/} | —                                             |
| PUT    | /api/v0/publishing/:surface/:audience/entries/:entry_ref(.:format)                                     | edit/org/api/v0/publishing/entries#update {surface: /docs\\       | help\\                                          | info\\ | news/, audience: /app\\ | com\\ | org/} | —                                             |
| GET    | /oidc/callback(.:format)                                                                               | edit/org/oidc/callbacks#show                                      | edit_org_oidc_callback                          |
| POST   | /oidc/closures(.:format)                                                                               | edit/org/oidc/closures#create                                     | edit_org_oidc_closures                          |
| GET    | /verification(.:format)                                                                                | edit/org/verifications#show                                       | edit_org_verification                           |
| POST   | /verification(.:format)                                                                                | edit/org/verifications#create                                     | —                                               |
| GET    | /sign(.:format)                                                                                        | edit/org/sign/entries#show                                        | edit_org_sign_show                              |
| POST   | /sign(.:format)                                                                                        | edit/org/sign/entries#create                                      | edit_org_sign_create                            |
| GET    | /sign/interruption(.:format)                                                                           | edit/org/sign/interruptions#show                                  | edit_org_sign_interruption                      |
| GET    | /sign/out/new(.:format)                                                                                | edit/org/sign/outs#new                                            | new_edit_org_sign_out                           |
| GET    | /sign/out/edit(.:format)                                                                               | edit/org/sign/outs#edit                                           | edit_edit_org_sign_out                          |
| GET    | /sign/out(.:format)                                                                                    | edit/org/sign/outs#show                                           | edit_org_sign_out                               |
| POST   | /sign/out(.:format)                                                                                    | edit/org/sign/outs#create                                         | —                                               |
| GET    | /sign/out/completion(.:format)                                                                         | edit/org/sign/outs#show                                           | edit_org_sign_out_completion                    |
| POST   | /publishing/info/app/entries/:entry_id/publications(.:format)                                          | edit/org/publishing/info/app/entries/publications#create          | edit_org_publishing_info_app_entry_publications |
| DELETE | /publishing/info/app/entries/:entry_id/publications/:id(.:format)                                      | edit/org/publishing/info/app/entries/publications#destroy         | edit_org_publishing_info_app_entry_publication  |
| DELETE | /publishing/info/app/entries/:entry_id/archive(.:format)                                               | edit/org/publishing/info/app/entries/archives#destroy             | edit_org_publishing_info_app_entry_archive      |
| POST   | /publishing/info/app/entries/:entry_id/archive(.:format)                                               | edit/org/publishing/info/app/entries/archives#create              | —                                               |
| GET    | /publishing/info/app/entries(.:format)                                                                 | edit/org/publishing/info/app/entries#index                        | edit_org_publishing_info_app_entries            |
| POST   | /publishing/info/app/entries(.:format)                                                                 | edit/org/publishing/info/app/entries#create                       | —                                               |
| GET    | /publishing/info/app/entries/new(.:format)                                                             | edit/org/publishing/info/app/entries#new                          | new_edit_org_publishing_info_app_entry          |
| GET    | /publishing/info/app/entries/:id/edit(.:format)                                                        | edit/org/publishing/info/app/entries#edit                         | edit_edit_org_publishing_info_app_entry         |
| GET    | /publishing/info/app/entries/:id(.:format)                                                             | edit/org/publishing/info/app/entries#show                         | edit_org_publishing_info_app_entry              |
| PATCH  | /publishing/info/app/entries/:id(.:format)                                                             | edit/org/publishing/info/app/entries#update                       | —                                               |
| PUT    | /publishing/info/app/entries/:id(.:format)                                                             | edit/org/publishing/info/app/entries#update                       | —                                               |
| POST   | /publishing/info/com/entries/:entry_id/publications(.:format)                                          | edit/org/publishing/info/com/entries/publications#create          | edit_org_publishing_info_com_entry_publications |
| DELETE | /publishing/info/com/entries/:entry_id/publications/:id(.:format)                                      | edit/org/publishing/info/com/entries/publications#destroy         | edit_org_publishing_info_com_entry_publication  |
| DELETE | /publishing/info/com/entries/:entry_id/archive(.:format)                                               | edit/org/publishing/info/com/entries/archives#destroy             | edit_org_publishing_info_com_entry_archive      |
| POST   | /publishing/info/com/entries/:entry_id/archive(.:format)                                               | edit/org/publishing/info/com/entries/archives#create              | —                                               |
| GET    | /publishing/info/com/entries(.:format)                                                                 | edit/org/publishing/info/com/entries#index                        | edit_org_publishing_info_com_entries            |
| POST   | /publishing/info/com/entries(.:format)                                                                 | edit/org/publishing/info/com/entries#create                       | —                                               |
| GET    | /publishing/info/com/entries/new(.:format)                                                             | edit/org/publishing/info/com/entries#new                          | new_edit_org_publishing_info_com_entry          |
| GET    | /publishing/info/com/entries/:id/edit(.:format)                                                        | edit/org/publishing/info/com/entries#edit                         | edit_edit_org_publishing_info_com_entry         |
| GET    | /publishing/info/com/entries/:id(.:format)                                                             | edit/org/publishing/info/com/entries#show                         | edit_org_publishing_info_com_entry              |
| PATCH  | /publishing/info/com/entries/:id(.:format)                                                             | edit/org/publishing/info/com/entries#update                       | —                                               |
| PUT    | /publishing/info/com/entries/:id(.:format)                                                             | edit/org/publishing/info/com/entries#update                       | —                                               |
| POST   | /publishing/info/org/entries/:entry_id/publications(.:format)                                          | edit/org/publishing/info/org/entries/publications#create          | edit_org_publishing_info_org_entry_publications |
| DELETE | /publishing/info/org/entries/:entry_id/publications/:id(.:format)                                      | edit/org/publishing/info/org/entries/publications#destroy         | edit_org_publishing_info_org_entry_publication  |
| DELETE | /publishing/info/org/entries/:entry_id/archive(.:format)                                               | edit/org/publishing/info/org/entries/archives#destroy             | edit_org_publishing_info_org_entry_archive      |
| POST   | /publishing/info/org/entries/:entry_id/archive(.:format)                                               | edit/org/publishing/info/org/entries/archives#create              | —                                               |
| GET    | /publishing/info/org/entries(.:format)                                                                 | edit/org/publishing/info/org/entries#index                        | edit_org_publishing_info_org_entries            |
| POST   | /publishing/info/org/entries(.:format)                                                                 | edit/org/publishing/info/org/entries#create                       | —                                               |
| GET    | /publishing/info/org/entries/new(.:format)                                                             | edit/org/publishing/info/org/entries#new                          | new_edit_org_publishing_info_org_entry          |
| GET    | /publishing/info/org/entries/:id/edit(.:format)                                                        | edit/org/publishing/info/org/entries#edit                         | edit_edit_org_publishing_info_org_entry         |
| GET    | /publishing/info/org/entries/:id(.:format)                                                             | edit/org/publishing/info/org/entries#show                         | edit_org_publishing_info_org_entry              |
| PATCH  | /publishing/info/org/entries/:id(.:format)                                                             | edit/org/publishing/info/org/entries#update                       | —                                               |
| PUT    | /publishing/info/org/entries/:id(.:format)                                                             | edit/org/publishing/info/org/entries#update                       | —                                               |
| POST   | /publishing/docs/app/entries/:entry_id/publications(.:format)                                          | edit/org/publishing/docs/app/entries/publications#create          | edit_org_publishing_docs_app_entry_publications |
| DELETE | /publishing/docs/app/entries/:entry_id/publications/:id(.:format)                                      | edit/org/publishing/docs/app/entries/publications#destroy         | edit_org_publishing_docs_app_entry_publication  |
| DELETE | /publishing/docs/app/entries/:entry_id/archive(.:format)                                               | edit/org/publishing/docs/app/entries/archives#destroy             | edit_org_publishing_docs_app_entry_archive      |
| POST   | /publishing/docs/app/entries/:entry_id/archive(.:format)                                               | edit/org/publishing/docs/app/entries/archives#create              | —                                               |
| GET    | /publishing/docs/app/entries(.:format)                                                                 | edit/org/publishing/docs/app/entries#index                        | edit_org_publishing_docs_app_entries            |
| POST   | /publishing/docs/app/entries(.:format)                                                                 | edit/org/publishing/docs/app/entries#create                       | —                                               |
| GET    | /publishing/docs/app/entries/new(.:format)                                                             | edit/org/publishing/docs/app/entries#new                          | new_edit_org_publishing_docs_app_entry          |
| GET    | /publishing/docs/app/entries/:id/edit(.:format)                                                        | edit/org/publishing/docs/app/entries#edit                         | edit_edit_org_publishing_docs_app_entry         |
| GET    | /publishing/docs/app/entries/:id(.:format)                                                             | edit/org/publishing/docs/app/entries#show                         | edit_org_publishing_docs_app_entry              |
| PATCH  | /publishing/docs/app/entries/:id(.:format)                                                             | edit/org/publishing/docs/app/entries#update                       | —                                               |
| PUT    | /publishing/docs/app/entries/:id(.:format)                                                             | edit/org/publishing/docs/app/entries#update                       | —                                               |
| POST   | /publishing/docs/com/entries/:entry_id/publications(.:format)                                          | edit/org/publishing/docs/com/entries/publications#create          | edit_org_publishing_docs_com_entry_publications |
| DELETE | /publishing/docs/com/entries/:entry_id/publications/:id(.:format)                                      | edit/org/publishing/docs/com/entries/publications#destroy         | edit_org_publishing_docs_com_entry_publication  |
| DELETE | /publishing/docs/com/entries/:entry_id/archive(.:format)                                               | edit/org/publishing/docs/com/entries/archives#destroy             | edit_org_publishing_docs_com_entry_archive      |
| POST   | /publishing/docs/com/entries/:entry_id/archive(.:format)                                               | edit/org/publishing/docs/com/entries/archives#create              | —                                               |
| GET    | /publishing/docs/com/entries(.:format)                                                                 | edit/org/publishing/docs/com/entries#index                        | edit_org_publishing_docs_com_entries            |
| POST   | /publishing/docs/com/entries(.:format)                                                                 | edit/org/publishing/docs/com/entries#create                       | —                                               |
| GET    | /publishing/docs/com/entries/new(.:format)                                                             | edit/org/publishing/docs/com/entries#new                          | new_edit_org_publishing_docs_com_entry          |
| GET    | /publishing/docs/com/entries/:id/edit(.:format)                                                        | edit/org/publishing/docs/com/entries#edit                         | edit_edit_org_publishing_docs_com_entry         |
| GET    | /publishing/docs/com/entries/:id(.:format)                                                             | edit/org/publishing/docs/com/entries#show                         | edit_org_publishing_docs_com_entry              |
| PATCH  | /publishing/docs/com/entries/:id(.:format)                                                             | edit/org/publishing/docs/com/entries#update                       | —                                               |
| PUT    | /publishing/docs/com/entries/:id(.:format)                                                             | edit/org/publishing/docs/com/entries#update                       | —                                               |
| POST   | /publishing/docs/org/entries/:entry_id/publications(.:format)                                          | edit/org/publishing/docs/org/entries/publications#create          | edit_org_publishing_docs_org_entry_publications |
| DELETE | /publishing/docs/org/entries/:entry_id/publications/:id(.:format)                                      | edit/org/publishing/docs/org/entries/publications#destroy         | edit_org_publishing_docs_org_entry_publication  |
| DELETE | /publishing/docs/org/entries/:entry_id/archive(.:format)                                               | edit/org/publishing/docs/org/entries/archives#destroy             | edit_org_publishing_docs_org_entry_archive      |
| POST   | /publishing/docs/org/entries/:entry_id/archive(.:format)                                               | edit/org/publishing/docs/org/entries/archives#create              | —                                               |
| GET    | /publishing/docs/org/entries(.:format)                                                                 | edit/org/publishing/docs/org/entries#index                        | edit_org_publishing_docs_org_entries            |
| POST   | /publishing/docs/org/entries(.:format)                                                                 | edit/org/publishing/docs/org/entries#create                       | —                                               |
| GET    | /publishing/docs/org/entries/new(.:format)                                                             | edit/org/publishing/docs/org/entries#new                          | new_edit_org_publishing_docs_org_entry          |
| GET    | /publishing/docs/org/entries/:id/edit(.:format)                                                        | edit/org/publishing/docs/org/entries#edit                         | edit_edit_org_publishing_docs_org_entry         |
| GET    | /publishing/docs/org/entries/:id(.:format)                                                             | edit/org/publishing/docs/org/entries#show                         | edit_org_publishing_docs_org_entry              |
| PATCH  | /publishing/docs/org/entries/:id(.:format)                                                             | edit/org/publishing/docs/org/entries#update                       | —                                               |
| PUT    | /publishing/docs/org/entries/:id(.:format)                                                             | edit/org/publishing/docs/org/entries#update                       | —                                               |
| POST   | /publishing/news/app/entries/:entry_id/publications(.:format)                                          | edit/org/publishing/news/app/entries/publications#create          | edit_org_publishing_news_app_entry_publications |
| DELETE | /publishing/news/app/entries/:entry_id/publications/:id(.:format)                                      | edit/org/publishing/news/app/entries/publications#destroy         | edit_org_publishing_news_app_entry_publication  |
| DELETE | /publishing/news/app/entries/:entry_id/archive(.:format)                                               | edit/org/publishing/news/app/entries/archives#destroy             | edit_org_publishing_news_app_entry_archive      |
| POST   | /publishing/news/app/entries/:entry_id/archive(.:format)                                               | edit/org/publishing/news/app/entries/archives#create              | —                                               |
| GET    | /publishing/news/app/entries(.:format)                                                                 | edit/org/publishing/news/app/entries#index                        | edit_org_publishing_news_app_entries            |
| POST   | /publishing/news/app/entries(.:format)                                                                 | edit/org/publishing/news/app/entries#create                       | —                                               |
| GET    | /publishing/news/app/entries/new(.:format)                                                             | edit/org/publishing/news/app/entries#new                          | new_edit_org_publishing_news_app_entry          |
| GET    | /publishing/news/app/entries/:id/edit(.:format)                                                        | edit/org/publishing/news/app/entries#edit                         | edit_edit_org_publishing_news_app_entry         |
| GET    | /publishing/news/app/entries/:id(.:format)                                                             | edit/org/publishing/news/app/entries#show                         | edit_org_publishing_news_app_entry              |
| PATCH  | /publishing/news/app/entries/:id(.:format)                                                             | edit/org/publishing/news/app/entries#update                       | —                                               |
| PUT    | /publishing/news/app/entries/:id(.:format)                                                             | edit/org/publishing/news/app/entries#update                       | —                                               |
| POST   | /publishing/news/com/entries/:entry_id/publications(.:format)                                          | edit/org/publishing/news/com/entries/publications#create          | edit_org_publishing_news_com_entry_publications |
| DELETE | /publishing/news/com/entries/:entry_id/publications/:id(.:format)                                      | edit/org/publishing/news/com/entries/publications#destroy         | edit_org_publishing_news_com_entry_publication  |
| DELETE | /publishing/news/com/entries/:entry_id/archive(.:format)                                               | edit/org/publishing/news/com/entries/archives#destroy             | edit_org_publishing_news_com_entry_archive      |
| POST   | /publishing/news/com/entries/:entry_id/archive(.:format)                                               | edit/org/publishing/news/com/entries/archives#create              | —                                               |
| GET    | /publishing/news/com/entries(.:format)                                                                 | edit/org/publishing/news/com/entries#index                        | edit_org_publishing_news_com_entries            |
| POST   | /publishing/news/com/entries(.:format)                                                                 | edit/org/publishing/news/com/entries#create                       | —                                               |
| GET    | /publishing/news/com/entries/new(.:format)                                                             | edit/org/publishing/news/com/entries#new                          | new_edit_org_publishing_news_com_entry          |
| GET    | /publishing/news/com/entries/:id/edit(.:format)                                                        | edit/org/publishing/news/com/entries#edit                         | edit_edit_org_publishing_news_com_entry         |
| GET    | /publishing/news/com/entries/:id(.:format)                                                             | edit/org/publishing/news/com/entries#show                         | edit_org_publishing_news_com_entry              |
| PATCH  | /publishing/news/com/entries/:id(.:format)                                                             | edit/org/publishing/news/com/entries#update                       | —                                               |
| PUT    | /publishing/news/com/entries/:id(.:format)                                                             | edit/org/publishing/news/com/entries#update                       | —                                               |
| POST   | /publishing/news/org/entries/:entry_id/publications(.:format)                                          | edit/org/publishing/news/org/entries/publications#create          | edit_org_publishing_news_org_entry_publications |
| DELETE | /publishing/news/org/entries/:entry_id/publications/:id(.:format)                                      | edit/org/publishing/news/org/entries/publications#destroy         | edit_org_publishing_news_org_entry_publication  |
| DELETE | /publishing/news/org/entries/:entry_id/archive(.:format)                                               | edit/org/publishing/news/org/entries/archives#destroy             | edit_org_publishing_news_org_entry_archive      |
| POST   | /publishing/news/org/entries/:entry_id/archive(.:format)                                               | edit/org/publishing/news/org/entries/archives#create              | —                                               |
| GET    | /publishing/news/org/entries(.:format)                                                                 | edit/org/publishing/news/org/entries#index                        | edit_org_publishing_news_org_entries            |
| POST   | /publishing/news/org/entries(.:format)                                                                 | edit/org/publishing/news/org/entries#create                       | —                                               |
| GET    | /publishing/news/org/entries/new(.:format)                                                             | edit/org/publishing/news/org/entries#new                          | new_edit_org_publishing_news_org_entry          |
| GET    | /publishing/news/org/entries/:id/edit(.:format)                                                        | edit/org/publishing/news/org/entries#edit                         | edit_edit_org_publishing_news_org_entry         |
| GET    | /publishing/news/org/entries/:id(.:format)                                                             | edit/org/publishing/news/org/entries#show                         | edit_org_publishing_news_org_entry              |
| PATCH  | /publishing/news/org/entries/:id(.:format)                                                             | edit/org/publishing/news/org/entries#update                       | —                                               |
| PUT    | /publishing/news/org/entries/:id(.:format)                                                             | edit/org/publishing/news/org/entries#update                       | —                                               |
| POST   | /publishing/help/app/entries/:entry_id/publications(.:format)                                          | edit/org/publishing/help/app/entries/publications#create          | edit_org_publishing_help_app_entry_publications |
| DELETE | /publishing/help/app/entries/:entry_id/publications/:id(.:format)                                      | edit/org/publishing/help/app/entries/publications#destroy         | edit_org_publishing_help_app_entry_publication  |
| DELETE | /publishing/help/app/entries/:entry_id/archive(.:format)                                               | edit/org/publishing/help/app/entries/archives#destroy             | edit_org_publishing_help_app_entry_archive      |
| POST   | /publishing/help/app/entries/:entry_id/archive(.:format)                                               | edit/org/publishing/help/app/entries/archives#create              | —                                               |
| GET    | /publishing/help/app/entries(.:format)                                                                 | edit/org/publishing/help/app/entries#index                        | edit_org_publishing_help_app_entries            |
| POST   | /publishing/help/app/entries(.:format)                                                                 | edit/org/publishing/help/app/entries#create                       | —                                               |
| GET    | /publishing/help/app/entries/new(.:format)                                                             | edit/org/publishing/help/app/entries#new                          | new_edit_org_publishing_help_app_entry          |
| GET    | /publishing/help/app/entries/:id/edit(.:format)                                                        | edit/org/publishing/help/app/entries#edit                         | edit_edit_org_publishing_help_app_entry         |
| GET    | /publishing/help/app/entries/:id(.:format)                                                             | edit/org/publishing/help/app/entries#show                         | edit_org_publishing_help_app_entry              |
| PATCH  | /publishing/help/app/entries/:id(.:format)                                                             | edit/org/publishing/help/app/entries#update                       | —                                               |
| PUT    | /publishing/help/app/entries/:id(.:format)                                                             | edit/org/publishing/help/app/entries#update                       | —                                               |
| POST   | /publishing/help/com/entries/:entry_id/publications(.:format)                                          | edit/org/publishing/help/com/entries/publications#create          | edit_org_publishing_help_com_entry_publications |
| DELETE | /publishing/help/com/entries/:entry_id/publications/:id(.:format)                                      | edit/org/publishing/help/com/entries/publications#destroy         | edit_org_publishing_help_com_entry_publication  |
| DELETE | /publishing/help/com/entries/:entry_id/archive(.:format)                                               | edit/org/publishing/help/com/entries/archives#destroy             | edit_org_publishing_help_com_entry_archive      |
| POST   | /publishing/help/com/entries/:entry_id/archive(.:format)                                               | edit/org/publishing/help/com/entries/archives#create              | —                                               |
| GET    | /publishing/help/com/entries(.:format)                                                                 | edit/org/publishing/help/com/entries#index                        | edit_org_publishing_help_com_entries            |
| POST   | /publishing/help/com/entries(.:format)                                                                 | edit/org/publishing/help/com/entries#create                       | —                                               |
| GET    | /publishing/help/com/entries/new(.:format)                                                             | edit/org/publishing/help/com/entries#new                          | new_edit_org_publishing_help_com_entry          |
| GET    | /publishing/help/com/entries/:id/edit(.:format)                                                        | edit/org/publishing/help/com/entries#edit                         | edit_edit_org_publishing_help_com_entry         |
| GET    | /publishing/help/com/entries/:id(.:format)                                                             | edit/org/publishing/help/com/entries#show                         | edit_org_publishing_help_com_entry              |
| PATCH  | /publishing/help/com/entries/:id(.:format)                                                             | edit/org/publishing/help/com/entries#update                       | —                                               |
| PUT    | /publishing/help/com/entries/:id(.:format)                                                             | edit/org/publishing/help/com/entries#update                       | —                                               |
| POST   | /publishing/help/org/entries/:entry_id/publications(.:format)                                          | edit/org/publishing/help/org/entries/publications#create          | edit_org_publishing_help_org_entry_publications |
| DELETE | /publishing/help/org/entries/:entry_id/publications/:id(.:format)                                      | edit/org/publishing/help/org/entries/publications#destroy         | edit_org_publishing_help_org_entry_publication  |
| DELETE | /publishing/help/org/entries/:entry_id/archive(.:format)                                               | edit/org/publishing/help/org/entries/archives#destroy             | edit_org_publishing_help_org_entry_archive      |
| POST   | /publishing/help/org/entries/:entry_id/archive(.:format)                                               | edit/org/publishing/help/org/entries/archives#create              | —                                               |
| GET    | /publishing/help/org/entries(.:format)                                                                 | edit/org/publishing/help/org/entries#index                        | edit_org_publishing_help_org_entries            |
| POST   | /publishing/help/org/entries(.:format)                                                                 | edit/org/publishing/help/org/entries#create                       | —                                               |
| GET    | /publishing/help/org/entries/new(.:format)                                                             | edit/org/publishing/help/org/entries#new                          | new_edit_org_publishing_help_org_entry          |
| GET    | /publishing/help/org/entries/:id/edit(.:format)                                                        | edit/org/publishing/help/org/entries#edit                         | edit_edit_org_publishing_help_org_entry         |
| GET    | /publishing/help/org/entries/:id(.:format)                                                             | edit/org/publishing/help/org/entries#show                         | edit_org_publishing_help_org_entry              |
| PATCH  | /publishing/help/org/entries/:id(.:format)                                                             | edit/org/publishing/help/org/entries#update                       | —                                               |
| PUT    | /publishing/help/org/entries/:id(.:format)                                                             | edit/org/publishing/help/org/entries#update                       | —                                               |

| POST | /api/v0/publishing/:surface/:audience/entries/:entry_entry_ref/publications(.:format) |
edit/org/api/v0/publishing/publications#create | — | | DELETE |
/api/v0/publishing/:surface/:audience/entries/:entry_entry_ref/publications/:publication_ref(.:format) |
edit/org/api/v0/publishing/publications#destroy | — | | DELETE |
/api/v0/publishing/:surface/:audience/entries/:entry_entry_ref/archive(.:format) |
edit/org/api/v0/publishing/archives#destroy | — | | POST |
/api/v0/publishing/:surface/:audience/entries/:entry_entry_ref/archive(.:format) |
edit/org/api/v0/publishing/archives#create | — | | GET |
/api/v0/publishing/:surface/:audience/entries(.:format) | edit/org/api/v0/publishing/entries#index |
— | | POST | /api/v0/publishing/:surface/:audience/entries(.:format) |
edit/org/api/v0/publishing/entries#create | — | | GET |
/api/v0/publishing/:surface/:audience/entries/:entry_ref(.:format) |
edit/org/api/v0/publishing/entries#show | — | | PATCH |
/api/v0/publishing/:surface/:audience/entries/:entry_ref(.:format) |
edit/org/api/v0/publishing/entries#update | — | | PUT |
/api/v0/publishing/:surface/:audience/entries/:entry_ref(.:format) |
edit/org/api/v0/publishing/entries#update | — |

### Mission operator-tool host constraint (25 entries)

| Verb   | Path                                                           | Target                                      | Route name                  |
| ------ | -------------------------------------------------------------- | ------------------------------------------- | --------------------------- |
| MOUNT  | /                                                              | MissionControl::Jobs::Engine                | mission_control_jobs        |
| DELETE | /applications/:application_id/queues/:queue_id/pause(.:format) | mission_control/jobs/queues/pauses#destroy  | application_queue_pause     |
| POST   | /applications/:application_id/queues/:queue_id/pause(.:format) | mission_control/jobs/queues/pauses#create   | —                           |
| GET    | /applications/:application_id/queues(.:format)                 | mission_control/jobs/queues#index           | application_queues          |
| GET    | /applications/:application_id/queues/:id(.:format)             | mission_control/jobs/queues#show            | application_queue           |
| POST   | /applications/:application_id/jobs/:job_id/retry(.:format)     | mission_control/jobs/retries#create         | application_job_retry       |
| POST   | /applications/:application_id/jobs/:job_id/discard(.:format)   | mission_control/jobs/discards#create        | application_job_discard     |
| POST   | /applications/:application_id/jobs/:job_id/dispatch(.:format)  | mission_control/jobs/dispatches#create      | application_job_dispatch    |
| POST   | /applications/:application_id/jobs/bulk_retries(.:format)      | mission_control/jobs/bulk_retries#create    | application_bulk_retries    |
| POST   | /applications/:application_id/jobs/bulk_discards(.:format)     | mission_control/jobs/bulk_discards#create   | application_bulk_discards   |
| GET    | /applications/:application_id/jobs/:id(.:format)               | mission_control/jobs/jobs#show              | application_job             |
| GET    | /applications/:application_id/:status/jobs(.:format)           | mission_control/jobs/jobs#index             | application_jobs            |
| GET    | /applications/:application_id/workers(.:format)                | mission_control/jobs/workers#index          | application_workers         |
| GET    | /applications/:application_id/workers/:id(.:format)            | mission_control/jobs/workers#show           | application_worker          |
| GET    | /applications/:application_id/recurring_tasks(.:format)        | mission_control/jobs/recurring_tasks#index  | application_recurring_tasks |
| GET    | /applications/:application_id/recurring_tasks/:id(.:format)    | mission_control/jobs/recurring_tasks#show   | application_recurring_task  |
| PATCH  | /applications/:application_id/recurring_tasks/:id(.:format)    | mission_control/jobs/recurring_tasks#update | —                           |
| PUT    | /applications/:application_id/recurring_tasks/:id(.:format)    | mission_control/jobs/recurring_tasks#update | —                           |
| GET    | /applications/:application_id/batches(.:format)                | mission_control/jobs/batches#index          | application_batches         |
| GET    | /applications/:application_id/batches/:id(.:format)            | mission_control/jobs/batches#show           | application_batch           |
| GET    | /queues(.:format)                                              | mission_control/jobs/queues#index           | queues                      |
| GET    | /queues/:id(.:format)                                          | mission_control/jobs/queues#show            | queue                       |
| GET    | /jobs/:id(.:format)                                            | mission_control/jobs/jobs#show              | job                         |
| GET    | /:status/jobs(.:format)                                        | mission_control/jobs/jobs#index             | jobs                        |
| GET    | /                                                              | mission_control/jobs/queues#index           | root                        |

### Flipper operator-tool host constraint (1 entries)

| Verb  | Path | Target                                 | Route name |
| ----- | ---- | -------------------------------------- | ---------- |
| MOUNT | /    | Rack::Auth::Basic wrapping Flipper::UI | flipper    |

### Blazer operator-tool host constraint (32 entries)

| Verb   | Path                              | Target                    | Route name        |
| ------ | --------------------------------- | ------------------------- | ----------------- |
| MOUNT  | /                                 | Blazer::Engine            | blazer            |
| POST   | /queries/run(.:format)            | blazer/queries#run        | run_queries       |
| POST   | /queries/cancel(.:format)         | blazer/queries#cancel     | cancel_queries    |
| POST   | /queries/:id/refresh(.:format)    | blazer/queries#refresh    | refresh_query     |
| GET    | /queries/tables(.:format)         | blazer/queries#tables     | tables_queries    |
| GET    | /queries/schema(.:format)         | blazer/queries#schema     | schema_queries    |
| GET    | /queries/docs(.:format)           | blazer/queries#docs       | docs_queries      |
| GET    | /queries(.:format)                | blazer/queries#index      | queries           |
| POST   | /queries(.:format)                | blazer/queries#create     | —                 |
| GET    | /queries/new(.:format)            | blazer/queries#new        | new_query         |
| GET    | /queries/:id/edit(.:format)       | blazer/queries#edit       | edit_query        |
| GET    | /queries/:id(.:format)            | blazer/queries#show       | query             |
| PATCH  | /queries/:id(.:format)            | blazer/queries#update     | —                 |
| PUT    | /queries/:id(.:format)            | blazer/queries#update     | —                 |
| DELETE | /queries/:id(.:format)            | blazer/queries#destroy    | —                 |
| GET    | /checks/:id/run(.:format)         | blazer/checks#run         | run_check         |
| GET    | /checks(.:format)                 | blazer/checks#index       | checks            |
| POST   | /checks(.:format)                 | blazer/checks#create      | —                 |
| GET    | /checks/new(.:format)             | blazer/checks#new         | new_check         |
| GET    | /checks/:id/edit(.:format)        | blazer/checks#edit        | edit_check        |
| PATCH  | /checks/:id(.:format)             | blazer/checks#update      | check             |
| PUT    | /checks/:id(.:format)             | blazer/checks#update      | —                 |
| DELETE | /checks/:id(.:format)             | blazer/checks#destroy     | —                 |
| POST   | /dashboards/:id/refresh(.:format) | blazer/dashboards#refresh | refresh_dashboard |
| POST   | /dashboards(.:format)             | blazer/dashboards#create  | dashboards        |
| GET    | /dashboards/new(.:format)         | blazer/dashboards#new     | new_dashboard     |
| GET    | /dashboards/:id/edit(.:format)    | blazer/dashboards#edit    | edit_dashboard    |
| GET    | /dashboards/:id(.:format)         | blazer/dashboards#show    | dashboard         |
| PATCH  | /dashboards/:id(.:format)         | blazer/dashboards#update  | —                 |
| PUT    | /dashboards/:id(.:format)         | blazer/dashboards#update  | —                 |
| DELETE | /dashboards/:id(.:format)         | blazer/dashboards#destroy | —                 |
| GET    | /                                 | blazer/queries#home       | root              |

### PgHero operator-tool host constraint (26 entries)

| Verb  | Path                                             | Target                                 | Route name                |
| ----- | ------------------------------------------------ | -------------------------------------- | ------------------------- |
| MOUNT | /                                                | PgHero::Engine                         | pghero                    |
| GET   | (/:database)/space(.:format)                     | pg_hero/home#space                     | space                     |
| GET   | (/:database)/space/:relation(.:format)           | pg_hero/home#relation_space            | relation_space            |
| GET   | (/:database)/index_bloat(.:format)               | pg_hero/home#index_bloat               | index_bloat               |
| GET   | (/:database)/live_queries(.:format)              | pg_hero/home#live_queries              | live_queries              |
| GET   | (/:database)/queries(.:format)                   | pg_hero/home#queries                   | queries                   |
| GET   | (/:database)/queries/:query_hash(.:format)       | pg_hero/home#show_query                | show_query                |
| GET   | (/:database)/system(.:format)                    | pg_hero/home#system                    | system                    |
| GET   | (/:database)/cpu_usage(.:format)                 | pg_hero/home#cpu_usage                 | cpu_usage                 |
| GET   | (/:database)/connection_stats(.:format)          | pg_hero/home#connection_stats          | connection_stats          |
| GET   | (/:database)/replication_lag_stats(.:format)     | pg_hero/home#replication_lag_stats     | replication_lag_stats     |
| GET   | (/:database)/load_stats(.:format)                | pg_hero/home#load_stats                | load_stats                |
| GET   | (/:database)/free_space_stats(.:format)          | pg_hero/home#free_space_stats          | free_space_stats          |
| GET   | (/:database)/explain(.:format)                   | pg_hero/home#explain                   | explain                   |
| GET   | (/:database)/tune(.:format)                      | pg_hero/home#tune                      | tune                      |
| GET   | (/:database)/connections(.:format)               | pg_hero/home#connections               | connections               |
| GET   | (/:database)/maintenance(.:format)               | pg_hero/home#maintenance               | maintenance               |
| POST  | (/:database)/kill(.:format)                      | pg_hero/home#kill                      | kill                      |
| POST  | (/:database)/kill_long_running_queries(.:format) | pg_hero/home#kill_long_running_queries | kill_long_running_queries |
| POST  | (/:database)/kill_all(.:format)                  | pg_hero/home#kill_all                  | kill_all                  |
| POST  | (/:database)/enable_query_stats(.:format)        | pg_hero/home#enable_query_stats        | enable_query_stats        |
| POST  | (/:database)/explain(.:format)                   | pg_hero/home#explain                   | —                         |
| POST  | (/:database)/reset_query_stats(.:format)         | pg_hero/home#reset_query_stats         | reset_query_stats         |
| GET   | (/:database)/system_stats(.:format)              | redirect(301, system)                  | system_stats              |
| GET   | (/:database)/query_stats(.:format)               | redirect(301, queries)                 | query_stats               |
| GET   | /(:database)(.:format)                           | pg_hero/home#index                     | root                      |

### Swagger operator-tool host constraint (2 entries)

| Verb  | Path     | Target             | Route name |
| ----- | -------- | ------------------ | ---------- |
| MOUNT | /openapi | Rswag::Api::Engine | rswag_api  |
| MOUNT | /        | Rswag::Ui::Engine  | rswag_ui   |

## Conditional route source not emitted by this command

config/routes/coverband.rb:9 declares a host constraint using ENV key PRIVATE_COVERBAND_URL and
fixed aliases, but the route command ran outside the request-serving process gate that loads
Coverband. No Coverband mount row was present; it has zero entries in this command output.

Rswag API and UI each have a mount row under the Swagger host constraint. Both engine sections
reported no internal routes.

### Unknown-host fallback (unconstrained, 1 entry)

| Verb | Path | Target             | Route name |
| ---- | ---- | ------------------ | ---------- |
| GET  | /    | unknown_hosts#show | —          |

The current output contains no Action Mailbox, Active Storage, Turbo navigation, or Inertia DevTools
routes. The only hostless application route is the unknown-host fallback. No framework-generated
hostless development routes appeared.

## Controller namespace ownership

| Namespace                                | Classification                         | Current evidence                                                                                                                                       |
| ---------------------------------------- | -------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| docs                                     | OWN                                    | 33 controller files; 11 routes per app/com/org host constraint. README.md:11 and 166-169 lists Docs among public content surfaces for those audiences. |
| news                                     | OWN                                    | 33 controller files; 11 routes per app/com/org host constraint. README.md:11 and 166-169 lists News among public content surfaces for those audiences. |
| help                                     | OWN                                    | 33 controller files; 11 routes per app/com/org host constraint. README.md:11 and 166-169 lists Help among public content surfaces for those audiences. |
| info                                     | OWN                                    | 33 controller files; 11 routes per app/com/org host constraint. README.md:11 and 166-169 lists Info among public content surfaces for those audiences. |
| edit                                     | OWN                                    | 57 controller files; 163 routes under the org host constraint. README.md:10-11 identifies Edit as the staff publishing surface.                        |
| unknown_hosts                            | OWN infrastructure boundary            | One unconstrained root route to the unknown-host handler.                                                                                              |
| shared concerns                          | OWN shared code, not a route namespace | 68 controller concerns; no direct route namespace.                                                                                                     |
| ApplicationController                    | OWN shared base, not a route namespace | Top-level controller file; no direct route target.                                                                                                     |
| Mission Control Jobs                     | OWN operator tool                      | One engine mount and 24 engine actions under its host constraint.                                                                                      |
| Flipper                                  | OWN operator tool                      | One Rack mount under its host constraint.                                                                                                              |
| Blazer                                   | OWN operator tool                      | One engine mount and 31 engine actions under its host constraint.                                                                                      |
| PgHero                                   | OWN operator tool                      | One engine mount and 25 engine actions under its host constraint.                                                                                      |
| Rswag API/UI                             | OWN operator tool                      | Two engine mounts under one host constraint; neither engine currently emits internal routes.                                                           |
| Coverband                                | OWN operator tool, conditional         | Source constraint remains, but this route command emitted no mount.                                                                                    |
| auth, base, core, palm, tech, visa, warp | FOREIGN/RETIRED                        | Controller namespace roots are absent from the current worktree; no route rows use them.                                                               |

Counts: 296 application controller actions, 6 operator-tool mounts, and 80 operator-tool engine
actions, for 382 emitted route entries total.

### Operator-tool routes with hardcoded canonical hosts

These current source lines were not edited by the surface hard reset. The route files already had
uncommitted differences from HEAD before the task; the host line changes in the cumulative diff are
part of that inherited worktree state:

- `config/routes/mission.rb:7`
- `config/routes/flipper.rb:6`
- `config/routes/blazer.rb:6`
- `config/routes/pghero.rb:6`
- `config/routes/swagger.rb:6`
- `config/routes/coverband.rb:9` (conditional; no mount emitted by the final route command)

## 2. Removal summary

The foreign controller trees and their local route files, views, helpers, controller tests, and dead
dependents were removed. The controller cleanup also removed concerns with no remaining caller. Dead
policies, operations, services, values, adapters, jobs, and support/tests were removed in repeated
caller scans.

Current cumulative tracked deletion totals relative to HEAD (including pre-existing dirty work):

| Area                                | Deleted files |
| ----------------------------------- | ------------: |
| Controllers and controller concerns |           780 |
| Views                               |           114 |
| Helpers                             |             6 |
| Policies                            |           317 |
| Operations                          |           126 |
| Services                            |           106 |
| Values                              |            70 |
| Adapters                            |            30 |
| Jobs                                |             6 |
| Route files                         |             9 |
| Tests                               |         1,007 |
| Model or migration files            |             0 |

The two locale files were edited to remove retired-surface translation entries; no locale files were
deleted. Current URL readers under `app/`, `config/`, and `lib/` contain no references to the
retired URL keys listed below. The tracked `.env.container.devcontainer` template removed these URL
keys:

`PRIVATE_AUTH_CORPORATE_URL, PRIVATE_AUTH_SERVICE_URL, PRIVATE_AUTH_STAFF_URL, PRIVATE_BASE_CORPORATE_URL, PRIVATE_BASE_DEVELOPER_URL, PRIVATE_BASE_NETWORK_URL, PRIVATE_BASE_SERVICE_URL, PRIVATE_BASE_STAFF_URL, PRIVATE_CORE_CORPORATE_URL, PRIVATE_CORE_DEVELOPER_URL, PRIVATE_CORE_SERVICE_URL, PRIVATE_CORE_STAFF_URL, PRIVATE_GUID_SERVICE_URL, PRIVATE_PALM_SERVICE_URL, PRIVATE_PERFORMANCE_URL, PRIVATE_TECH_STAFF_URL, PRIVATE_VISA_CORPORATE_URL, PRIVATE_VISA_SERVICE_URL, PRIVATE_VISA_STAFF_URL, PUBLIC_AUTH_CORPORATE_URL, PUBLIC_BASE_DEVELOPER_URL, PUBLIC_BLAZER_URL, PUBLIC_CORE_CORPORATE_URL, PUBLIC_CORE_DEVELOPER_URL, PUBLIC_CORE_SERVICE_URL, PUBLIC_CORE_STAFF_URL, PUBLIC_COVERBAND_URL, PUBLIC_EDGE_CORPORATE_URL, PUBLIC_EDGE_SERVICE_URL, PUBLIC_EDGE_STAFF_URL, PUBLIC_FLIPPER_URL, PUBLIC_GUID_SERVICE_URL, PUBLIC_MISSION_URL, PUBLIC_PALM_SERVICE_URL, PUBLIC_PERFORMANCE_URL, PUBLIC_PGHERO_URL, PUBLIC_STATUS_URL, PUBLIC_SWAGGER_URL, PUBLIC_TECH_STAFF_URL, PUBLIC_VISA_CORPORATE_URL, PUBLIC_WARP_CORPORATE_URL, PUBLIC_WARP_SERVICE_URL, PUBLIC_WARP_STAFF_URL`

The current ignored local `.env` and `.env.local` key inventories contain no retired URL keys.
Compose interpolation changes in the cumulative diff remove these local port-variable names (not URL
variables):
`ALLOY_OTLP_HTTP_HOST_PORT, CLOUDFLARED_EDGE_TOKEN, FAKECLOUD_HOST_PORT, GRAFANA_HOST_PORT, POSTGRESQL_PRIMARY_HOST_PORT, POSTGRESQL_REPLICA_HOST_PORT, VALKEY_CACHE_HOST_PORT, VALKEY_HOST_PORT, VALKEY_KVS_HOST_PORT`.
No removed URL assignment was found in Compose.

The `.github` filesystem mount is currently read-only (`findmnt` reports the `ro` option), which
prevented removing the retired URL variable names from `.github/workflows/ci.yml`. It still contains
these names (values omitted):

`PRIVATE_AUTH_CORPORATE_URL, PRIVATE_AUTH_SERVICE_URL, PRIVATE_AUTH_STAFF_URL, PRIVATE_BASE_CORPORATE_URL, PRIVATE_BASE_DEVELOPER_URL, PRIVATE_BASE_NETWORK_URL, PRIVATE_BASE_SERVICE_URL, PRIVATE_BASE_STAFF_URL, PRIVATE_CORE_CORPORATE_URL, PRIVATE_CORE_DEVELOPER_URL, PRIVATE_CORE_SERVICE_URL, PRIVATE_CORE_STAFF_URL, PRIVATE_PALM_SERVICE_URL, PRIVATE_PERFORMANCE_URL, PRIVATE_TECH_STAFF_URL, PUBLIC_AUTH_CORPORATE_URL, PUBLIC_BASE_DEVELOPER_URL, PUBLIC_BLAZER_URL, PUBLIC_CORE_CORPORATE_URL, PUBLIC_CORE_DEVELOPER_URL, PUBLIC_CORE_SERVICE_URL, PUBLIC_CORE_STAFF_URL, PUBLIC_COVERBAND_URL, PUBLIC_EDGE_CORPORATE_URL, PUBLIC_EDGE_SERVICE_URL, PUBLIC_EDGE_STAFF_URL, PUBLIC_FLIPPER_URL, PUBLIC_GUID_SERVICE_URL, PUBLIC_MISSION_URL, PUBLIC_PALM_SERVICE_URL, PUBLIC_PERFORMANCE_URL, PUBLIC_PGHERO_URL, PUBLIC_STATUS_URL, PUBLIC_SWAGGER_URL, PUBLIC_TECH_STAFF_URL, PUBLIC_WARP_CORPORATE_URL, PUBLIC_WARP_SERVICE_URL, PUBLIC_WARP_STAFF_URL`

No workflow changes were written. Dated handoff and backlog records retain some old URL names as
historical snapshots; current application/config/library readers are clean. The Rails Performance
backlog entry was marked as completed historical work. Current Press surface and URL documentation
was updated, including README.md and `docs/operations/press-surface-url-dependencies.md`.

## 3. Abstract Record database/model report

The inventory below scans 922 model source files (765 concrete application model classes), 688
current non-model runtime Ruby files, and 1,433 test files. For every concrete model with a static
non-model runtime reference, it lists one caller example. It lists model/test-only models and models
with no static reference separately under each abstract Record database.

Status summary: all 22 `*Record` writer database groups below have at least one static production
caller and classify **USED**. Nine `rp_*` connection keys are statically referenced but absent from
`config/database.yml`: `rp_base_app`, `rp_base_org`, `rp_core_app`, `rp_core_org`, `rp_edit_org`,
`rp_palm_app`, `rp_tech_org`, `rp_warp_app`, and `rp_warp_org`. `ApplicationRecord`/`primary` and
`SearchRecord`/`search` classify **UNUSED** by direct concrete-model ownership. `queue` and
`storage` have no app-owned abstract `*Record` class and are outside this scan.

The per-model lists below are static source results and may miss constantization, reflection, or
SQL-only use. Review them before any model/database deletion.

# Refreshed AbstractRecord model/database report

## Method and limits

No database was connected to or queried. Current model inventory: 922 model source files and 765
concrete application model classes. The only model diffs are `application_record.rb` and
`concerns/rp_principal.rb`; neither changes model inheritance or associations. Abstract Record
writer database keys were read from `connects_to` declarations and checked by key name against
`config/database.yml`; database configuration values were not read or printed. Nine `rp_*` writer
keys currently have no matching key in `config/database.yml`, which is called out below.

Runtime references were rescanned from 688 current Ruby files under `app` (excluding `app/models`),
`lib`, and `config`; tests and docs are excluded from runtime callers. Current tests were scanned in
1433 Ruby files under `test`. Each runtime example gives its enclosing Ruby method, path, and line;
`class/module body` means an eager constant reference with no enclosing method. Model associations
and source references plus test references determine model/test-only status.

This is a static reference inventory. It may miss dynamic `constantize`/`safe_constantize` targets,
class names held in arbitrary strings, table-name dispatch, SQL-only usage, and reflection-driven
behavior. Short unqualified constant names are accepted only when unique among the concrete model
classes; lines should be checked before any model/database deletion. Replica keys share their writer
database classification.

Status rule: `USED` means at least one concrete model has a non-model production Ruby caller;
`ONLY-VIA-MODELS` means no runtime caller was found but a model association/source or test reference
exists; `UNUSED` means no static runtime, model, association, or test reference was found. Database
status is `USED` if any concrete model is runtime-referenced, `ONLY-VIA-MODELS` if none are
runtime-referenced but some are model/test-only, otherwise `UNUSED`.

## Database summary

| Database key  | Abstract Record    | Config key  | Status   |                                 Concrete model counts |
| ------------- | ------------------ | ----------- | -------- | ----------------------------------------------------: |
| `app_setting` | `AppSettingRecord` | **PRESENT** | **USED** |    29: 23 runtime, 6 model/test-only, 0 no static ref |
| `app_signal`  | `AppSignalRecord`  | **PRESENT** | **USED** |      2: 1 runtime, 1 model/test-only, 0 no static ref |
| `app_zenith`  | `AppZenithRecord`  | **PRESENT** | **USED** |  114: 60 runtime, 53 model/test-only, 1 no static ref |
| `avatar`      | `AvatarRecord`     | **PRESENT** | **USED** |   45: 19 runtime, 26 model/test-only, 0 no static ref |
| `chronicle`   | `ChronicleRecord`  | **PRESENT** | **USED** |    22: 21 runtime, 1 model/test-only, 0 no static ref |
| `com_setting` | `ComSettingRecord` | **PRESENT** | **USED** |    29: 27 runtime, 2 model/test-only, 0 no static ref |
| `occurrence`  | `OccurrenceRecord` | **PRESENT** | **USED** |   52: 13 runtime, 39 model/test-only, 0 no static ref |
| `op_base_app` | `OpBaseAppRecord`  | **PRESENT** | **USED** |   65: 32 runtime, 31 model/test-only, 2 no static ref |
| `op_base_org` | `OpBaseOrgRecord`  | **PRESENT** | **USED** |   53: 25 runtime, 27 model/test-only, 1 no static ref |
| `org_setting` | `OrgSettingRecord` | **PRESENT** | **USED** |    29: 23 runtime, 6 model/test-only, 0 no static ref |
| `org_signal`  | `OrgSignalRecord`  | **PRESENT** | **USED** |      2: 1 runtime, 1 model/test-only, 0 no static ref |
| `org_zenith`  | `OrgZenithRecord`  | **PRESENT** | **USED** |   97: 52 runtime, 44 model/test-only, 1 no static ref |
| `publishing`  | `PublishingRecord` | **PRESENT** | **USED** | 157: 12 runtime, 145 model/test-only, 0 no static ref |
| `rp_base_app` | `RpBaseAppRecord`  | **MISSING** | **USED** |     13: 8 runtime, 4 model/test-only, 1 no static ref |
| `rp_base_org` | `RpBaseOrgRecord`  | **MISSING** | **USED** |     14: 8 runtime, 5 model/test-only, 1 no static ref |
| `rp_core_app` | `RpCoreAppRecord`  | **MISSING** | **USED** |      6: 1 runtime, 4 model/test-only, 1 no static ref |
| `rp_core_org` | `RpCoreOrgRecord`  | **MISSING** | **USED** |      6: 1 runtime, 4 model/test-only, 1 no static ref |
| `rp_edit_org` | `RpEditOrgRecord`  | **MISSING** | **USED** |      6: 1 runtime, 4 model/test-only, 1 no static ref |
| `rp_palm_app` | `RpPalmAppRecord`  | **MISSING** | **USED** |      6: 1 runtime, 4 model/test-only, 1 no static ref |
| `rp_tech_org` | `RpTechOrgRecord`  | **MISSING** | **USED** |      6: 1 runtime, 4 model/test-only, 1 no static ref |
| `rp_warp_app` | `RpWarpAppRecord`  | **MISSING** | **USED** |      6: 1 runtime, 4 model/test-only, 1 no static ref |
| `rp_warp_org` | `RpWarpOrgRecord`  | **MISSING** | **USED** |      6: 1 runtime, 4 model/test-only, 1 no static ref |

Writer keys absent from `config/database.yml`: `rp_base_app`, `rp_base_org`, `rp_core_app`,
`rp_core_org`, `rp_edit_org`, `rp_palm_app`, `rp_tech_org`, `rp_warp_app`, `rp_warp_org`. Statuses
below reflect static source references to the corresponding `connects_to` declarations.

## `app_setting` — `AppSettingRecord` — **USED**

29 concrete models: 23 runtime-referenced, 6 model/test-only, 0 unreferenced.

Runtime-referenced models and one caller example each:

- `AppPreference` — `anonymous_preference_claim_shape?` in
  `app/controllers/concerns/preference_base.rb:475`
- `AppPreferenceCookie` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:49`
- `AppPreferenceCurrency` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:70`
- `AppPreferenceCurrencyOption` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:58`
- `AppPreferenceDateFormat` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:71`
- `AppPreferenceDateFormatOption` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:59`
- `AppPreferenceDensity` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:74`
- `AppPreferenceDensityOption` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:62`
- `AppPreferenceLanguage` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:67`
- `AppPreferenceLanguageOption` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:55`
- `AppPreferenceMotion` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:73`
- `AppPreferenceMotionOption` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:61`
- `AppPreferencePageSize` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:75`
- `AppPreferencePageSizeOption` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:63`
- `AppPreferenceRegion` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:68`
- `AppPreferenceRegionOption` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:56`
- `AppPreferenceStatus` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:48`
- `AppPreferenceTheme` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:69`
- `AppPreferenceThemeOption` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:57`
- `AppPreferenceTimeFormat` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:72`
- `AppPreferenceTimeFormatOption` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:60`
- `AppPreferenceTimezone` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:66`
- `AppPreferenceTimezoneOption` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:54`

Models referenced only through model associations/model source and/or tests:

`AppPreferenceAdultContentGate`, `AppPreferenceAdultContentGateOption`,
`AppPreferenceBrowserBinding`, `AppPreferenceConsentReceipt`, `AppPreferenceWebPush`,
`AppPreferenceWebPushOption`

## `app_signal` — `AppSignalRecord` — **USED**

2 concrete models: 1 runtime-referenced, 1 model/test-only, 0 unreferenced.

Runtime-referenced models and one caller example each:

- `ClientNotificationRecord` — `purge_client` in
  `app/services/retention_cross_database_child_purge.rb:52`

Models referenced only through model associations/model source and/or tests:

`MemberNotification`

## `app_zenith` — `AppZenithRecord` — **USED**

114 concrete models: 60 runtime-referenced, 53 model/test-only, 1 unreferenced.

Runtime-referenced models and one caller example each:

- `AppEnforcementAppeal` — `class/module body` in `app/jobs/enforcement_reconciliation_job.rb:19`
- `AppEnforcementCase` — `class/module body` in `app/jobs/enforcement_expiry_job.rb:12`
- `AppIdentityAuthenticationEvent` — `class/module body` in
  `app/jobs/op_identity_event_delivery_job.rb:9`
- `Client` — `selected_image` in `app/adapters/avatar_authority_client.rb:78`
- `ClientAuthorityLock` — `call` in `app/operations/client_persona_creator.rb:37`
- `ClientContactAuditOutbox` — `perform` in `app/jobs/contact_audit_delivery_job.rb:14`
- `ClientEmail` — `class/module body` in `app/jobs/retention_purge_job.rb:41`
- `ClientEmailStatus` — `class/module body` in `app/policies/auth_method_guard.rb:6`
- `ClientEnforcementRecoveryCeremony` — `validate_recovery_pair!` in
  `app/operations/enforcement_case_end_operation.rb:146`
- `ClientExternalIdentity` — `context_for` in `app/jobs/social_audit_delivery_job.rb:64`
- `ClientIdentity` — `call` in `app/operations/client_persona_creator.rb:40`
- `ClientIdentityState` — `validate_identity!` in `app/operations/client_persona_creator.rb:78`
- `ClientPasskey` — `class/module body` in `app/jobs/retention_purge_job.rb:42`
- `ClientPasskeyAuditOutbox` — `class/module body` in `app/jobs/passkey_audit_delivery_job.rb:8`
- `ClientPasskeyStatus` — `verify_sign_up_registration!` in
  `app/operations/client_secret_passkey_reservation_issuer.rb:235`
- `ClientPersona` — `class/module body` in `app/operations/client_persona_creator.rb:4`
- `ClientPersonaAuthorityCutover` — `class/module body` in
  `app/queries/authority_owner_migration_inventory.rb:93`
- `ClientPersonaLifecycle` — `call` in `app/operations/client_persona_creator.rb:51`
- `ClientPersonaOwnership` — `call` in `app/operations/client_persona_creator.rb:55`
- `ClientPreference` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:143`
- `ClientPreferenceCurrency` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:161`
- `ClientPreferenceCurrencyOption` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:149`
- `ClientPreferenceDateFormat` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:162`
- `ClientPreferenceDateFormatOption` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:150`
- `ClientPreferenceDensity` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:165`
- `ClientPreferenceDensityOption` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:153`
- `ClientPreferenceLanguage` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:158`
- `ClientPreferenceLanguageOption` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:146`
- `ClientPreferenceMotion` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:164`
- `ClientPreferenceMotionOption` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:152`
- `ClientPreferencePageSize` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:166`
- `ClientPreferencePageSizeOption` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:154`
- `ClientPreferenceRegion` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:159`
- `ClientPreferenceRegionOption` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:147`
- `ClientPreferenceTheme` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:160`
- `ClientPreferenceThemeOption` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:148`
- `ClientPreferenceTimeFormat` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:163`
- `ClientPreferenceTimeFormatOption` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:151`
- `ClientPreferenceTimezone` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:157`
- `ClientPreferenceTimezoneOption` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:145`
- `ClientPrivacyRequest` — `class/module body` in `app/jobs/retention_purge_job.rb:35`
- `ClientProcessorErasureNotification` — `notification_class` in
  `app/consumers/processor_erasure_notification_receipt_consumer.rb:40`
- `ClientRetentionHold` — `class/module body` in `app/jobs/retention_purge_job.rb:36`
- `ClientSecretAuditOutbox` — `perform` in `app/jobs/client_secret_audit_delivery_job.rb:17`
- `ClientSecretCredential` — `reconcile_credentials!` in
  `app/jobs/client_secret_lifecycle_job.rb:47`
- `ClientSecretIssuance` — `perform` in `app/jobs/client_secret_issuance_collection_job.rb:18`
- `ClientSocialAuditOutbox` — `perform` in `app/jobs/social_audit_delivery_job.rb:15`
- `ClientStatus` — `validate_owner_active!` in `app/operations/client_persona_creator.rb:85`
- `ClientTelephone` — `class/module body` in `app/jobs/retention_purge_job.rb:41`
- `ClientTelephoneStatus` — `verify_sign_up_registration!` in
  `app/operations/client_secret_passkey_reservation_issuer.rb:233`
- `ClientTotpCredential` — `anonymize_client` in
  `app/operations/withdrawal_personal_data_anonymizer.rb:49`
- `ClientTotpCredentialStatus` — `anonymize_client` in
  `app/operations/withdrawal_personal_data_anonymizer.rb:50`
- `ClientWithdrawalFlow` — `class/module body` in `app/jobs/retention_purge_job.rb:33`
- `Enterprise` — `class/module body` in `app/operations/enterprise_creator.rb:4`
- `EnterpriseAuthorityCutover` — `class/module body` in
  `app/queries/authority_owner_migration_inventory.rb:118`
- `EnterpriseLifecycle` — `call` in `app/operations/enterprise_creator.rb:39`
- `EnterpriseOwnership` — `call` in `app/operations/enterprise_creator.rb:43`
- `Member` — `class/module body` in `app/jobs/retention_purge_job.rb:39`
- `PersonaMembership` — `class/module body` in `app/resolvers/avatar_permission_resolver.rb:29`
- `PersonaMembershipKind` — `class/module body` in `app/resolvers/avatar_permission_resolver.rb:31`

Models referenced only through model associations/model source and/or tests:

`AppEnforcementAuthenticationMethodEffect`, `AppEnforcementIdentifierEffect`,
`AppEnforcementPrincipalEffect`, `AppEnforcementPrincipalLink`, `ClientAccount`,
`ClientAppleNotificationEvent`, `ClientBanner`, `ClientBulletin`, `ClientEmailHistory`,
`ClientIdentifierRotationAudit`, `ClientMember`, `ClientMemberDeletion`, `ClientMemberDiscovery`,
`ClientMemberImpersonation`, `ClientMemberObservation`, `ClientMemberRevocation`,
`ClientMemberSuspension`, `ClientMembership`, `ClientMfaStatus`, `ClientOidcIdentityBinding`,
`ClientPersonaAdministrationGrant`, `ClientPersonaDelegationGrant`,
`ClientPersonaOwnershipTransferRequest`, `ClientPersonaUsageGrant`, `ClientPersonaViewGrant`,
`ClientPreferenceAdultContentGate`, `ClientPreferenceAdultContentGateOption`,
`ClientPreferenceStatus`, `ClientPrivacyRequestStatus`, `ClientProcessorErasureNotificationAttempt`,
`ClientProcessorErasureNotificationStatus`, `ClientProfile`, `ClientProfileStatus`,
`ClientRegistrationCompletion`, `ClientRegistrationCompletionMethod`, `ClientRetentionHoldStatus`,
`ClientSecurityMode`, `ClientTelephoneHistory`, `ClientVisibility`, `ClientWithdrawalCeremony`,
`ClientWithdrawalFlowEvent`, `ClientWithdrawalFlowStatus`, `CoreAppClientBridge`,
`EnterpriseAdministrationGrant`, `EnterpriseDelegationGrant`, `EnterpriseOwnershipTransferRequest`,
`EnterpriseUnit`, `EnterpriseUnitClosure`, `EnterpriseViewGrant`, `MemberStatus`,
`PersonaAssignment`, `PersonaMembershipRevokeReason`, `PersonaMembershipState`

Models with no static runtime, model-source, association, or test reference:

`ClientSocialLinkSourceReceipt`

## `avatar` — `AvatarRecord` — **USED**

45 concrete models: 19 runtime-referenced, 26 model/test-only, 0 unreferenced.

Runtime-referenced models and one caller example each:

- `Avatar` — `class/module body` in `app/adapters/avatar_authority_client.rb:4`
- `AvatarAgentBinding` — `active_bindings_for_avatar` in
  `app/services/avatar_backfill/audit_legacy_client_bindings.rb:162`
- `AvatarAssignment` — `purge_client` in `app/services/retention_cross_database_child_purge.rb:53`
- `AvatarBureauAgentGrant` — `class/module body` in
  `app/resolvers/avatar_access_grant_resolver.rb:8`
- `AvatarBureauOwnershipPeriod` — `create_concrete_period!` in
  `app/operations/avatar_concrete_ownership_backfill_operation.rb:117`
- `AvatarCapability` — `ensure_reference_rows!` in `app/services/avatar_provisioning/create.rb:89`
- `AvatarEnterpriseOwnershipPeriod` — `create_concrete_period!` in
  `app/operations/avatar_concrete_ownership_backfill_operation.rb:115`
- `AvatarEnterprisePersonaGrant` — `class/module body` in
  `app/resolvers/avatar_access_grant_resolver.rb:6`
- `AvatarGroup` — `apply_candidate` in
  `app/operations/avatar_group_concrete_ownership_backfill_operation.rb:64`
- `AvatarGroupConcreteOwnershipPeriod` — `validate_candidate!` in
  `app/operations/avatar_group_concrete_ownership_backfill_operation.rb:92`
- `AvatarGroupOwnershipPeriod` — `apply_candidate` in
  `app/operations/avatar_group_concrete_ownership_backfill_operation.rb:71`
- `AvatarLifecycleState` — `ensure_reference_rows!` in
  `app/services/avatar_provisioning/create.rb:90`
- `AvatarMoniker` — `call` in `app/operations/avatar_moniker_writer_operation.rb:30`
- `AvatarOwnershipCutover` — `call_on_writer` in
  `app/operations/avatar_ownership_cutover_operation.rb:55`
- `AvatarOwnershipPeriod` — `validate_candidate!` in
  `app/operations/avatar_concrete_ownership_backfill_operation.rb:98`
- `AvatarPersonaBinding` — `classify` in
  `app/services/avatar_backfill/audit_legacy_client_bindings.rb:134`
- `AvatarPurgeDeferral` — `purge_avatars` in `app/jobs/retention_purge_job.rb:204`
- `Handle` — `create_handle!` in `app/services/avatar_provisioning/create.rb:94`
- `HandleStatus` — `ensure_reference_rows!` in `app/services/avatar_provisioning/create.rb:88`

Models referenced only through model associations/model source and/or tests:

`AvatarBlock`, `AvatarBureauToBureauTransferDetail`, `AvatarBureauToEnterpriseTransferDetail`,
`AvatarEnterpriseToBureauTransferDetail`, `AvatarEnterpriseToEnterpriseTransferDetail`,
`AvatarFollow`, `AvatarLifecycleEvent`, `AvatarMembership`, `AvatarMembershipStatus`, `AvatarMute`,
`AvatarOwnershipStatus`, `AvatarOwnershipTransfer`, `AvatarPermission`, `AvatarRole`,
`AvatarRolePermission`, `AvatarTransferReservation`, `GroupAvatarMembership`, `HandleAssignment`,
`HandleAssignmentStatus`, `MemberAvatarAccess`, `MemberAvatarDeletion`, `MemberAvatarExtraction`,
`MemberAvatarImpersonation`, `MemberAvatarOversight`, `MemberAvatarSuspension`,
`MemberAvatarVisibility`

## `chronicle` — `ChronicleRecord` — **USED**

22 concrete models: 21 runtime-referenced, 1 model/test-only, 0 unreferenced.

Runtime-referenced models and one caller example each:

- `AccountAccessEvent` — `principal_access_recorded?` in
  `app/jobs/enforcement_reconciliation_job.rb:93`
- `AppPreferenceChronicle` — `event_id_map_for` in
  `app/controllers/concerns/authentication_audit_writer.rb:275`
- `AppPreferenceChronicleEvent` — `event_id_map_for` in
  `app/controllers/concerns/authentication_audit_writer.rb:277`
- `AppPreferenceChronicleLevel` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:52`
- `Chronicle` — `class/module body` in `app/controllers/concerns/authentication_audit_writer.rb:6`
- `ChronicleOutboxEntry` — `class/module body` in
  `app/controllers/concerns/authentication_audit_writer.rb:10`
- `ChronicleRetentionPolicy` — `persist_chronicle!` in
  `app/jobs/client_secret_audit_delivery_job.rb:80`
- `ChronicleVisibility` — `attach_visibility_contexts` in
  `app/operations/chronicle_intent_writer.rb:61`
- `ChronicleVisibilityContext` — `resolve_visibility_context` in
  `app/operations/chronicle_intent_writer.rb:69`
- `ClientChronicle` — `build_audit` in `app/controllers/concerns/authentication_audit_writer.rb:110`
- `ClientChronicleEvent` — `event_id_map_for` in
  `app/controllers/concerns/authentication_audit_writer.rb:257`
- `ClientChronicleLevel` — `ensure_chronicle_references!` in
  `app/controllers/concerns/authentication_audit_writer.rb:323`
- `ComPreferenceChronicle` — `event_id_map_for` in
  `app/controllers/concerns/authentication_audit_writer.rb:286`
- `ComPreferenceChronicleEvent` — `event_id_map_for` in
  `app/controllers/concerns/authentication_audit_writer.rb:288`
- `ComPreferenceChronicleLevel` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:84`
- `OperatorChronicle` — `build_audit` in
  `app/controllers/concerns/authentication_audit_writer.rb:111`
- `OperatorChronicleEvent` — `event_id_map_for` in
  `app/controllers/concerns/authentication_audit_writer.rb:267`
- `OperatorChronicleLevel` — `ensure_chronicle_references!` in
  `app/controllers/concerns/authentication_audit_writer.rb:328`
- `OrgPreferenceChronicle` — `event_id_map_for` in
  `app/controllers/concerns/authentication_audit_writer.rb:297`
- `OrgPreferenceChronicleEvent` — `event_id_map_for` in
  `app/controllers/concerns/authentication_audit_writer.rb:299`
- `OrgPreferenceChronicleLevel` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:116`

Models referenced only through model associations/model source and/or tests:

`EnforcementEvent`

## `com_setting` — `ComSettingRecord` — **USED**

29 concrete models: 27 runtime-referenced, 2 model/test-only, 0 unreferenced.

Runtime-referenced models and one caller example each:

- `ComPreference` — `anonymous_com_claim_shape?` in
  `app/controllers/concerns/preference_base.rb:469`
- `ComPreferenceBrowserBinding` — `require_matching_existing_browser_binding!` in
  `app/controllers/concerns/preference_browser_binding.rb:50`
- `ComPreferenceConsentReceipt` — `require_matching_existing_browser_binding!` in
  `app/controllers/concerns/preference_browser_binding.rb:53`
- `ComPreferenceCookie` — `readable_cookie_state` in
  `app/controllers/concerns/preference_browser_binding.rb:66`
- `ComPreferenceCurrency` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:102`
- `ComPreferenceCurrencyOption` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:90`
- `ComPreferenceDateFormat` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:103`
- `ComPreferenceDateFormatOption` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:91`
- `ComPreferenceDensity` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:106`
- `ComPreferenceDensityOption` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:94`
- `ComPreferenceLanguage` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:99`
- `ComPreferenceLanguageOption` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:87`
- `ComPreferenceMotion` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:105`
- `ComPreferenceMotionOption` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:93`
- `ComPreferencePageSize` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:107`
- `ComPreferencePageSizeOption` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:95`
- `ComPreferenceRegion` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:100`
- `ComPreferenceRegionOption` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:88`
- `ComPreferenceStatus` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:80`
- `ComPreferenceTheme` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:101`
- `ComPreferenceThemeOption` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:89`
- `ComPreferenceTimeFormat` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:104`
- `ComPreferenceTimeFormatOption` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:92`
- `ComPreferenceTimezone` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:98`
- `ComPreferenceTimezoneOption` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:86`
- `ComPreferenceWebPush` — `create_preference_options` in
  `app/controllers/concerns/preference_base.rb:108`
- `ComPreferenceWebPushOption` — `create_preference_options` in
  `app/controllers/concerns/preference_base.rb:106`

Models referenced only through model associations/model source and/or tests:

`ComPreferenceAdultContentGate`, `ComPreferenceAdultContentGateOption`

## `occurrence` — `OccurrenceRecord` — **USED**

52 concrete models: 13 runtime-referenced, 39 model/test-only, 0 unreferenced.

Runtime-referenced models and one caller example each:

- `AreaOccurrence` — `class/module body` in `app/jobs/retention_purge_job.rb:46`
- `ClientOccurrence` — `class/module body` in `app/jobs/retention_purge_job.rb:46`
- `ClientOccurrenceStatus` — `persist_user_occurrence` in `app/services/sign_risk_emitter.rb:60`
- `DomainOccurrence` — `class/module body` in `app/jobs/retention_purge_job.rb:47`
- `EmailOccurrence` — `class/module body` in `app/jobs/retention_purge_job.rb:47`
- `IpOccurrence` — `class/module body` in `app/jobs/retention_purge_job.rb:47`
- `JwtAnomalyEvent` — `emit` in `app/subscribers/jwt_anomaly_subscriber.rb:34`
- `JwtOccurrence` — `class/module body` in `app/jobs/retention_purge_job.rb:47`
- `OperatorOccurrence` — `class/module body` in `app/jobs/retention_purge_job.rb:46`
- `OperatorOccurrenceStatus` — `persist_staff_occurrence` in `app/services/sign_risk_emitter.rb:76`
- `TelephoneOccurrence` — `class/module body` in `app/jobs/retention_purge_job.rb:47`
- `VisitorOccurrence` — `class/module body` in `app/jobs/retention_purge_job.rb:46`
- `ZipOccurrence` — `class/module body` in `app/jobs/retention_purge_job.rb:46`

Models referenced only through model associations/model source and/or tests:

`AreaClientOccurrence`, `AreaDomainOccurrence`, `AreaEmailOccurrence`, `AreaIpOccurrence`,
`AreaOccurrenceStatus`, `AreaOperatorOccurrence`, `AreaTelephoneOccurrence`,
`AreaVisitorOccurrence`, `AreaZipOccurrence`, `ClientZipOccurrence`, `DomainClientOccurrence`,
`DomainEmailOccurrence`, `DomainIpOccurrence`, `DomainOccurrenceStatus`, `DomainOperatorOccurrence`,
`DomainTelephoneOccurrence`, `DomainZipOccurrence`, `EmailClientOccurrence`, `EmailIpOccurrence`,
`EmailOccurrenceStatus`, `EmailOperatorOccurrence`, `EmailTelephoneOccurrence`,
`EmailVisitorOccurrence`, `EmailZipOccurrence`, `IpClientOccurrence`, `IpOccurrenceStatus`,
`IpOperatorOccurrence`, `IpTelephoneOccurrence`, `IpVisitorOccurrence`, `IpZipOccurrence`,
`JwtOccurrenceStatus`, `OperatorClientOccurrence`, `OperatorTelephoneOccurrence`,
`OperatorZipOccurrence`, `TelephoneClientOccurrence`, `TelephoneOccurrenceStatus`,
`TelephoneZipOccurrence`, `VisitorOccurrenceStatus`, `ZipOccurrenceStatus`

## `op_base_app` — `OpBaseAppRecord` — **USED**

65 concrete models: 32 runtime-referenced, 31 model/test-only, 2 unreferenced.

Runtime-referenced models and one caller example each:

- `ClientAuthAdmissionBinding` — `class/module body` in
  `app/operations/auth_admission_binding_purger.rb:9`
- `ClientAuthCeremonySession` — `failure_reason!` in
  `app/operations/client_secret_claim_finalizer.rb:71`
- `ClientDeviceSession` — `parent_revocation_persisted?` in
  `app/controllers/concerns/authentication_logout_current_session.rb:194`
- `ClientDpopProofState` — `class/module body` in `app/jobs/dpop_proof_state_purge_job.rb:19`
- `ClientEmailCeremonyTransaction` — `class/module body` in
  `app/operations/identity_email_ceremony_transaction_purger.rb:6`
- `ClientOidcAuthorizationTransaction` — `purge_sign_in_flows` in
  `app/jobs/retention_purge_job.rb:374`
- `ClientPasskeyCeremonyTransaction` — `class/module body` in
  `app/operations/identity_passkey_ceremony_transaction_purger.rb:6`
- `ClientSecretCredentialCeremonyTransaction` — `class/module body` in
  `app/operations/identity_secret_credential_ceremony_transaction_purger.rb:6`
- `ClientSecretSignInReceipt` — `reconcile_completed_receipts!` in
  `app/jobs/client_secret_lifecycle_job.rb:71`
- `ClientSessionLimitResolutionTransaction` — `resolution_model_for_gate` in
  `app/controllers/concerns/session_limit_gate.rb:164`
- `ClientSignInFlow` — `reconcile_completed_receipts!` in
  `app/jobs/client_secret_lifecycle_job.rb:70`
- `ClientSignUpFlow` — `reconcile_signup_batches!` in `app/jobs/client_secret_lifecycle_job.rb:99`
- `ClientSocialCeremonyTransaction` — `class/module body` in
  `app/operations/identity_social_ceremony_transaction_purger.rb:6`
- `ClientStepUpCeremonyTransaction` — `class/module body` in
  `app/operations/auth_admission_binding_purger.rb:11`
- `ClientStepUpCommit` — `latest_totp_commit_root_token_ids` in
  `app/controllers/concerns/authentication_session_revoker.rb:50`
- `ClientStepUpSession` — `class/module body` in `app/jobs/retention_purge_job.rb:45`
- `ClientTelephoneCeremonyTransaction` — `class/module body` in
  `app/operations/identity_telephone_ceremony_transaction_purger.rb:6`
- `ClientToken` — `token_scope` in
  `app/controllers/concerns/authentication_logout_all_sessions.rb:50`
- `ClientTotpCeremonyTransaction` — `class/module body` in
  `app/operations/identity_step_up_ceremony_transaction_purger.rb:12`
- `ClientVerification` — `verification_model` in `app/controllers/concerns/verification_base.rb:564`
- `ClientVisaSensitiveAdmission` — `issuance_result_from` in
  `app/adapters/visa_sensitive_admission_client.rb:147`
- `IdentityPasskeyCeremonyCandidate` — `class/module body` in
  `app/operations/identity_step_up_ceremony_transaction_purger.rb:12`
- `IdentityTotpCeremonyCandidate` — `class/module body` in
  `app/operations/identity_step_up_ceremony_transaction_purger.rb:12`
- `OpAppAuthorityStop` — `class/module body` in `app/operations/op_authority_stop_committer.rb:28`
- `OpAppAuthorityStopEpochCutoff` — `class/module body` in
  `app/operations/op_authority_stop_committer.rb:31`
- `OpAppAuthorityStopGrantTarget` — `class/module body` in
  `app/operations/op_authority_stop_committer.rb:30`
- `OpAppAuthorityStopParticipant` — `class/module body` in `app/jobs/op_outbox_dispatch_job.rb:17`
- `OpAppAuthorityStopRootTarget` — `class/module body` in
  `app/operations/op_authority_stop_committer.rb:29`
- `OpAppGrant` — `browser_rp_session_class` in
  `app/controllers/concerns/browser_rp_authentication.rb:354`
- `OpAppInboundEventReceipt` — `class/module body` in
  `app/operations/op_identity_event_invalidator.rb:13`
- `SecurityConsumedJti` — `perform` in `app/jobs/security_consumed_jti_purge_job.rb:27`
- `SecurityOneTimeReveal` — `class/module body` in
  `app/jobs/security_one_time_reveal_purge_job.rb:8`

Models referenced only through model associations/model source and/or tests:

`ClientAuthAdmissionBindingStatus`, `ClientAuthCeremonySessionStatus`, `ClientOauthCallbackState`,
`ClientOidcAuthorizationTransactionStatus`, `ClientOidcConnection`, `ClientSensitiveAdmission`,
`ClientSensitiveAdmissionAuditAttempt`, `ClientSensitiveAdmissionAuditOutbox`,
`ClientSessionLimitResolutionState`, `ClientSignInFlowState`, `ClientSignUpFlowCleanupStatus`,
`ClientSignUpFlowStatus`, `ClientStepUpAuditOutbox`, `ClientStepUpAuditOutboxAttempt`,
`ClientStepUpAuditOutboxDeliveryState`, `ClientStepUpContext`, `ClientStepUpContextState`,
`ClientStepUpContextTransition`, `ClientTokenBindingMethod`, `ClientTokenDbscStatus`,
`ClientTokenKind`, `ClientTokenStatus`, `ClientVisaSocialLinkAdmission`,
`IdentitySocialCeremonyCandidate`, `LogoutTransaction`, `OpAppAuthorityStopCause`,
`OpAppAuthorityStopParticipantStatus`, `OpAppAuthorityStopScope`, `OpAppConsumedJti`,
`OpAppGrantLogoutHint`, `TurnstileReplay`

Models with no static runtime, model-source, association, or test reference:

`ClientEmergencySignInOperation`, `IdentitySecretCredentialCeremonyCandidate`

## `op_base_org` — `OpBaseOrgRecord` — **USED**

53 concrete models: 25 runtime-referenced, 27 model/test-only, 1 unreferenced.

Runtime-referenced models and one caller example each:

- `OpOrgAuthorityStop` — `class/module body` in `app/operations/op_authority_stop_committer.rb:41`
- `OpOrgAuthorityStopEpochCutoff` — `class/module body` in
  `app/operations/op_authority_stop_committer.rb:44`
- `OpOrgAuthorityStopGrantTarget` — `class/module body` in
  `app/operations/op_authority_stop_committer.rb:43`
- `OpOrgAuthorityStopParticipant` — `class/module body` in `app/jobs/op_outbox_dispatch_job.rb:18`
- `OpOrgAuthorityStopRootTarget` — `class/module body` in
  `app/operations/op_authority_stop_committer.rb:42`
- `OpOrgGrant` — `browser_rp_session_class` in
  `app/controllers/concerns/browser_rp_authentication.rb:353`
- `OpOrgInboundEventReceipt` — `class/module body` in
  `app/operations/op_identity_event_invalidator.rb:14`
- `OperatorAuthAdmissionBinding` — `class/module body` in
  `app/operations/auth_admission_binding_purger.rb:10`
- `OperatorAuthCeremonySession` — `class/module body` in
  `app/operations/identity_step_up_ceremony_transaction_purger.rb:15`
- `OperatorDeviceSession` — `parent_revocation_persisted?` in
  `app/controllers/concerns/authentication_logout_current_session.rb:195`
- `OperatorDpopProofState` — `class/module body` in `app/jobs/dpop_proof_state_purge_job.rb:20`
- `OperatorEmailCeremonyTransaction` — `class/module body` in
  `app/operations/identity_email_ceremony_transaction_purger.rb:7`
- `OperatorOidcAuthorizationTransaction` — `class/module body` in
  `app/operations/auth_admission_binding_purger.rb:10`
- `OperatorPasskeyCeremonyCandidate` — `class/module body` in
  `app/operations/identity_step_up_ceremony_transaction_purger.rb:16`
- `OperatorPasskeyCeremonyTransaction` — `class/module body` in
  `app/operations/identity_passkey_ceremony_transaction_purger.rb:7`
- `OperatorSecretCredentialCeremonyTransaction` — `class/module body` in
  `app/operations/identity_secret_credential_ceremony_transaction_purger.rb:7`
- `OperatorSessionLimitResolutionTransaction` — `resolution_model_for_gate` in
  `app/controllers/concerns/session_limit_gate.rb:165`
- `OperatorSignInFlow` — `class/module body` in `app/jobs/retention_purge_job.rb:32`
- `OperatorSignUpFlow` — `class/module body` in `app/jobs/retention_purge_job.rb:37`
- `OperatorStepUpCeremonyTransaction` — `class/module body` in
  `app/operations/auth_admission_binding_purger.rb:12`
- `OperatorStepUpCommit` — `latest_totp_commit_root_token_ids` in
  `app/controllers/concerns/authentication_session_revoker.rb:51`
- `OperatorStepUpSession` — `class/module body` in `app/jobs/retention_purge_job.rb:45`
- `OperatorTelephoneCeremonyTransaction` — `class/module body` in
  `app/operations/identity_telephone_ceremony_transaction_purger.rb:7`
- `OperatorToken` — `token_scope` in
  `app/controllers/concerns/authentication_logout_all_sessions.rb:52`
- `OperatorVerification` — `verification_model` in
  `app/controllers/concerns/verification_base.rb:564`

Models referenced only through model associations/model source and/or tests:

`OpOrgAuthorityStopCause`, `OpOrgAuthorityStopParticipantStatus`, `OpOrgAuthorityStopScope`,
`OpOrgConsumedJti`, `OpOrgGrantLogoutHint`, `OperatorAuthAdmissionBindingStatus`,
`OperatorAuthCeremonySessionStatus`, `OperatorOauthCallbackState`,
`OperatorOidcAuthorizationTransactionStatus`, `OperatorOidcConnection`,
`OperatorSensitiveAdmission`, `OperatorSensitiveAdmissionAuditAttempt`,
`OperatorSensitiveAdmissionAuditOutbox`, `OperatorSessionLimitResolutionState`,
`OperatorSignInFlowState`, `OperatorSignUpFlowStatus`, `OperatorStepUpAuditOutbox`,
`OperatorStepUpAuditOutboxAttempt`, `OperatorStepUpAuditOutboxDeliveryState`,
`OperatorStepUpContext`, `OperatorStepUpContextState`, `OperatorStepUpContextTransition`,
`OperatorTokenBindingMethod`, `OperatorTokenDbscStatus`, `OperatorTokenKind`, `OperatorTokenStatus`,
`OrganizationInvitation`

Models with no static runtime, model-source, association, or test reference:

`OperatorVisaSensitiveAdmission`

## `org_setting` — `OrgSettingRecord` — **USED**

29 concrete models: 23 runtime-referenced, 6 model/test-only, 0 unreferenced.

Runtime-referenced models and one caller example each:

- `OrgPreference` — `anonymous_preference_claim_shape?` in
  `app/controllers/concerns/preference_base.rb:475`
- `OrgPreferenceCookie` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:113`
- `OrgPreferenceCurrency` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:134`
- `OrgPreferenceCurrencyOption` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:122`
- `OrgPreferenceDateFormat` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:135`
- `OrgPreferenceDateFormatOption` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:123`
- `OrgPreferenceDensity` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:138`
- `OrgPreferenceDensityOption` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:126`
- `OrgPreferenceLanguage` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:131`
- `OrgPreferenceLanguageOption` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:119`
- `OrgPreferenceMotion` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:137`
- `OrgPreferenceMotionOption` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:125`
- `OrgPreferencePageSize` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:139`
- `OrgPreferencePageSizeOption` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:127`
- `OrgPreferenceRegion` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:132`
- `OrgPreferenceRegionOption` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:120`
- `OrgPreferenceStatus` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:112`
- `OrgPreferenceTheme` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:133`
- `OrgPreferenceThemeOption` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:121`
- `OrgPreferenceTimeFormat` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:136`
- `OrgPreferenceTimeFormatOption` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:124`
- `OrgPreferenceTimezone` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:130`
- `OrgPreferenceTimezoneOption` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:118`

Models referenced only through model associations/model source and/or tests:

`OrgPreferenceAdultContentGate`, `OrgPreferenceAdultContentGateOption`,
`OrgPreferenceBrowserBinding`, `OrgPreferenceConsentReceipt`, `OrgPreferenceWebPush`,
`OrgPreferenceWebPushOption`

## `org_signal` — `OrgSignalRecord` — **USED**

2 concrete models: 1 runtime-referenced, 1 model/test-only, 0 unreferenced.

Runtime-referenced models and one caller example each:

- `OperatorNotificationRecord` — `purge_operator` in
  `app/services/retention_cross_database_child_purge.rb:57`

Models referenced only through model associations/model source and/or tests:

`OperatorNotification`

## `org_zenith` — `OrgZenithRecord` — **USED**

97 concrete models: 52 runtime-referenced, 44 model/test-only, 1 unreferenced.

Runtime-referenced models and one caller example each:

- `Agent` — `class/module body` in `app/adapters/org_admin_authority_client.rb:7`
- `AgentAuthorityCutover` — `class/module body` in
  `app/queries/authority_owner_migration_inventory.rb:141`
- `AgentLifecycle` — `call` in `app/operations/agent_creator.rb:48`
- `AgentMembership` — `class/module body` in `app/resolvers/avatar_permission_resolver.rb:40`
- `AgentMembershipKind` — `class/module body` in `app/resolvers/avatar_permission_resolver.rb:42`
- `AgentOwnership` — `call` in `app/operations/agent_creator.rb:52`
- `Bureau` — `class/module body` in `app/operations/bureau_creator.rb:4`
- `BureauAuthorityCutover` — `class/module body` in
  `app/queries/authority_owner_migration_inventory.rb:166`
- `BureauLifecycle` — `call` in `app/operations/bureau_creator.rb:38`
- `BureauOwnership` — `call` in `app/operations/bureau_creator.rb:42`
- `Operator` — `class/module body` in `app/adapters/org_admin_authority_client.rb:6`
- `OperatorAuthorityLock` — `call` in `app/operations/agent_creator.rb:34`
- `OperatorCapabilityGrant` — `class/module body` in `app/policies/application_policy.rb:133`
- `OperatorEmail` — `call` in `app/operations/email_identifier_purger.rb:12`
- `OperatorEmailHistory` — `purge_operators` in `app/jobs/retention_purge_job.rb:423`
- `OperatorEmailStatus` — `contact_email_count` in
  `app/queries/authentication_credential_inventory.rb:176`
- `OperatorEntraIdentity` — `purge_operator` in
  `app/services/retention_cross_database_child_purge.rb:63`
- `OperatorIdentity` — `call` in `app/operations/agent_creator.rb:37`
- `OperatorIdentityState` — `validate_identity!` in `app/operations/agent_creator.rb:71`
- `OperatorPasskey` — `class/module body` in `app/operations/passkey_registration_operation.rb:12`
- `OperatorPasskeyAuditOutbox` — `class/module body` in `app/jobs/passkey_audit_delivery_job.rb:9`
- `OperatorPasskeyStatus` — `active_passkey_count` in
  `app/queries/authentication_credential_inventory.rb:223`
- `OperatorPreference` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:170`
- `OperatorPreferenceCurrency` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:188`
- `OperatorPreferenceCurrencyOption` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:176`
- `OperatorPreferenceDateFormat` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:189`
- `OperatorPreferenceDateFormatOption` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:177`
- `OperatorPreferenceDensity` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:192`
- `OperatorPreferenceDensityOption` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:180`
- `OperatorPreferenceLanguage` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:185`
- `OperatorPreferenceLanguageOption` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:173`
- `OperatorPreferenceMotion` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:191`
- `OperatorPreferenceMotionOption` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:179`
- `OperatorPreferencePageSize` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:193`
- `OperatorPreferencePageSizeOption` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:181`
- `OperatorPreferenceRegion` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:186`
- `OperatorPreferenceRegionOption` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:174`
- `OperatorPreferenceTheme` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:187`
- `OperatorPreferenceThemeOption` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:175`
- `OperatorPreferenceTimeFormat` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:190`
- `OperatorPreferenceTimeFormatOption` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:178`
- `OperatorPreferenceTimezone` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:184`
- `OperatorPreferenceTimezoneOption` — `class/module body` in
  `app/controllers/concerns/preference_class_registry.rb:172`
- `OperatorSecretCredential` — `class/module body` in `app/jobs/retention_purge_job.rb:38`
- `OperatorStatus` — `validate_owner_active!` in `app/operations/agent_creator.rb:78`
- `OperatorTelephone` — `call` in
  `app/operations/operator_telephone_public_id_backfill_operation.rb:8`
- `OperatorTelephoneHistory` — `purge_operators` in `app/jobs/retention_purge_job.rb:424`
- `OperatorTelephoneStatus` — `contact_telephone_count` in
  `app/queries/authentication_credential_inventory.rb:201`
- `OperatorWorkspaceAccount` — `class/module body` in `app/jobs/retention_purge_job.rb:39`
- `OrgEnforcementAppeal` — `class/module body` in `app/jobs/enforcement_reconciliation_job.rb:19`
- `OrgEnforcementCase` — `class/module body` in `app/jobs/enforcement_expiry_job.rb:12`
- `OrgIdentityAuthenticationEvent` — `class/module body` in
  `app/jobs/op_identity_event_delivery_job.rb:9`

Models referenced only through model associations/model source and/or tests:

`AgentAdministrationGrant`, `AgentAssignment`, `AgentDelegationGrant`,
`AgentMembershipRevokeReason`, `AgentMembershipState`, `AgentOwnershipTransferRequest`,
`AgentUsageGrant`, `AgentViewGrant`, `BureauAdministrationGrant`, `BureauDelegationGrant`,
`BureauOwnershipTransferRequest`, `BureauUnit`, `BureauUnitClosure`, `BureauViewGrant`,
`CoreOrgOperatorBridge`, `Department`, `DepartmentStatus`, `Division`, `DivisionStatus`,
`OperatorAccount`, `OperatorBanner`, `OperatorBulletin`, `OperatorEntraIdentityState`,
`OperatorLifecycleRequest`, `OperatorMfaStatus`, `OperatorOidcIdentityBinding`,
`OperatorOrganization`, `OperatorPreferenceAdultContentGate`,
`OperatorPreferenceAdultContentGateOption`, `OperatorPreferenceStatus`,
`OperatorSecretCredentialKind`, `OperatorSecretCredentialStatus`, `OperatorSecurityMode`,
`OperatorVisibility`, `OperatorWorkspaceAccountMembership`, `OperatorWorkspaceAccountStatus`,
`OrgEnforcementAuthenticationMethodEffect`, `OrgEnforcementIdentifierEffect`,
`OrgEnforcementPrincipalEffect`, `OrgEnforcementPrincipalLink`, `OrgIamOperationOutcome`,
`OrganizationEntraConnection`, `OrganizationEntraConnectionState`, `OrganizationStatus`

Models with no static runtime, model-source, association, or test reference:

`OperatorIdentifierRotationAudit`

## `publishing` — `PublishingRecord` — **USED**

157 concrete models: 12 runtime-referenced, 145 model/test-only, 0 unreferenced.

Runtime-referenced models and one caller example each:

- `Publishing::Docs::App::Entry` — `publishing_entry_class` in
  `app/controllers/concerns/publishing_authority_api_endpoint.rb:49`
- `Publishing::Docs::Com::Entry` — `publishing_entry_class` in
  `app/controllers/concerns/publishing_authority_api_endpoint.rb:50`
- `Publishing::Docs::Org::Entry` — `publishing_entry_class` in
  `app/controllers/concerns/publishing_authority_api_endpoint.rb:51`
- `Publishing::Help::App::Entry` — `publishing_entry_class` in
  `app/controllers/concerns/publishing_authority_api_endpoint.rb:52`
- `Publishing::Help::Com::Entry` — `publishing_entry_class` in
  `app/controllers/concerns/publishing_authority_api_endpoint.rb:53`
- `Publishing::Help::Org::Entry` — `publishing_entry_class` in
  `app/controllers/concerns/publishing_authority_api_endpoint.rb:54`
- `Publishing::Info::App::Entry` — `publishing_entry_class` in
  `app/controllers/concerns/publishing_authority_api_endpoint.rb:55`
- `Publishing::Info::Com::Entry` — `publishing_entry_class` in
  `app/controllers/concerns/publishing_authority_api_endpoint.rb:56`
- `Publishing::Info::Org::Entry` — `publishing_entry_class` in
  `app/controllers/concerns/publishing_authority_api_endpoint.rb:57`
- `Publishing::News::App::Entry` — `publishing_entry_class` in
  `app/controllers/concerns/publishing_authority_api_endpoint.rb:58`
- `Publishing::News::Com::Entry` — `publishing_entry_class` in
  `app/controllers/concerns/publishing_authority_api_endpoint.rb:59`
- `Publishing::News::Org::Entry` — `publishing_entry_class` in
  `app/controllers/concerns/publishing_authority_api_endpoint.rb:60`

Models referenced only through model associations/model source and/or tests:

`Publishing::Docs::App::EntryRevision`, `Publishing::Docs::App::EntrySlug`,
`Publishing::Docs::App::EntryVersion`, `Publishing::Docs::App::Publication`,
`Publishing::Docs::App::RevisionMediaUsage`,
`Publishing::Docs::App::RevisionMultipleTaxonomyAssignment`,
`Publishing::Docs::App::RevisionSingleTaxonomyAssignment`, `Publishing::Docs::App::TaxonomyTerm`,
`Publishing::Docs::App::VersionMediaUsage`,
`Publishing::Docs::App::VersionMultipleTaxonomyAssignment`,
`Publishing::Docs::App::VersionSingleTaxonomyAssignment`, `Publishing::Docs::App::Vocabulary`,
`Publishing::Docs::Com::EntryRevision`, `Publishing::Docs::Com::EntrySlug`,
`Publishing::Docs::Com::EntryVersion`, `Publishing::Docs::Com::Publication`,
`Publishing::Docs::Com::RevisionMediaUsage`,
`Publishing::Docs::Com::RevisionMultipleTaxonomyAssignment`,
`Publishing::Docs::Com::RevisionSingleTaxonomyAssignment`, `Publishing::Docs::Com::TaxonomyTerm`,
`Publishing::Docs::Com::VersionMediaUsage`,
`Publishing::Docs::Com::VersionMultipleTaxonomyAssignment`,
`Publishing::Docs::Com::VersionSingleTaxonomyAssignment`, `Publishing::Docs::Com::Vocabulary`,
`Publishing::Docs::Org::EntryRevision`, `Publishing::Docs::Org::EntrySlug`,
`Publishing::Docs::Org::EntryVersion`, `Publishing::Docs::Org::Publication`,
`Publishing::Docs::Org::RevisionMediaUsage`,
`Publishing::Docs::Org::RevisionMultipleTaxonomyAssignment`,
`Publishing::Docs::Org::RevisionSingleTaxonomyAssignment`, `Publishing::Docs::Org::TaxonomyTerm`,
`Publishing::Docs::Org::VersionMediaUsage`,
`Publishing::Docs::Org::VersionMultipleTaxonomyAssignment`,
`Publishing::Docs::Org::VersionSingleTaxonomyAssignment`, `Publishing::Docs::Org::Vocabulary`,
`Publishing::Help::App::EntryRevision`, `Publishing::Help::App::EntrySlug`,
`Publishing::Help::App::EntryVersion`, `Publishing::Help::App::Publication`,
`Publishing::Help::App::RevisionMediaUsage`,
`Publishing::Help::App::RevisionMultipleTaxonomyAssignment`,
`Publishing::Help::App::RevisionSingleTaxonomyAssignment`, `Publishing::Help::App::TaxonomyTerm`,
`Publishing::Help::App::VersionMediaUsage`,
`Publishing::Help::App::VersionMultipleTaxonomyAssignment`,
`Publishing::Help::App::VersionSingleTaxonomyAssignment`, `Publishing::Help::App::Vocabulary`,
`Publishing::Help::Com::EntryRevision`, `Publishing::Help::Com::EntrySlug`,
`Publishing::Help::Com::EntryVersion`, `Publishing::Help::Com::Publication`,
`Publishing::Help::Com::RevisionMediaUsage`,
`Publishing::Help::Com::RevisionMultipleTaxonomyAssignment`,
`Publishing::Help::Com::RevisionSingleTaxonomyAssignment`, `Publishing::Help::Com::TaxonomyTerm`,
`Publishing::Help::Com::VersionMediaUsage`,
`Publishing::Help::Com::VersionMultipleTaxonomyAssignment`,
`Publishing::Help::Com::VersionSingleTaxonomyAssignment`, `Publishing::Help::Com::Vocabulary`,
`Publishing::Help::Org::EntryRevision`, `Publishing::Help::Org::EntrySlug`,
`Publishing::Help::Org::EntryVersion`, `Publishing::Help::Org::Publication`,
`Publishing::Help::Org::RevisionMediaUsage`,
`Publishing::Help::Org::RevisionMultipleTaxonomyAssignment`,
`Publishing::Help::Org::RevisionSingleTaxonomyAssignment`, `Publishing::Help::Org::TaxonomyTerm`,
`Publishing::Help::Org::VersionMediaUsage`,
`Publishing::Help::Org::VersionMultipleTaxonomyAssignment`,
`Publishing::Help::Org::VersionSingleTaxonomyAssignment`, `Publishing::Help::Org::Vocabulary`,
`Publishing::Info::App::EntryRevision`, `Publishing::Info::App::EntrySlug`,
`Publishing::Info::App::EntryVersion`, `Publishing::Info::App::Publication`,
`Publishing::Info::App::RevisionMediaUsage`,
`Publishing::Info::App::RevisionMultipleTaxonomyAssignment`,
`Publishing::Info::App::RevisionSingleTaxonomyAssignment`, `Publishing::Info::App::TaxonomyTerm`,
`Publishing::Info::App::VersionMediaUsage`,
`Publishing::Info::App::VersionMultipleTaxonomyAssignment`,
`Publishing::Info::App::VersionSingleTaxonomyAssignment`, `Publishing::Info::App::Vocabulary`,
`Publishing::Info::Com::EntryRevision`, `Publishing::Info::Com::EntrySlug`,
`Publishing::Info::Com::EntryVersion`, `Publishing::Info::Com::Publication`,
`Publishing::Info::Com::RevisionMediaUsage`,
`Publishing::Info::Com::RevisionMultipleTaxonomyAssignment`,
`Publishing::Info::Com::RevisionSingleTaxonomyAssignment`, `Publishing::Info::Com::TaxonomyTerm`,
`Publishing::Info::Com::VersionMediaUsage`,
`Publishing::Info::Com::VersionMultipleTaxonomyAssignment`,
`Publishing::Info::Com::VersionSingleTaxonomyAssignment`, `Publishing::Info::Com::Vocabulary`,
`Publishing::Info::Org::EntryRevision`, `Publishing::Info::Org::EntrySlug`,
`Publishing::Info::Org::EntryVersion`, `Publishing::Info::Org::Publication`,
`Publishing::Info::Org::RevisionMediaUsage`,
`Publishing::Info::Org::RevisionMultipleTaxonomyAssignment`,
`Publishing::Info::Org::RevisionSingleTaxonomyAssignment`, `Publishing::Info::Org::TaxonomyTerm`,
`Publishing::Info::Org::VersionMediaUsage`,
`Publishing::Info::Org::VersionMultipleTaxonomyAssignment`,
`Publishing::Info::Org::VersionSingleTaxonomyAssignment`, `Publishing::Info::Org::Vocabulary`,
`Publishing::MediaFile`, `Publishing::News::App::EntryRevision`, `Publishing::News::App::EntrySlug`,
`Publishing::News::App::EntryVersion`, `Publishing::News::App::Publication`,
`Publishing::News::App::RevisionMediaUsage`,
`Publishing::News::App::RevisionMultipleTaxonomyAssignment`,
`Publishing::News::App::RevisionSingleTaxonomyAssignment`, `Publishing::News::App::TaxonomyTerm`,
`Publishing::News::App::VersionMediaUsage`,
`Publishing::News::App::VersionMultipleTaxonomyAssignment`,
`Publishing::News::App::VersionSingleTaxonomyAssignment`, `Publishing::News::App::Vocabulary`,
`Publishing::News::Com::EntryRevision`, `Publishing::News::Com::EntrySlug`,
`Publishing::News::Com::EntryVersion`, `Publishing::News::Com::Publication`,
`Publishing::News::Com::RevisionMediaUsage`,
`Publishing::News::Com::RevisionMultipleTaxonomyAssignment`,
`Publishing::News::Com::RevisionSingleTaxonomyAssignment`, `Publishing::News::Com::TaxonomyTerm`,
`Publishing::News::Com::VersionMediaUsage`,
`Publishing::News::Com::VersionMultipleTaxonomyAssignment`,
`Publishing::News::Com::VersionSingleTaxonomyAssignment`, `Publishing::News::Com::Vocabulary`,
`Publishing::News::Org::EntryRevision`, `Publishing::News::Org::EntrySlug`,
`Publishing::News::Org::EntryVersion`, `Publishing::News::Org::Publication`,
`Publishing::News::Org::RevisionMediaUsage`,
`Publishing::News::Org::RevisionMultipleTaxonomyAssignment`,
`Publishing::News::Org::RevisionSingleTaxonomyAssignment`, `Publishing::News::Org::TaxonomyTerm`,
`Publishing::News::Org::VersionMediaUsage`,
`Publishing::News::Org::VersionMultipleTaxonomyAssignment`,
`Publishing::News::Org::VersionSingleTaxonomyAssignment`, `Publishing::News::Org::Vocabulary`

## `rp_base_app` — `RpBaseAppRecord` — **USED**

13 concrete models: 8 runtime-referenced, 4 model/test-only, 1 unreferenced.

Runtime-referenced models and one caller example each:

- `RpBaseAppIdentityBinding` — `class/module body` in `app/values/rp_step_up_cell_registry.rb:13`
- `RpBaseAppOpSessionBinding` — `class/module body` in `app/values/rp_step_up_cell_registry.rb:13`
- `RpBaseAppPrincipal` — `boundary` in `app/resolvers/step_up_evidence_resolver.rb:76`
- `RpBaseAppSession` — `rp_cell_selected_context` in
  `app/controllers/concerns/browser_rp_authentication.rb:585`
- `RpBaseAppSessionSelection` — `rp_cell_selected_context` in
  `app/controllers/concerns/browser_rp_authentication.rb:591`
- `RpStepUpState` — `class/module body` in `app/values/rp_step_up_cell_registry.rb:14`
- `RpStepUpStateStatus` — `class/module body` in
  `app/operations/rp_step_up_state_transition_writer.rb:9`
- `RpStepUpStateTransition` — `class/module body` in `app/values/rp_step_up_cell_registry.rb:15`

Models referenced only through model associations/model source and/or tests:

`RpBaseAppEventReceipt`, `RpStepUpAuditOutbox`, `RpStepUpAuditOutboxAttempt`,
`RpStepUpAuditOutboxDeliveryState`

Models with no static runtime, model-source, association, or test reference:

`RpBaseAppCallbackState`

## `rp_base_org` — `RpBaseOrgRecord` — **USED**

14 concrete models: 8 runtime-referenced, 5 model/test-only, 1 unreferenced.

Runtime-referenced models and one caller example each:

- `RpBaseOrgIdentityBinding` — `class/module body` in `app/values/rp_step_up_cell_registry.rb:21`
- `RpBaseOrgOpSessionBinding` — `class/module body` in `app/values/rp_step_up_cell_registry.rb:21`
- `RpBaseOrgPrincipal` — `boundary` in `app/resolvers/step_up_evidence_resolver.rb:78`
- `RpBaseOrgSession` — `rp_cell_selected_context` in
  `app/controllers/concerns/browser_rp_authentication.rb:604`
- `RpBaseOrgSessionSelection` — `rp_org_cell_selected_context` in
  `app/controllers/concerns/browser_rp_authentication.rb:638`
- `RpBaseOrgStepUpState` — `class/module body` in `app/values/rp_step_up_cell_registry.rb:22`
- `RpBaseOrgStepUpStateStatus` — `class/module body` in `app/values/rp_step_up_cell_registry.rb:23`
- `RpBaseOrgStepUpStateTransition` — `class/module body` in
  `app/values/rp_step_up_cell_registry.rb:23`

Models referenced only through model associations/model source and/or tests:

`RpBaseOrgEventReceipt`, `RpBaseOrgSessionAvatarSelection`, `RpBaseOrgStepUpAuditOutbox`,
`RpBaseOrgStepUpAuditOutboxAttempt`, `RpBaseOrgStepUpAuditOutboxDeliveryState`

Models with no static runtime, model-source, association, or test reference:

`RpBaseOrgCallbackState`

## `rp_core_app` — `RpCoreAppRecord` — **USED**

6 concrete models: 1 runtime-referenced, 4 model/test-only, 1 unreferenced.

Runtime-referenced models and one caller example each:

- `RpCoreAppSession` — `class/module body` in `app/operations/rp_callback_committer.rb:132`

Models referenced only through model associations/model source and/or tests:

`RpCoreAppEventReceipt`, `RpCoreAppIdentityBinding`, `RpCoreAppOpSessionBinding`,
`RpCoreAppPrincipal`

Models with no static runtime, model-source, association, or test reference:

`RpCoreAppCallbackState`

## `rp_core_org` — `RpCoreOrgRecord` — **USED**

6 concrete models: 1 runtime-referenced, 4 model/test-only, 1 unreferenced.

Runtime-referenced models and one caller example each:

- `RpCoreOrgSession` — `class/module body` in `app/services/rp_request_authenticator.rb:26`

Models referenced only through model associations/model source and/or tests:

`RpCoreOrgEventReceipt`, `RpCoreOrgIdentityBinding`, `RpCoreOrgOpSessionBinding`,
`RpCoreOrgPrincipal`

Models with no static runtime, model-source, association, or test reference:

`RpCoreOrgCallbackState`

## `rp_edit_org` — `RpEditOrgRecord` — **USED**

6 concrete models: 1 runtime-referenced, 4 model/test-only, 1 unreferenced.

Runtime-referenced models and one caller example each:

- `RpEditOrgSession` — `class/module body` in `app/services/rp_request_authenticator.rb:28`

Models referenced only through model associations/model source and/or tests:

`RpEditOrgEventReceipt`, `RpEditOrgIdentityBinding`, `RpEditOrgOpSessionBinding`,
`RpEditOrgPrincipal`

Models with no static runtime, model-source, association, or test reference:

`RpEditOrgCallbackState`

## `rp_palm_app` — `RpPalmAppRecord` — **USED**

6 concrete models: 1 runtime-referenced, 4 model/test-only, 1 unreferenced.

Runtime-referenced models and one caller example each:

- `RpPalmAppSession` — `class/module body` in `app/services/rp_request_authenticator.rb:24`

Models referenced only through model associations/model source and/or tests:

`RpPalmAppEventReceipt`, `RpPalmAppIdentityBinding`, `RpPalmAppOpSessionBinding`,
`RpPalmAppPrincipal`

Models with no static runtime, model-source, association, or test reference:

`RpPalmAppCallbackState`

## `rp_tech_org` — `RpTechOrgRecord` — **USED**

6 concrete models: 1 runtime-referenced, 4 model/test-only, 1 unreferenced.

Runtime-referenced models and one caller example each:

- `RpTechOrgSession` — `class/module body` in `app/services/rp_request_authenticator.rb:29`

Models referenced only through model associations/model source and/or tests:

`RpTechOrgEventReceipt`, `RpTechOrgIdentityBinding`, `RpTechOrgOpSessionBinding`,
`RpTechOrgPrincipal`

Models with no static runtime, model-source, association, or test reference:

`RpTechOrgCallbackState`

## `rp_warp_app` — `RpWarpAppRecord` — **USED**

6 concrete models: 1 runtime-referenced, 4 model/test-only, 1 unreferenced.

Runtime-referenced models and one caller example each:

- `RpWarpAppSession` — `class/module body` in `app/services/rp_request_authenticator.rb:23`

Models referenced only through model associations/model source and/or tests:

`RpWarpAppEventReceipt`, `RpWarpAppIdentityBinding`, `RpWarpAppOpSessionBinding`,
`RpWarpAppPrincipal`

Models with no static runtime, model-source, association, or test reference:

`RpWarpAppCallbackState`

## `rp_warp_org` — `RpWarpOrgRecord` — **USED**

6 concrete models: 1 runtime-referenced, 4 model/test-only, 1 unreferenced.

Runtime-referenced models and one caller example each:

- `RpWarpOrgSession` — `class/module body` in `app/services/rp_request_authenticator.rb:27`

Models referenced only through model associations/model source and/or tests:

`RpWarpOrgEventReceipt`, `RpWarpOrgIdentityBinding`, `RpWarpOrgOpSessionBinding`,
`RpWarpOrgPrincipal`

Models with no static runtime, model-source, association, or test reference:

`RpWarpOrgCallbackState`

## Abstract Record classes without direct concrete model ownership

- `ApplicationRecord` has the `primary` connection, but no concrete application model is assigned
  directly to it; concrete models use dedicated child Record classes. Direct concrete-model
  classification: **UNUSED**.
- `SearchRecord` is connected to `search`, with no concrete model descendants. Classification:
  **UNUSED**.
- `queue` and `storage` are config/database.yml keys without app-owned abstract `*Record` classes
  under `app/models`; they are outside this report.
- `AppPrincipalRecord`, `OrgPrincipalRecord`, `AppRpRecord`, and `OrgRpRecord` are abstract grouping
  classes without their own `connects_to`; their descendants are reported under the configured
  parent Record database.

## 4. Foreign-looking code and configuration retained

- Public Auth service/staff origins remain external dependencies of Edit's OIDC redirect and
  authentication boundary behavior.
- Public Visa service/staff origins remain external OIDC issuer inputs for Edit.
- Public Base domain origins remain inputs to retained preference-token and mail-link contracts.
  These origins do not add local routes.
- `RpPrincipalPolicy` remains because `RpPrincipal#policy_class` resolves it dynamically for Edit RP
  authorization; a focused integration test exercised the live Edit path.
- The `/rails/performance` path remains only in the mounted-engine negative invariant; it is not a
  route or compatibility shim.
- Mission, Flipper, Blazer, PgHero, Swagger, and conditional Coverband remain as the README-owned
  operator tools. Their hardcoded host source locations are listed above.

## 5. Verification and remaining failures

| Command                           | Result                                                                 |
| --------------------------------- | ---------------------------------------------------------------------- |
| `bin/rails zeitwerk:check`        | PASS — `All is good!`                                                  |
| `bin/rails routes`                | PASS — 382 emitted route entries; no Turbo navigation routes           |
| `bin/rubocop`                     | PASS — 3,066 files inspected, no offenses                              |
| `bundle exec erb_lint --lint-all` | PASS — 867 ERB files, no errors                                        |
| `bin/rails test`                  | FAIL — 9633 runs, 51417 assertions, 117 failures, 2495 errors, 0 skips |

The suite was already failing before the surface removals: its pre-cleanup dirty-worktree run
reported `12236 runs, 60950 assertions, 223 failures, 3609 errors, 0 skips`. Current failures remain
concentrated in model/database contract tests (including NOT NULL and column-length validations),
browser RP authentication, and sign-in/OIDC/WebAuthn flows.
`Security::PublicEntrypointInventoryTest` still reports the pre-existing open `/sign/interruption`
classification gap. Every distinct missing-constant name extracted from the current `NameError`
failures also appeared in at least one earlier recorded full-run log; this is evidence of inherited
test failures, not proof that every remaining failure is pre-existing. A separate failing-run
comparison is limited because both the baseline and current results include substantial uncommitted
work and the current test inventory is smaller after retired-controller cleanup. Previously passing
focused runs were: the OIDC assertion and RP readiness pair (19 runs, 81 assertions), the registered
RP logout matrix (2 runs, 33 assertions), the outbox dispatch job (16 runs, 149 assertions), and the
focused session-cookie config test (10 runs, 10 assertions).

The required full suite was run against test databases. No development database was dropped. No
secrets or environment values are recorded here.
