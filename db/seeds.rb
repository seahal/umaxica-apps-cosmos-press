# typed: false
# frozen_string_literal: true

# Replay the retained Chronicle catalogs after schema-only loads.
[
  ClientChronicleEvent, ClientChronicleLevel, OperatorChronicleEvent, OperatorChronicleLevel,
  ComPreferenceChronicleEvent, ComPreferenceChronicleLevel,
].each do |model|
  connection = model.lease_connection
  table = connection.quote_table_name(model.table_name)
  model::DEFAULTS.each do |id|
    connection.execute("INSERT INTO #{table} (id) VALUES (#{connection.quote(id)}) ON CONFLICT (id) DO NOTHING")
  end
end

return if Rails.env.production?

# `fqdn_available_*` carries the same `:availability` polarity, so an unwritten flag closes the
# FQDN: a fresh primary database answers every request with 503 `fqdn_unavailable` before routing.
# Every slot the router serves is opened here so a freshly seeded development environment serves the
# hosts its own routes declare. Production is untouched (this file returns above) -- switching a
# public FQDN on stays an explicit operator decision made through the Flipper UI.
FqdnAvailabilityRegistry.flag_names.each { |feature_name| Flipper.enable(feature_name) }

# Deterministic development CMS documents so all twelve public content cells have
# a published entry. Uses the normal draft -> promote -> publish lifecycle.
# Keep this out of test: `db:prepare` seeds newly created test databases, and the
# welcome rows then leak into every worker clone and break empty-table assertions.
if Rails.env.development?
  locales = %w(ja en)

  Publishing::ContentFamilies::ENTRY_CLASSES.product(locales).each do |entry_class, locale|
    slug = "welcome"
    next if entry_class.reflect_on_association(:slugs).klass.exists?(locale:, slug:)

    title = "#{entry_class::SURFACE.capitalize} #{entry_class::AUDIENCE} (#{locale})"
    entry = entry_class.create!(locale:)
    entry.slugs.create!(locale:, slug:, state: "canonical", canonicalized_at: Time.current)
    revision = entry.revisions.create!(
      locale:, title:, summary: "#{title} summary",
      body: { "text" => "#{title} body" }, schema_version: 1,
      content_digest: Digest::SHA256.hexdigest("#{entry_class::AUDIENCE}-#{entry_class::SURFACE}-#{locale}-welcome"),
      sequence: 1,
    )
    entry.update!(current_revision: revision)
    version = Publishing::PromoteRevisionOperation.call(revision:)
    entry.publications.create!(entry_version: version, effective_from: 1.hour.ago)
  end
end
