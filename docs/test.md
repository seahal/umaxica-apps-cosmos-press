# Test Strategy

This repository is the Rails application for Press. Its local request surfaces are Edit ORG, Docs,
Help, Info and News for app/com/org audiences, plus the operator tools listed in `README.md`.

Ruby behavior is covered with Minitest. Run the smallest suite that covers the change, then broaden
for any affected boundary:

```bash
bin/rails test test/path/to/file_test.rb
bin/rails test
```

JavaScript checks use the repository scripts:

```bash
bun run test
bun run check
```

The full CI gate is `bin/ci`. It includes test database setup and the configured static checks. Do
not drop databases as part of ordinary route or controller cleanup.
