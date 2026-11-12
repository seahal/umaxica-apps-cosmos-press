# UMAXICA presentation design

This document describes the current Rails HTML and CSS presentation for the Press surfaces. The app
serves ERB pages and surface-scoped stylesheets; it does not ship a React, Inertia, Stimulus, Turbo
or service-worker client.

## Surfaces

- Edit org: staff publishing and the Edit browser relying party.
- Docs, Help, Info and News: public content roots for app, com and org audiences.
- Mission, Flipper, Blazer, PgHero, Swagger and Coverband: operator tools constrained to their own
  hosts.

Every page remains within its surface's existing route, controller and authorization boundary.
Shared CSS tokens describe appearance only; they do not share request state or authority.

## Layout and typography

Use native semantic HTML, visible labels, underlined links and clear focus indicators. Place the
page purpose and primary action before secondary explanations. Keep page gutters and content width
responsive, and let long headings, URLs and display values wrap without horizontal page overflow.

Ordinary body text, labels, navigation and action labels use the default 16px size. Dense metadata
may use 14px when its secondary role is explicit. Japanese copy uses natural Japanese line breaking
and a 1.7 body line height; Latin copy uses 1.5.

## Stylesheet ownership

Each owned page loads one stylesheet under `src/styles/surfaces/`. Each stylesheet imports
`src/styles/theme.css` and `src/styles/base.css`, then scans only its matching Rails view tree. This
keeps generated CSS scoped to its page family while sharing design tokens.

The content roots are deliberately thin. The Edit layout owns the publishing and sign-out pages.
Ordinary forms and navigation use browser HTML behavior; no client-side component runtime is
required.

## Sources

The Digital Agency of Japan Design System introduction is useful reading before introducing new
screen patterns: <https://design.digital.go.jp/dads/introduction/>. The related source notes are in
`docs/reference/digital-agency-design-system.md`.
