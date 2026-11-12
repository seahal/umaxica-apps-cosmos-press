# frozen_string_literal: true

require "test_helper"

class OidcRpLogoutEditReturnTest < ActionDispatch::IntegrationTest
  include RpCellSessionHelper

  setup do
    @previous_jwks_clients = OidcOpJwksClient::CLIENTS.dup
    OidcOpJwksClient::CLIENTS.clear
    install_operator_jwks_client!
  end

  teardown do
    OidcOpJwksClient::CLIENTS.clear
    @previous_jwks_clients&.each { |client_key, client_value| OidcOpJwksClient::CLIENTS[client_key] = client_value }
  end

  test "Edit RP returns through Visa ORG without a token hint and rejects callbacks without its issued state" do
    hosts = Rails.configuration.x.boot_config.fetch(:hosts)
    [
      {
        client_id: "edit-org-ww",
        rp_host: hosts.edit_staff.host,
        expected_op_host: hosts.visa_staff.host,
      },
    ].each do |scenario|
      client = OidcClientRegistry.find!(scenario.fetch(:client_id))
      token_response, _payload, local_session = sign_in_edit_rp
      browser = open_session
      browser.host!(scenario.fetch(:rp_host))
      browser.https!
      browser.cookies[OidcRpBrowserCredentialContract::ACCESS_COOKIE] = token_response.fetch(:access_token)
      browser.cookies[OidcRpBrowserCredentialContract::REFRESH_COOKIE] = token_response.fetch(:refresh_token)
      browser.cookies[OidcRpBrowserCredentialContract::SESSION_COOKIE] = local_session.public_id

      unavailable = OidcOpRevocationClient::Result.new(outcome: :network_unavailable)
      OidcOpRevocationClient.stub(:revoke, ->(**) { unavailable }) do
        browser.post("/sign/out?ri=jp")
      end

      assert_equal 303, browser.response.status, "#{scenario.fetch(:client_id)} RP sign-out must redirect"
      location = URI.parse(browser.response.location)
      query = Rack::Utils.parse_nested_query(location.query.to_s)

      assert_equal scenario.fetch(:expected_op_host), location.host, "#{scenario.fetch(:client_id)} OP host"
      assert_equal "/oidc/logout", location.path, "#{scenario.fetch(:client_id)} OP path"
      assert_equal client.client_id, query.fetch("client_id")
      assert_nil query["id_token_hint"], "RP sign-out must not send an ID Token hint"
      state = query.fetch("state")

      assert_operator state.length, :>, 0, "RP sign-out must bind the completion with state"
      assert_predicate local_session.reload.revoked_at, :present?

      return_uri = URI.parse(query.fetch("post_logout_redirect_uri"))

      assert_includes client.post_logout_redirect_uris, return_uri.to_s
      assert_equal scenario.fetch(:rp_host), return_uri.host, "#{scenario.fetch(:client_id)} callback host"
      assert_equal "/sign/out/completion", return_uri.path
      assert_equal({ "ri" => "jp" }, Rack::Utils.parse_nested_query(return_uri.query.to_s))

      assert_equal hosts.edit_staff.host, return_uri.host
      wrong_state = "#{(state[0] == "x") ? "y" : "x"}#{state[1..]}"
      [nil, wrong_state].each do |callback_state|
        callback_uri = return_uri.dup
        callback_params = Rack::Utils.parse_nested_query(callback_uri.query.to_s)
        callback_params["state"] = callback_state if callback_state
        callback_uri.query = callback_params.to_query
        browser.host!(hosts.edit_staff.host)
        browser.get(callback_uri.request_uri)

        assert_equal 404, browser.response.status, "Edit callback requires the issued state"
        assert_predicate local_session.reload.revoked_at, :present?
      end

      callback_params = Rack::Utils.parse_nested_query(return_uri.query.to_s)
      callback_params["state"] = state
      return_uri.query = callback_params.to_query
      browser.host!(scenario.fetch(:rp_host))
      browser.get(return_uri.request_uri)

      assert_equal 200, browser.response.status, "#{scenario.fetch(:client_id)} completion page"
      assert_includes browser.response.headers.fetch("Clear-Site-Data"), '"storage"'

      browser.get(return_uri.request_uri)

      assert_equal 404, browser.response.status, "#{scenario.fetch(:client_id)} completion is single use"
    end
  end

  private

  def install_operator_jwks_client!
    jwks_uri = OidcIssuer.jwks_uri("operator").to_s
    issuer_id = OidcIssuer.jwt_issuer_id_for_resource_type("operator")
    OidcOpJwksClient::CLIENTS[jwks_uri] = OidcOpJwksClient.new(
      jwks_uri:, fetcher: -> { JitSecurityJwtRegistry.jwks_for(issuer_id).deep_stringify_keys },
    )
  end
end
