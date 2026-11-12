# Operator Capability CLI Runbook

This runbook covers the Press-owned bootstrap and status commands for org administrative
capabilities. Browser-based IAM workflows are not part of this application.

## Chronicle retention prerequisite

Bootstrap writes a Chronicle intent row and fails when it cannot. The target Chronicle database
needs a `chronicle_retention_policies` row with code `compliance`. Migration
`db/chronicle_migrate/20260926130000_insert_compliance_chronicle_retention_policy.rb` creates the
row with the approved retention period. A database built only from `db/chronicle_structure.sql` does
not receive it; run the migration before using the command.

## Bootstrap

Bootstrap the IAM capabilities for one existing operator. The command grants to the explicitly named
operator; it does not grant to all operators or to the first person who signs in.

```bash
bin/rails operator_capabilities:bootstrap \
  OPERATOR=<operator public id> \
  CAPABILITIES=iam.capability.read,iam.capability.grant,iam.capability.revoke \
  TICKET=<change ticket id> \
  EXPIRES_AT=<ISO 8601 time, at most 366 days ahead>
```

Run first with `DRY_RUN=true` to validate the inputs without writing. The command fails closed for
missing or invalid values, an ineligible operator, unknown capabilities, an existing in-force grant,
or an unavailable Chronicle intent writer. Successful output contains the grant public identifiers
and audit event identifier.

## Status

```bash
bin/rails operator_capabilities:status
bin/rails operator_capabilities:status OPERATOR=<operator public id>
```

`eligible=false` means the grant remains recorded but currently confers no capability because of the
operator's state. Grant lifecycle and browser administration outside these CLI commands belong to
the owning repository.
