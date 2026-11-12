# typed: false
# frozen_string_literal: true

require "test_helper"
# require "helpers/global_test_support"

class ContentSurfaceBoundaryTest < ActionDispatch::IntegrationTest
  self.fixture_table_names = []

  SURFACE_HOSTS = {
    "docs" => ENV.fetch("PRIVATE_DOCS_SERVICE_URL"),
    "help" => ENV.fetch("PRIVATE_HELP_SERVICE_URL"),
    "news" => ENV.fetch("PRIVATE_NEWS_SERVICE_URL"),
  }.freeze

  test "docs help and news entries remain public read-only json surfaces" do
    SURFACE_HOSTS.each_value do |host|
      host! host

      get "/api/v0/entries"

      assert_response :success
      # adr/api-collection-contract.md: every collection carries the same envelope, and an empty
      # page still reports its pagination state rather than omitting it.
      assert_equal(
        { "data" => [], "page" => { "current" => 1, "previous" => nil, "next" => nil, "last" => 1 } },
        response.parsed_body,
      )
      assert_empty Array(response.headers["Set-Cookie"])

      # Revisions are an internal lifecycle concept; the nested endpoints that
      # once returned an empty array were removed rather than kept as a contract.
      get "/api/v0/entries/example/revisions"

      assert_response :not_found

      assert_mutation_verbs_rejected(host, "/api/v0/entries")
    end
  end

  test "docs help and news do not expose rp or provider endpoints" do
    SURFACE_HOSTS.each_value do |host|
      %w(/auth /auth/callback /authorize /token /userinfo /jwks /oauth/authorize /oauth/token /oauth/userinfo
         /oauth/jwks).each do |path|
        assert_raises(ActionController::RoutingError) do
          Rails.application.routes.recognize_path("http://#{host}#{path}", method: :get)
        end
      end

      assert_raises(ActionController::RoutingError) do
        Rails.application.routes.recognize_path("http://#{host}/oauth/token", method: :post)
      end
    end
  end

  private

  def assert_mutation_verbs_rejected(host, path)
    %i(post patch put delete).each do |method|
      assert_raises(ActionController::RoutingError) do
        Rails.application.routes.recognize_path("http://#{host}#{path}", method: method)
      end
    end
  end
end
