# Publish a Disclosure of the Credential Exposure on News (2026-11-11)

Owner: owner (content), Press (`news` surface). Status: decided (owner), waiting for the News
surface; publish as soon as it exists.

## What happened (facts for the notice)

Development credentials of the Cosmos applications were decryptable from public Git history from
2025-09-03: the encryption key files were committed and later removed, but history kept them. The
exposed values included third-party service credentials. They were found and handled on 2026-11-11.
Record of the investigation and response:
`umaxica-apps-cosmos-access/evidence/2026-11-11-public-history-credential-exposure-K7Q2.md`.

## The notice should state

- What was exposed (kinds of credentials, development environment), from when, and how it was found.
- What was done: credentials revoked or rotated, removed from the repositories, accounts checked.
- What was not found: no sign of misuse in the services checked; one unexplained use of an AWS key
  (2026-03-19) whose purpose could not be determined, on a key limited to sending email, with no
  email sent.
- That the service is not deployed and no user data was involved, if that remains true when the
  notice is written; confirm before publishing.
- A second exposure: development secrets in the tracked file `.env.container.devcontainer` (public
  since 2026-10-19); replaced when secrets move to credentials.
- What changes to prevent recurrence.

## Rules

- No secret values, no full key identifiers, no attack instructions.
- Confirm every statement against the evidence record before publishing.
