# Press Surface URL Dependencies

Status: implementing. Accepted by the owner's repository-scoped task on 2026-11-10.

## Purpose and scope

Remove copied surface URL readers/configuration that Press no longer needs after the repository
split. Ownership follows
[the Sphere decision](../../adr/cosmos-sphere-surfaces-and-rp-independence.md) and
[Press route ownership](../cosmos-press-route-ownership/spec.md), checked against current routes.
Keep Access AUTH inputs, actual OIDC/protocol dependencies, and Press's Edit/Info/Docs/News/Help
inputs across their currently routed audiences. No credentials, databases, external systems or
commits are in scope. Preserve unrelated worktree changes.

## Acceptance

- AC-1: Press boot and its local OIDC/Jump catalogs no longer read CORE/WARP/PALM/GUID/TECH URL
  inputs, retired VISA corporate inputs, or unused private/network/developer BASE inputs.
- AC-2: Removing those definitions leaves no runtime ENV lookup requiring them. Definitions and
  current documentation are updated together wherever the filesystem permits; blocked writes remain
  explicitly incomplete.
- AC-3: Access AUTH URLs, Visa app/org issuer/callback dependencies, public BASE preference-domain
  anchors and outbound mail-link dependencies, and all Press-owned content audiences remain intact.
- AC-4: Foreign surfaces are not admitted as Press surfaces through host authorization/FQDN
  availability configuration. Edit remains the only local OIDC client and gains no Jump issuer
  authority; existing foreign namespaces and clients are refused.
- AC-5: Run RuboCop and affected tests; verify actual environment construction separately and record
  commands, revision, uncommitted scope, results and blockers in evidence.

## Risks and verification

Retaining an obsolete redirect origin could widen authority; removing an Access protocol dependency
could break Edit sign-in. Tests cover client/realm rejection, signed targets, registered Press hosts
and preserved preference behavior. Host/configuration construction is verified by direct boot rather
than adding environment-construction tests. Shared preference-domain anchors and identity mail-link
contracts are retained; replacing them is outside this removal.

Recovery is a scoped source/configuration correction with the retained required inputs. No shared or
persisted state is changed and no production deployment is authorized.

## Verification disposition (2026-11-10)

AC-1, AC-3 and AC-4 have scoped source, behavior-test and actual development-Rack evidence. AC-2
remains incomplete for the read-only CI file (44 definitions); writable definitions and current docs
were updated. AC-5 checks ran: full RuboCop and the final 418-test affected collection passed. A
separate unchanged logout integration still disagrees with existing no-hint logout code and was
reported rather than changed. See the
[evidence](../../evidence/2026-11-10-press-surface-url-readers-P8U4.md). The change remains open for
the CI blocker; it is not marked verified or closed.
