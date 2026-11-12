# typed: false
# frozen_string_literal: true

require "test_helper"
require_relative "../../support/rp_cell_session_helper"

# Edit's authenticated HTML responses must not outlive the operator's local RP session. A
# conditional request must still authenticate before Rails can return a cached representation.
# Edit serves HTML pages; its root-level no-store defaults are
# covered by `default_no_store_edit_test.rb`.
class AuthenticatedResponseCachePolicyTest < ActionDispatch::IntegrationTest
  include RpCellSessionHelper

  self.fixture_table_names = []

  setup do
    @previous_jwks_clients = OidcOpJwksClient::CLIENTS.dup
    @host = ENV.fetch("PUBLIC_EDIT_STAFF_URL")
    host! @host
    https!
  end

  teardown do
    OidcOpJwksClient::CLIENTS.clear
    @previous_jwks_clients&.each do |client_key, client_value|
      OidcOpJwksClient::CLIENTS[client_key] = client_value
    end
  end

  test "an authenticated Edit HTML page is no-store" do
    with_authenticated_edit_session do
      get edit_org_dashboard_path(ri: "jp")

      assert_response :success
      assert_equal "text/html", response.media_type
      assert_no_store
    end
  end

  # Rack adds a validator to the page, and a 304 is produced only after the action ran. A
  # conditional request therefore cannot skip the credential check: without a valid credential the
  # matching validator earns the Edit sign-in redirect, never a 304.
  test "a matching validator does not let a conditional request bypass Edit authentication" do
    with_authenticated_edit_session do
      get edit_org_dashboard_path(ri: "jp")

      assert_response :success
      assert_no_store
      validator = response.headers.fetch("ETag")

      [OidcRpBrowserCredentialContract::ACCESS_COOKIE,
       OidcRpBrowserCredentialContract::REFRESH_COOKIE,
       OidcRpBrowserCredentialContract::SESSION_COOKIE,].each do |cookie_name|
        cookies.delete(cookie_name)
      end

      get edit_org_dashboard_path(ri: "jp"), headers: host_headers(@host).merge("If-None-Match" => validator)

      assert_response :redirect
      assert_equal "/sign", URI.parse(response.location).path
      assert_not_equal 304, response.status
    end
  end

  private

  def with_authenticated_edit_session
    as_rp_cell("edit-org-ww") do
      sign_in_edit_rp
      install_operator_jwks_client!
      yield
    end
  end

  def install_operator_jwks_client!
    jwks_uri = OidcIssuer.jwks_uri("operator").to_s
    issuer_id = OidcIssuer.jwt_issuer_id_for_resource_type("operator")
    OidcOpJwksClient::CLIENTS[jwks_uri] = OidcOpJwksClient.new(
      jwks_uri:, fetcher: -> { JitSecurityJwtRegistry.jwks_for(issuer_id).deep_stringify_keys },
    )
  end

  def assert_no_store
    assert_includes response.headers["Cache-Control"].to_s.split(",").map(&:strip), "no-store",
                    "expected no-store, got #{response.headers["Cache-Control"].inspect}"
  end
end
