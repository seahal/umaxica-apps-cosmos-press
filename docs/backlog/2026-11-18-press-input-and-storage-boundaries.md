# Press input handling, outbound URLs and file storage

Static review of `57c72d323dd157fcacd7aef2e145d9bf0d8132e6`. The inspected Press routes yielded no
confirmed path from a request to injected SQL, executable markup, shell execution, an arbitrary
outbound host or an arbitrary filesystem path. The scope covers application-owned handlers. Network
reachability, bucket policies and downstream consumers of published JSON still require deployment or
consumer evidence.

## Queries and output

| Input and destination                                                 | Observed behavior                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |
| --------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Public collection filters and entry reference to PostgreSQL           | The controller selects the model from its declared cell and passes locale, category and tag to the query. Active Record hash predicates bind the values. The sort columns and taxonomy associations come from application code. A detail lookup checks the locale, public ID, archive state and active publication. [Controller](../../app/controllers/concerns/publishing_content_rendering.rb#L155), [detail lookup](../../app/queries/publishing_published_entries_query.rb#L36), [taxonomy filter](../../app/queries/publishing_published_entries_query.rb#L66) |
| Title, summary and structured body to API or HTML                     | The public serializer selects fields from the published version and the controller renders JSON. The Edit template interpolates the summary and pretty-printed body using escaped ERB expressions. Rendering this JSON as HTML in another application would introduce a new output boundary. [Serializer](../../app/serializers/publishing_entry_serializer.rb#L28), [JSON response](../../app/controllers/concerns/publishing_content_rendering.rb#L88), [Edit template](../../app/views/edit/org/publishing/entries/show.html.erb#L122)                           |
| Request strings to templates, application processes and deserializers | The inspected Press handlers exposed no request-selected template source, shell command, Ruby or JavaScript evaluation, unsafe object deserialization, or client-side HTML insertion sink. Model configuration uses fixed Ruby blocks. The inventory script loads a local YAML file and invokes a fixed tool with arguments. [Template selection](../../app/controllers/concerns/publishing_management_cell.rb#L111), [model configuration](../../app/models/concerns/publishing_entry_record.rb#L13), [inventory tool](../../lib/architecture_baseline.rb#L37)     |
| Search, email, CSV, Markdown and HTTP headers                         | Article filtering uses relational predicates. The review found no public NoSQL query builder, Markdown-to-HTML evaluator, CSV export or mail composition action consuming these inputs. Dynamic navigation headers use Rails redirects. The OIDC return target rejects control characters through its restricted path grammar. [Query](../../app/queries/publishing_published_entries_query.rb#L94), [return path](../../app/values/rp_target_link_uri.rb#L10), [callback redirect](../../app/controllers/concerns/oidc_callback.rb#L168)                           |

## Outbound requests and redirects

The Publishing client builds an origin from boot configuration, takes the surface and audience from
controller constants, and URL-encodes entry and publication references. The OIDC client gets its
JWKS URL from the configured issuer. Faraday does not follow redirects in this builder. Request
input could not select a destination host in these paths.
[Publishing caller](../../app/controllers/concerns/publishing_management_cell.rb#L69),
[URL construction](../../app/adapters/publishing_authority_client.rb#L30),
[reference encoding](../../app/adapters/publishing_authority_client.rb#L94),
[JWKS client](../../app/adapters/oidc_op_jwks_client.rb#L42),
[transport](../../app/lib/outbound_http/connection.rb#L28)

The registered back-channel logout sender explicitly enables the public-address check. Its adapter
checks every DNS answer and connects to a selected validated IP. The exclusions include loopback,
private and link-local IPv4, and non-global IPv6. Fixed recipients such as the Edit authority and OP
JWKS use their configured hosts without this check. The actual egress firewall, private DNS and
metadata service were outside this review. Reassess host ownership and connection-time address
checks if an endpoint becomes configurable by a user or tenant.
[Logout sender](../../app/adapters/oidc_backchannel_logout_client.rb#L17),
[address check and pinning](../../app/lib/outbound_http/connection_adapter_port.rb#L31),
[JWKS transport](../../app/adapters/oidc_op_jwks_client.rb#L224)

The RP normalizes its browser return target to a local path. Cross-host OIDC navigation uses the
configured authorization endpoint and a separate decision before redirecting. No user-controlled
open redirect was established. [Target validation](../../app/values/rp_target_link_uri.rb#L13),
[OIDC initiation](../../app/controllers/concerns/oidc_sso_initiator.rb#L92),
[authorization endpoint](../../app/values/oidc/acme_service_origin.rb#L106)

## Files and uploads

The repository has a Publishing media attachment model. No inspected HTTP action accepts `file` or
`file_data` for that model or serves a file from a request-selected local path. The configured
Shrine uploader validates detected JPEG, PNG, WebP or GIF content and a 10 MiB size limit. Object
keys use the record identity and random bytes and omit the original filename. If a web upload or
presign route is added, recheck owner authorization, cached metadata trust, pre-storage resource
limits and the delivery origin. [Attachment model](../../app/models/publishing/media_file.rb#L10),
[MIME detection](../../config/initializers/shrine.rb#L18),
[size and MIME policy](../../app/uploaders/publishing_media_uploader.rb#L4),
[key generation](../../app/uploaders/application_uploader.rb#L90)

For diagnostics, see [errors and sensitive logs](2026-11-18-press-errors-and-sensitive-logs.md). The
earlier
[URL and upload follow-up](../../plans/backlog/2026-10-22-url-path-upload-security-followups.md)
records earlier scope and assumptions; the opt-in public-address check above is present in this
revision.
