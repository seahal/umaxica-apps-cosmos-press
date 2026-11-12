# frozen_string_literal: true

require "test_helper"

class OidcRpLogoutRegisteredRpMatrixTest < ActionDispatch::IntegrationTest
  self.fixture_table_names = []

  setup do
    host! ENV.fetch("PUBLIC_EDIT_STAFF_URL")
    https!
  end

  test "Edit clears local credentials and hands off to external no-hint logout" do
    as_rp_cell("edit-org-ww") do
      install_rp_cell_operator_jwks_client!
      _tokens, _payload, local_session = sign_in_edit_rp
      unavailable = OidcOpRevocationClient::Result.new(outcome: :network_unavailable)
      OidcOpRevocationClient.stub(:revoke, ->(**) { unavailable }) do
        post "/sign/out?ri=jp"
      end

      assert_response :see_other
      query = Rack::Utils.parse_nested_query(URI.parse(response.location).query.to_s)
      client = OidcClientRegistry.find!("edit-org-ww")

      assert_equal OidcIssuer.host_for_client(client), URI.parse(response.location).host
      assert_equal "/oidc/logout", URI.parse(response.location).path
      assert_equal client.client_id, query.fetch("client_id")
      assert_not query.key?("id_token_hint")
      assert_not query.key?("logout_challenge")
      assert_predicate query.fetch("state"), :present?
      assert_empty cookies[OidcRpBrowserCredentialContract::ACCESS_COOKIE].to_s
      assert_empty cookies[OidcRpBrowserCredentialContract::REFRESH_COOKIE].to_s
      assert_predicate local_session.reload.revoked_at, :present?

      callback = URI.parse(query.fetch("post_logout_redirect_uri"))
      callback.query = Rack::Utils.parse_nested_query(callback.query).merge("state" => query.fetch("state")).to_query
      writes = []
      observer =
        ->(_name, _start, _finish, _id, payload) do
          writes << payload.fetch(:sql) if payload.fetch(:sql).match?(/\A\s*(INSERT|UPDATE|DELETE)\b/i)
        end
      ActiveSupport::Notifications.subscribed(observer, "sql.active_record") { get callback.request_uri }

      assert_empty writes, "logout completion must not write database records"
      assert_includes [200, 303], response.status
      follow_redirect! while response.redirect?

      assert_includes response.headers.fetch("Clear-Site-Data"), '"storage"'
      get callback.request_uri

      assert_response :not_found
    end
  end

  test "an old return refuses a wrong state and cannot disrupt a new RP session" do
    as_rp_cell("edit-org-ww") do
      install_rp_cell_operator_jwks_client!
      sign_in_edit_rp(subject: "operator:old-external-subject")
      unavailable = OidcOpRevocationClient::Result.new(outcome: :network_unavailable)
      OidcOpRevocationClient.stub(:revoke, ->(**) { unavailable }) do
        post "/sign/out?ri=jp"
      end

      assert_response :see_other
      query = Rack::Utils.parse_nested_query(URI.parse(response.location).query.to_s)
      callback = URI.parse(query.fetch("post_logout_redirect_uri"))
      callback_query = Rack::Utils.parse_nested_query(callback.query.to_s)
      callback.query = callback_query.merge("state" => "wrong-state").to_query
      get callback.request_uri

      assert_response :not_found

      _tokens, _payload, new_session = sign_in_edit_rp(subject: "operator:new-external-subject")
      access_before = cookies[OidcRpBrowserCredentialContract::ACCESS_COOKIE]
      refresh_before = cookies[OidcRpBrowserCredentialContract::REFRESH_COOKIE]
      local_before = cookies[OidcRpBrowserCredentialContract::SESSION_COOKIE]
      callback.query = callback_query.merge("state" => query.fetch("state")).to_query
      get callback.request_uri

      assert_response :not_found
      assert_equal access_before, cookies[OidcRpBrowserCredentialContract::ACCESS_COOKIE]
      assert_equal refresh_before, cookies[OidcRpBrowserCredentialContract::REFRESH_COOKIE]
      assert_equal local_before, cookies[OidcRpBrowserCredentialContract::SESSION_COOKIE]
      assert_nil new_session.reload.revoked_at
    end
  end
end
