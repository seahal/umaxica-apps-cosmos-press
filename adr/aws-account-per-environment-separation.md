# Separate AWS Accounts for Production, Staging and Development (2026-11-19)

## Status

Accepted (2026-11-19, owner). Not implemented. The current AWS account layout has not been
inventoried: whether today's production and development credentials belong to one account is
unknown. The same record is kept in each of the four Cosmos repositories (Access, Governance, Press
and Sphere); only the "This repository" section differs.

## Context

The Cosmos applications use AWS for outbound email (Amazon SES over SMTP), SMS (Amazon SNS), object
storage (Amazon S3) and, per `adr/cosmos-jwt-ps256-and-op-signing-in-aws-kms.md`, signing keys (AWS
KMS). Every environment reads the same credential names, such as `AWS_SES_SMTP_USERNAME` and
`AWS_SES_SMTP_PASSWORD`, so the code does not show which AWS account an environment reaches.

Several properties that matter for these services are scoped to an AWS account:

- SES sending reputation (bounce and complaint rates) is measured per account and Region. Test
  traffic from development or staging can lead AWS to pause sending for the whole account, which
  would stop production OTP delivery and therefore sign-in.
- SES and SMS sandbox status, sending quotas and SMS spend limits are set per account.
- IAM credentials and KMS keys are authorized within an account. Development credentials live on
  developer machines and in local configuration; if they belong to the production account, a leak
  lets anyone send mail or SMS as production, or use production keys and data.
- This system responds to a key or credential leak by stopping the affected service, not by
  continuing to operate. Stopping only the affected environment requires the environments to be
  separate.

On 2026-11-19 Access development email delivery failed with SES SMTP authentication error
`535 Authentication Credentials Invalid`. Reissuing those credentials is the first point at which
this decision can be applied.

## Decision

1. Production, staging and development each use their own AWS account. No environment runs
   workloads, stores data or holds keys in another environment's account.
2. Credentials, IAM roles, KMS keys, S3 buckets, SES identities and SNS resources are issued per
   environment account. A credential issued for one environment must not be configured in another.
   Production credentials are never placed on developer machines.
3. The development and staging accounts keep SES and SMS in their sandbox, so they can send only to
   verified recipients. Only the production account requests SES production access and SMS
   production use.
4. Each account sets its own SMS spend limit and SES sending limits, sized for that environment.
5. Local development does not need AWS for ordinary work. It may use an emulator
   (`adr/aws-emulator-podman-staging-environment.md` in Access) or Rails file delivery for mail. The
   development account is used when real delivery or a real AWS API must be exercised.
6. A credential or key leak is handled by disabling the affected environment account's credentials
   and keys. The other environments keep operating.
7. Development email is sent from `fake.umaxica.app` (App) and `fake.umaxica.org` (Org), verified as
   SES domain identities in the development account only. The application reads each sender address
   from an environment variable with no code default; production keeps its `umaxica.app` and
   `umaxica.org` senders. The `dev.` subdomain is not used because it is easily confused with the
   separately owned `umaxica.dev` domain, both when reading mail and when editing DNS or IAM sender
   restrictions. The DKIM records belong in the `umaxica.app` and `umaxica.org` Cloudflare zones as
   DNS-only (unproxied) CNAMEs.

## Not Decided Here

- Whether the four repositories share one account per environment or each repository also has its
  own account per environment.
- Use of AWS Organizations, a management account without workloads, and IAM Identity Center for
  human access. These are the expected structure but have not been approved.
- The staging sending domain. A separate subdomain would keep its DKIM and reputation apart from
  production; avoid names that resemble other owned domains, as decision 7 does for development.
- Account IDs, Regions per environment, and the migration order.
- AWS-less Sphere Regions, which remain open in `adr/cosmos-jwt-ps256-and-op-signing-in-aws-kms.md`.

## Consequences

- Before implementation, inventory which account each environment's SES, SNS, S3 and KMS resources
  and credentials belong to, recording account aliases only, never secrets.
- If production and any other environment share an account today, move the non-production
  environment to its own account and then rotate the credentials it held.
- Each non-production account must verify its own sender identities and test recipients. Production
  access requests and limit increases are per account and take AWS review time.
- Credential configuration stays per environment; the existing variable names are unchanged.

## This repository

Press uses SES SMTP for email, S3 for object storage (`lib/object_storage_shrine_configuration.rb`)
and, per the PS256 record, KMS for its RP signing key. Each environment's S3 buckets belong to that
environment's account.
