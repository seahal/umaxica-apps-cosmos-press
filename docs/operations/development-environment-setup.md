# Development Environment Setup

Status: draft. Environment construction has not been verified as part of the surface hard reset.

This guide covers the local Rails application. It does not start or configure services owned by the
other Cosmos repositories.

## Host prerequisites

Install Podman 5 or newer, `podman-compose`, VS Code and the Dev Containers extension. Apply the
one-time host configuration in
[devcontainer-cli-podman-startup.md](devcontainer-cli-podman-startup.md); Podman-specific notes are
in [container-engine-podman-notes.md](container-engine-podman-notes.md).

## Local configuration

Obtain the development and test Rails credential keys through the development lead. The tracked
`.env.container.devcontainer` file lists the names expected by the container. Keep provider secrets
in encrypted Rails credentials and do not copy secret values into environment templates.

The local Rails routes cover Edit org, Docs, Help, Info, News and the Press operator tools. The
route host families are summarized in [the README](../../README.md). Compose and CI own additional
container and pipeline configuration; consult their checked-in definitions when changing setup.

## Database setup

Database creation, migration and test preparation are covered by [db-workflow.md](db-workflow.md)
and [test-environment.md](test-environment.md). This guide does not authorize dropping or resetting
databases.

## Edit sign-in

Edit is the only local browser relying party. Its OIDC sign-in depends on externally operated Auth
and Visa services. Their provider-side setup and credentials are owned outside this repository;
coordinate with those owners before attempting an end-to-end sign-in.

## Verification

After configuration, start the Dev Container and confirm the retained hostnames resolve to the Rails
service. Run `bin/rails routes` to inspect the local route set and follow the checks in
[the test environment guide](test-environment.md) for Rails behavior.
