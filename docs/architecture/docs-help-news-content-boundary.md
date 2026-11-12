# Content Surface Boundaries

Docs, Help, Info and News are separate Press surfaces. The current route, controller, view, database
and stylesheet ownership is recorded in the [content surface matrix](content-surface-matrix.md).

Each surface and audience family owns its host-constrained root, read-only entry API, health and
revision endpoints, and CSP report sink. The public roots are thin Rails pages. Content
authorization and persistence must not inherit Edit operator sessions, preferences or request state.

Publishing management belongs to Edit org. It calls the content read and management contracts as an
authenticated operator; content hosts do not expose management mutations.
