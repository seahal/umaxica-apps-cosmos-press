# Press content surface matrix

The repository owns four public content families, each served independently for app, com and org.
README lists the development and public entrypoints. The route files use host constraints; audience
namespaces do not share request state or credentials.

| Family | Route file              | Controllers                           | Rails homepage         | Retained endpoints                             |
| ------ | ----------------------- | ------------------------------------- | ---------------------- | ---------------------------------------------- |
| Docs   | `config/routes/docs.rb` | `Docs::App`, `Docs::Com`, `Docs::Org` | None (`/` returns 404) | Health, revision, CSP report and read-only API |
| Help   | `config/routes/help.rb` | `Help::App`, `Help::Com`, `Help::Org` | None (`/` returns 404) | Health, revision, CSP report and read-only API |
| Info   | `config/routes/info.rb` | `Info::App`, `Info::Com`, `Info::Org` | None (`/` returns 404) | Health, revision, CSP report and read-only API |
| News   | `config/routes/news.rb` | `News::App`, `News::Com`, `News::Org` | None (`/` returns 404) | Health, revision, CSP report and read-only API |

The public browser pages are served outside Rails. Each family keeps host-local health, revision,
CSP-report and read-only `api/v0/entries` routes on its app, com and org hosts. No content family
owns authentication, preference, mutation, sign-in or article-management routes. Edit org owns
publishing management and the content API caller boundary.

All four families use the central `publishing` database through `PublishingRecord`. App, com and org
identify audience-specific content; they do not identify separate databases. This preserves the
accepted persistence contract in `adr/publishing-db-content-authority.md`.

The surface stylesheet entrypoints remain under `src/styles/surfaces/`; they are independent of the
removed Rails homepage views and continue to import the shared theme and base CSS.
