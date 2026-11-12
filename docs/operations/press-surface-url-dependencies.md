# Press Surface URL Dependencies

Press serves Edit ORG, Docs, Help, Info, News and its operator tools. Route ownership is listed in
the [Press route decision](../../specs/cosmos-press-route-ownership/spec.md) and
[surface hard-reset report](../../specs/press-surface-hard-reset/spec.md).

## Retained inputs

| Inputs                                                                                                               | Local use                                                                                               |
| -------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------- |
| `PUBLIC_AUTH_SERVICE_URL`, `PUBLIC_AUTH_STAFF_URL`                                                                   | External Auth origins used by Edit redirects, authentication boundaries and host-derived configuration. |
| `PUBLIC_VISA_SERVICE_URL`, `PUBLIC_VISA_STAFF_URL`                                                                   | External OIDC issuer origins used by Edit authorization-code and refresh flows.                         |
| `PUBLIC_BASE_SERVICE_URL`, `PUBLIC_BASE_CORPORATE_URL`, `PUBLIC_BASE_STAFF_URL`                                      | External Base domain inputs used by shared preference-token verification.                               |
| `PUBLIC_EDIT_STAFF_URL`, `PRIVATE_EDIT_STAFF_URL`                                                                    | Edit ORG's local host configuration.                                                                    |
| `PUBLIC_*_{SERVICE,CORPORATE,STAFF}_URL` and `PRIVATE_*_{SERVICE,CORPORATE,STAFF}_URL` for Docs, Help, Info and News | The four owned content surfaces' host configuration.                                                    |
| `PRIVATE_{MISSION,FLIPPER,BLAZER,PGHERO,COVERBAND,SWAGGER}_URL`                                                      | Owned operator-tool host constraints.                                                                   |

Public Auth, Visa, and Base URLs are outbound dependencies of retained Edit behavior. Private Auth
host readers used only for local session-cookie setup and redirect allowlisting were removed. These
origin values do not add local Press routes. The external provider owns token issuance and
refresh-token family policy; see
[OIDC refresh at the Edit RP](../security/refresh-token-rotation.md).

## Retired local configuration

The local CORE, WARP, PALM, GUID and TECH surfaces and their URL readers were removed. So were the
local Auth/Base/Visa route trees, foreign edge and performance hosts, private Base inputs, and
corporate/private Visa inputs that had no retained caller. Models and migrations remain unchanged
for the separate database review.

`.env` and `.env.container.devcontainer` were cleaned locally. The CI workflow still contains
references to retired URL and performance variable names; its filesystem mount is read-only in the
current environment, so those entries could not be updated. The final evidence records the names
without values.

The route inventory and hardcoded operator-tool hosts are recorded in the
[surface hard-reset evidence](../../evidence/2026-11-10-surface-hard-reset-A7K2.md). No database was
dropped.
