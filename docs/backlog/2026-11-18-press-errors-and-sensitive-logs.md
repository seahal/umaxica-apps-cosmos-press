# Press error responses and sensitive request logs

Static review of `57c72d323dd157fcacd7aef2e145d9bf0d8132e6`. Two configuration-dependent exposure
paths warrant follow-up. No production log, error-tracker event or deployment response was
inspected.

## Malformed JSON can reach DEBUG logs before redaction

The Rack size middleware forwards accepted JSON bodies to Rails for parsing. When parsing fails, the
pinned Action Pack code logs the raw request body at DEBUG. A malformed request that contains a
token, password or personal information can therefore leave that content in a log even when its
parameter name is on the filter list. The production logger writes to stdout. Its default INFO level
suppresses this message, while a DEBUG deployment emits it.
[Request handling](../../lib/request_body_size_limit.rb#L25),
[pinned Rails revision](../../Gemfile.lock#L32),
[Action Pack parser at that revision](https://github.com/rails/rails/blob/9ba8b1edeeacccb1ff5d2497432242eeddf48aed/actionpack/lib/action_dispatch/http/parameters.rb#L105-L120),
[production logger and level](../../config/environments/production.rb#L59)

Record which deployments accept real credentials while running at DEBUG and which sinks receive
stdout. A fix should retain the parse failure and correlation ID while omitting raw payloads. Verify
with synthetic data at DEBUG so the result applies during incident diagnosis as well as routine
operation.

## Detailed error pages depend on the environment

Development treats every request as local for exception rendering. If an allowed development host is
reachable through shared ingress, its error middleware can show framework diagnostics to the remote
caller. Production sets this flag to false. Development registration of `/rails/info` and
mailer-preview routes is a separate question. The current runtime-role guard refuses their unowned
controllers with 404, while exceptions on owned routes may still receive detailed responses. Confirm
which development or staging hosts are reachable and the effective Rails environment at those hosts.
[Development configuration](../../config/environments/development.rb#L27),
[development host permissions](../../config/environments/development.rb#L179),
[production configuration](../../config/environments/production.rb#L18),
[runtime-role guard](../../lib/runtime_role_route_guard.rb#L15)

## Response and telemetry controls reviewed

- The API exception renderer emits the registered problem type, title, status, request path and
  request ID. It omits exception text. Public content serialization selects the published version's
  public fields. The structured body is intentionally sent in full, so publishers control which
  content becomes public.
  [API error document](../../app/services/api_problem_exceptions_app.rb#L73),
  [published fields](../../app/serializers/publishing_entry_serializer.rb#L28)
- Rails parameter filtering includes passwords, contact data, tokens, cookies, assertions,
  authorization codes and OIDC state. Lograge strips query strings from its request and redirect
  paths and applies the repository path/URL scrubber. Structured application events pass through a
  redactor before JSON encoding. These filters apply at their own sinks.
  [Filter configuration](../../config/initializers/filter_parameter_logging.rb#L4),
  [Lograge configuration](../../config/initializers/lograge.rb#L54),
  [structured event formatter](../../lib/jit_log_event.rb#L9)
- Sentry disables default PII collection and scrubs request attributes, extras, tags, user context
  and breadcrumbs in its pre-send hook. OpenTelemetry configures span scrubbing and omits mail
  addresses from the mailer instrumentation. Receipt, retention and operator access at external
  collectors were unverified. Recheck those properties against deployed settings and synthetic
  events if a deployment relies on them. [Sentry hook](../../config/initializers/sentry.rb#L5),
  [OpenTelemetry configuration](../../config/initializers/opentelemetry.rb#L74),
  [observability ownership](../security/observability-boundary.md)
