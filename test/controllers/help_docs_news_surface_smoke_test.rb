# typed: false
# frozen_string_literal: true

require "test_helper"
# require "helpers/global_test_support"

class HelpDocsNewsSurfaceSmokeTest < ActionDispatch::IntegrationTest
  SURFACES = [
    {
      host_env: "PRIVATE_HELP_SERVICE_URL",
      host_fallback: "help.app.localhost",
      label: "Help",
      health_path: "/health",
      entries_index_path: "/api/v0/entries",
      surface: "help",
    },
    {
      host_env: "PRIVATE_DOCS_SERVICE_URL",
      host_fallback: "docs.app.localhost",
      label: "Docs",
      health_path: "/health",
      entries_index_path: "/api/v0/entries",
      surface: "docs",
    },
    {
      host_env: "PRIVATE_NEWS_SERVICE_URL",
      host_fallback: "news.app.localhost",
      label: "News",
      health_path: "/health",
      entries_index_path: "/api/v0/entries",
      surface: "news",
    },
  ].freeze

  test "help docs and news app surfaces respond on their public read-only endpoints" do
    SURFACES.each do |surface|
      host = ENV.fetch(surface.fetch(:host_env), surface.fetch(:host_fallback))
      host! host

      get surface.fetch(:health_path), headers: { "Host" => host }

      assert_response :success, surface.fetch(:label)
      assert_not_empty response.body, surface.fetch(:label)

      published = create_publishing_entry(
        audience: "app", surface: surface.fetch(:surface),
        namespace: surface.fetch(:label).downcase,
      )

      get surface.fetch(:entries_index_path),
          params: { locale: "test-smoke" },
          headers: { "Host" => host, "Accept" => "application/json" },
          as: :json

      assert_response :success, surface.fetch(:label)
      entry = response.parsed_body.fetch("data").first

      assert_equal published.slug, entry.fetch("slug"), surface.fetch(:label)
      assert_equal surface.fetch(:label).downcase, entry.fetch("namespace"), surface.fetch(:label)
      assert_equal "app", entry.fetch("surface"), surface.fetch(:label)

      get "#{surface.fetch(:entries_index_path)}/#{published.entry.public_id}",
          params: { locale: "test-smoke" },
          headers: { "Host" => host, "Accept" => "application/json" },
          as: :json

      assert_response :success, surface.fetch(:label)
      assert_equal published.entry.public_id, response.parsed_body.fetch("public_id"), surface.fetch(:label)
      assert_equal published.slug, response.parsed_body.fetch("slug"), surface.fetch(:label)
    end
  end

  private
  def create_publishing_entry(audience:, surface:, namespace:)
    entry =
      publishing_published_entry(
        audience:, surface:, locale: "test-smoke", slug: "#{namespace}-surface-smoke",
        title: "#{namespace.titleize} Surface Smoke", published_at: 1.minute.ago,
      )
    entry.slugs.canonical.first
  end
end
