# Development dashboard credentials and operator access

**Decision pending.** High priority for any development origin reachable beyond a trusted operator.

The tracked development environment supplies nonempty Basic Auth usernames and passwords for
Flipper, Blazer and PgHero. Local files load afterward and can override them. The pinned Rails
credential resolver reads the environment before encrypted credentials. The application therefore
accepts the tracked Flipper pair at its Basic Auth boundary when no override is present. A caller
who can reach that origin and authenticate can read and change feature flags. No credential values
or successful access attempts were collected for this record. [Usernames](../../.envrc#L54) ·
[Passwords and override order](../../.envrc#L220) ·
[Flipper Rack authentication](../../config/routes/flipper.rb#L15)

Blazer and PgHero also read these values in their engine middleware. Development runtime inspection
showed that the application role guard denies the Blazer queries and PgHero home controllers.
Mission's queues controller was likewise denied. Flipper is a mounted Rack application outside that
controller guard. The three fixed credential pairs therefore have different consequences.
[Blazer](../../config/initializers/blazer.rb#L23) ·
[PgHero](../../config/initializers/pghero.rb#L19) ·
[Role guard](../../lib/runtime_role_route_guard.rb#L15) ·
[Role ownership](../../lib/runtime_role.rb#L83)

The working-tree Compose configuration starts the development tunnel with the rest of the stack.
Cloudflare Access policy, hostname publication and local credential overrides were unverified. The
worker VPC connector has a distinct purpose and its presence alone does not establish a public
hostname. [Connectors](../../compose.yaml#L271)

**Decision for the development owner.** Determine which dashboards should operate remotely and
whether any instance used the tracked credentials. If replacement is selected, provision unique
credentials outside Git, retire previously accepted values and verify that missing credentials deny
access. Include both the origin and the edge in that decision. The separate historical disclosure
concerns an earlier incident.
[Credential provisioning backlog](2026-11-10-secrets-from-credentials-only.md) ·
[Earlier disclosure record](2026-11-11-credential-exposure-disclosure.md)
