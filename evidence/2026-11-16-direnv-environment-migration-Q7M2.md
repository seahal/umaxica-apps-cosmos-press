# Local direnv environment migration

HEAD: `ec34b0a5750c75dc0765fa8ae9e585e3be1ab4d5`. The checks used the changed worktree, which also
contained pre-existing uncommitted changes.

- Compared the old loader's parsed assignments against the exported environment using the direnv
  Bash standard library. All 158 retained assignments matched, without displaying their values. The
  obsolete container TMPDIR, RUBY_PATH, and DEVCONTAINER were excluded from the comparison.
- Checked shell syntax and Git ignore rules. The credential file mode is 0600. Verified that Valkey
  and object storage client ports match the configured host port overrides.
- Rails runner booted in development and test with RUBY_DEBUG_OPEN unset for these checks. The
  initial development boot hit the sandbox restriction on debugger Unix socket binding.
- No direnv approval was changed. Compose, Vite, and the full CI suite were not run.
