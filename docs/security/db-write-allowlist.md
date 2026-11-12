# DB Write Allowlist

> **Route boundary update (2026-11-10):** The local Auth and Base controllers, plus their social and
> identity callbacks, were removed. This allowlist covers the retained Edit, Docs, Help, Info, News,
> and operator-tool routes. Persisted models and migrations remain for a separate review.

## Purpose

Normal `GET` and `HEAD` requests should be read-only unless the write is an explicit lifecycle
exception. This allowlist records the current accepted exceptions so future CI can fail any
unreviewed `INSERT`, `UPDATE`, or `DELETE` observed during read-only request tests.

The database remains the source of truth. JWTs are projections or runtime credentials, not an
authority to invent new state.

## Current Allowlist

| ID  | Classification               | Request phase             | Expected write                                                                              | GET/HEAD lifecycle exception? | Current scope                    |
| --- | ---------------------------- | ------------------------- | ------------------------------------------------------------------------------------------- | ----------------------------- | -------------------------------- |
| W8  | Preference explicit update   | Preference write endpoint | Persist an intentional preference update from PATCH/PUT/DELETE/POST.                        | No                            | non-GET preference endpoints     |
| W9  | Preference reset/rebootstrap | Preference reset endpoint | Retire or replace the current shared preference and rebootstrap a fresh preference.         | No                            | explicit reset/delete endpoint   |
| W16 | OIDC callback                | Edit ORG RP callback      | Validate the external issuer response and commit the retained Edit RP callback lifecycle.   | No                            | Edit ORG OIDC callback endpoints |
| W18 | Maintenance or repair task   | Explicit operator task    | Repair, admin, or maintenance writes performed outside ordinary read-only request handling. | No                            | explicitly invoked tasks only    |

The former W1-W7 preference GET writes and W14-W15 authentication GET writes were removed from the
allowlist on 2026-09-25 after checking the current request lifecycle. `set_preferences_cookie`
returns through read-only preference loading for `GET`/`HEAD`; `transparent_refresh_allowed?`
rejects browser navigation; and authenticated session activity tracking defaults off for
`GET`/`HEAD`. The preference transport and authentication refresh records are changed only at their
explicit write endpoints. W16 remains the Edit ORG RP callback write boundary.

W10-W13 and W17 were retired with the local Base/Auth/Visa controller routes on 2026-11-10. Their
cookie, theme, preference-adoption, social-login, and Visa callback writers are not current Press
request paths. W16 remains for the independent Edit ORG RP callback.

## CI Direction

Future CI should subscribe to SQL and fail `GET`/`HEAD` request tests when `INSERT`, `UPDATE`, or
`DELETE` appears outside this allowlist. A new write path must update this document before the test
allowlist expands.

The allowlist is intentionally behavioral. It does not grant permission to move writes into generic
controller setup, to repair broken JWTs from the database on normal reads, or to introduce hidden
state changes behind read-only routes.
