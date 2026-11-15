# mise runtime version resolution

HEAD: `ec34b0a5750c75dc0765fa8ae9e585e3be1ab4d5`. The worktree had existing changes. This check used
the updated, uncommitted `mise.toml` and the working-tree version files.

`mise ls --current --offline` with mise 2026.11.3 selected Ruby 4.0.9 from `Gemfile`, Node.js
26.13.1 from `.node-version`, and Bun 1.4.0 from `mise.toml`. The command exited successfully and
warned that its configuration tracking directory was read-only. The same check in the access
checkout selected Ruby from its `Gemfile` as well. This check did not install or run the selected
runtimes.
