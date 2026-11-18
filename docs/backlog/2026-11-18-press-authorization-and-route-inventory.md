# Press authorization and reachable routes

Deferred for owner review.

Review date 2026-11-18. Source revision `57c72d323dd157fcacd7aef2e145d9bf0d8132e6`. The review
included the working tree with an existing change to `compose.yaml`. Route ownership, controller
admission and database selection below describe this revision. The production boot guard raises
before Rails can serve requests. Public DNS, edge policy and any deployed revision require separate
evidence. [Boot guard](../../config/application.rb#L93)

## Application routes

The twelve public content hosts pair one of Docs, Help, Info and News with one of app, com and org.
Edit org is the staff relying party. A process role selected from configuration decides which
controllers it serves. Earlier local role inspection also confirmed refusal for the diagnostic
controllers listed below. [Surface matrix](../architecture/content-surface-matrix.md#L7) ·
[Role ownership and admission](../../lib/runtime_role.rb#L83)

| Host and HTTP route                                                                                                                         | Anonymous reachability and server-side check                                                                                                                                                                                                                                                                                                                                                                                                                   |
| ------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| All twelve content hosts, GET `/api/v0/entries` and `/api/v0/entries/:public_id`                                                            | Published content for the selected host, including org-audience publications. The read and serialization constraints are detailed below. [Content routes](../../config/routes/info.rb#L22)                                                                                                                                                                                                                                                                     |
| All twelve plus Edit, GET `/health`, `/health/{startup,liveness,readiness}`, `/api/v0/health.json`, `/revision` and `/api/v0/revision.json` | Rails serves health or deployment metadata without user credentials, subject to process and availability checks. The operations guide calls the machine JSON endpoints internal but lists only the text health paths in the edge block. A separate deployed rule could cover the JSON paths. [Edit routes](../../config/routes/edit.rb#L15) · [Documented block](../operations/health-check.md#L38)                                                            |
| All twelve plus Edit, POST `/csp-violation-report`                                                                                          | Browser telemetry uses a bounded body and a request counter. It has no account or session mutation. [Intake](../../app/controllers/concerns/csp_violation_report.rb#L13)                                                                                                                                                                                                                                                                                       |
| Edit, GET `/`, GET and POST `/sign`, GET `/sign/interruption`                                                                               | Public landing and sign-in UI. GET displays the sign form. The CSRF-protected POST starts an external OIDC flow. [Edit routes](../../config/routes/edit.rb#L49) · [Sign actions](../../app/controllers/concerns/oidc_rp_sign_entry.rb#L11)                                                                                                                                                                                                                     |
| Edit, GET `/oidc/callback` and POST `/oidc/closures`                                                                                        | A callback can arrive before login and must match the pending flow. Closure uses the configured OP's signed logout token and the local cell. An anonymous caller cannot choose a session to revoke by supplying its ID. [Callback](../../app/controllers/concerns/oidc_callback.rb) · [Closure receiver](../../app/controllers/concerns/rp_backchannel_logout_endpoint.rb#L15)                                                                                 |
| Edit, GET `/sign/out`, `/sign/out/new`, `/sign/out/edit` and `/sign/out/completion`; POST `/sign/out`                                       | Entry and confirmation screens are accessible without an active identity. Completion checks the browser-bound sign-out notice. The POST resolves the local session and enforces browser request protection before revocation. [Routes](../../config/routes/edit.rb#L68) · [Session requirement](../../app/controllers/edit/org/sign/outs_controller.rb#L33) · [Completion](../../app/controllers/concerns/oidc_rp_logout_launcher.rb#L85)                      |
| Edit, GET `/dashboard`, GET/POST `/verification` and the twelve `/publishing/…` management areas                                            | Private routes. Dashboard authorizes the current operator. Step-up currently answers unavailable after authorization. Publishing UI requires the Edit session and calls the authority for reads and writes. [Dashboard](../../app/controllers/edit/org/dashboards_controller.rb#L7) · [Verification](../../app/controllers/edit/org/verifications_controller.rb#L12) · [Management boundary](../../app/controllers/concerns/publishing_management_cell.rb#L43) |
| Edit, management API under `/api/v0/publishing/:surface/:audience/entries`                                                                  | Routes exist for listing, detail, creation, update, archive/unarchive and publication creation/termination. Each API controller returns 503 before the action while Governance is unavailable. [Routes](../../config/routes/edit.rb#L31) · [Refusal](../../app/controllers/concerns/publishing_authority_api_endpoint.rb#L23)                                                                                                                                  |
| Content roots and other admitted hosts without an assigned root, GET `/`                                                                    | The final root answers 404 with the fixed `unknown_host` error. Public browser homepages for the four content families live outside Rails. [Fallback route](../../config/routes.rb#L32) · [Response](../../app/controllers/unknown_hosts_controller.rb#L24)                                                                                                                                                                                                    |

## Ownership and authority

Public article retrieval starts with a host-constrained controller and its fixed entry model. The
detail query applies locale and public ID, then checks archive state and active publication. The
index joins the active publication scope. The publication must have started, remain within its
effective window and have no cancellation timestamp. The serializer reads the published version and
frozen taxonomy, so an unpublished draft, an archived article or an ID from a different cell does
not grant private content through this path.
[Controller](../../app/controllers/info/org/api/v0/entries_controller.rb#L13) ·
[Queries](../../app/queries/publishing_published_entries_query.rb#L36) ·
[Window](../../app/models/concerns/publishing_publication_record.rb#L23) ·
[Serializer](../../app/serializers/publishing_entry_serializer.rb#L28)

The Edit dashboard policy compares the authenticated local principal to the record. Publishing
requires an active Edit principal and an authoritative Governance decision. Current management
requests stop before entry lookup, including requests with otherwise valid credentials. The
unreachable action code selects from twelve fixed models, resolves the entry in that cell and
resolves the nested publication through the entry. Create/update allowlist content fields and derive
the author from the server-side operator. The inspected routes contain no user, tenant, project or
file identifier that grants an ownership override and no privilege decision based on editable
profile attributes, client storage or a caller-supplied role. Enabling Governance will require
verifying permission boundaries with distinct operators, cells and publication parents.
[Principal policy](../../app/policies/rp_principal_policy.rb#L9) ·
[Publishing policy](../../app/policies/publishing_entry_policy.rb#L21) ·
[Cell and entry selection](../../app/controllers/concerns/publishing_authority_api_endpoint.rb#L28)
· [Entry writes](../../app/controllers/edit/org/api/v0/publishing/entries_controller.rb#L40) ·
[Parent-scoped publication](../../app/controllers/edit/org/api/v0/publishing/publications_controller.rb#L44)

## Framework, operator and storage surfaces

- **WebSocket.** Press loads Action Cable. The locked Rails engine mounts its default `/cable` Rack
  endpoint. Connection admission includes an Origin check. The inventory found no
  application-defined channel or stream publisher. The bundled Turbo Streams channel verifies the
  signed stream name before subscription. Development can additionally mount `/hotwire-spark` when
  its feature switch is enabled and broadcast change notifications with paths. The controller
  ownership guard does not inspect Rack sockets. Decide whether either socket serves a required
  client on each exposed host. [Engine load](../../config/application.rb#L13) ·
  [Rails pin](../../Gemfile.lock#L32) · [Spark switch](../../config/environments/development.rb#L14)
- **Controller-based tools.** Local role inspection denied the controller paths for `Rails::Info`,
  `Rails::Mailers`, `Blazer::Queries`, `PgHero::Home` and `MissionControl::Jobs::Queues`. Even the
  shared role rejects unowned controllers. Blazer, PgHero and Mission also configure credentials. A
  development exception page is rendered through a different path and can still expose diagnostics
  when the development origin is reachable. [Guard](../../lib/runtime_role_route_guard.rb#L15) ·
  [Role mapping](../../lib/runtime_role.rb#L96) · [Operator mounts](../../config/routes.rb#L12) ·
  [Development exceptions](../../config/environments/development.rb#L21)
- **Rack operator surfaces.** Flipper wraps its feature-flag UI in HTTP Basic authentication.
  Coverband wraps its development source-coverage display in a credential check. Development Swagger
  serves UI and OpenAPI documents on separately protected mounts. Each has a dedicated host. Actual
  edge access, stored credentials and conditional mounts in a running service require deployment
  evidence. [Flipper](../../config/routes/flipper.rb#L15) ·
  [Coverband](../../config/routes/coverband.rb#L28) · [Swagger](../../config/routes/swagger.rb#L25)
  · [UI protection](../../config/initializers/rswag_ui.rb#L50) ·
  [Document protection](../../config/initializers/rswag_api.rb#L29)
- **Storage and other protocols.** Rails disables Active Storage routes, including direct upload and
  blob access. The application route tree contains no GraphQL, RPC, MCP or Server Action endpoint.
  Storage provisioning and bucket access have separate controls. This review did not establish live
  bucket policy or external storage reachability. [Storage routes](../../config/application.rb#L104)
  · [Application route tree](../../config/routes.rb#L4) ·
  [Object storage](../../terraform/modules/object_storage/main.tf)

## Backlog decisions

Reconcile the maintained entrypoint inventory with the actual content root fallback, management 503,
framework mounts and role refusals. Its automated inventory selects routes by application controller
prefix, which excludes Rack and framework routes. Confirm effective edge protection for the JSON
health and revision endpoints and the intended development diagnostic exposure in the deployed
environment. Record the deployment revision and origin protections before changing their exposure
classification. [Current inventory](../security/public-entrypoints.md#L8) ·
[Inventory filter](../../test/unit/security/public_entrypoint_inventory_test.rb#L75) ·
[Health policy](../operations/health-check.md#L13)
