# frozen_string_literal: true

require "test_helper"
require_relative "../support/rp_cell_session_helper"

# Edit's retained JP-development RP process authenticates from its local session and the
# OP-verified Access JWT, refuses the same token without that session, and refuses it after the
# local OP binding is revoked (a back-channel logout tombstone).
class RpCellLocalSessionReadinessTest < ActionDispatch::IntegrationTest
  include RpCellSessionHelper

  setup { @previous_jwks_clients = OidcOpJwksClient::CLIENTS.dup }

  teardown do
    OidcOpJwksClient::CLIENTS.clear
    @previous_jwks_clients&.each { |client_key, client_value| OidcOpJwksClient::CLIENTS[client_key] = client_value }
  end

  # client_id => [host env, protected GET path]
  CELLS = {
    "edit-org-ww" => ["PUBLIC_EDIT_STAFF_URL", "/dashboard"],
  }.freeze

  CELLS.each do |client_id, (host_env, path)|
    test "#{client_id} authenticates from its local session and refuses without it or after logout" do
      host!(ENV.fetch(host_env))
      https!

      as_rp_cell(client_id) do
        token_response, _payload, local_session = sign_in_edit_rp
        install_operator_jwks_client!
        get path, params: { ri: "jp" }

        assert_response :success

        # The same Access JWT without Edit's local session starts a new OIDC authorization.
        session_cookie = cookies[OidcRpBrowserCredentialContract::SESSION_COOKIE]
        cookies.delete(OidcRpBrowserCredentialContract::SESSION_COOKIE)
        get path, params: { ri: "jp" }

        assert_edit_authorization_redirect(client_id)

        # A revoked local OP binding also returns to sign-in for the same credential.
        cookies[OidcRpBrowserCredentialContract::SESSION_COOKIE] = session_cookie
        cookies[OidcRpBrowserCredentialContract::ACCESS_COOKIE] = token_response.fetch(:access_token)
        binding_class = RpEditOrgOpSessionBinding
        binding_class.where(id: local_session.op_session_binding_id).update_all(revoked_at: Time.current)
        get path, params: { ri: "jp" }

        assert_response :found
        sign_in_path = URI.parse(response.location)

        assert_equal ENV.fetch("PUBLIC_EDIT_STAFF_URL"), sign_in_path.host
        assert_equal "/sign", sign_in_path.path
        assert_equal(
          { "ri" => "jp", "target_link_uri" => "/dashboard" },
          Rack::Utils.parse_nested_query(sign_in_path.query.to_s),
        )
      end
    end
  end

  CELLS.each_key do |client_id|
    test "#{client_id} signs out locally before revoking its Refresh Token" do
      assert_rp_cell_sign_out(client_id)
    end
  end

  test "sign out without a registered region refuses handoff without guessing or revoking the local session" do
    host!(ENV.fetch("PUBLIC_EDIT_STAFF_URL"))
    https!
    install_rp_cell_operator_jwks_client!
    token_response, _payload, local_session = sign_in_edit_rp
    OidcOpRevocationClient.stub(:revoke, ->(**) { flunk("no registered callback means no external revocation") }) do
      post "/sign/out"
    end

    assert_response :unprocessable_content
    assert_nil local_session.reload.revoked_at
    assert_equal token_response.fetch(:access_token), cookies[OidcRpBrowserCredentialContract::ACCESS_COOKIE]
    assert_equal token_response.fetch(:refresh_token), cookies[OidcRpBrowserCredentialContract::REFRESH_COOKIE]
    assert_equal local_session.public_id, cookies[OidcRpBrowserCredentialContract::SESSION_COOKIE]
  end

  private

  def assert_rp_cell_sign_out(client_id)
    previous_jwks_clients = OidcOpJwksClient::CLIENTS.dup
    client = OidcClientRegistry.find!(client_id)
    resource_type = OidcIssuer.resource_type_for_client(client)

    as_rp_cell(client_id) do
      host!(ENV.fetch(CELLS.fetch(client_id).first))
      https!
      credentials = rp_cell_logout_credentials(client_id)
      outcome = submit_rp_cell_logout(credentials)

      assert_rp_cell_logout_handoff(client_id, resource_type, credentials, outcome)
      assert_rp_cell_logout_state(client_id, credentials)
    end
  ensure
    OidcOpJwksClient::CLIENTS.clear
    previous_jwks_clients&.each { |client_key, client_value| OidcOpJwksClient::CLIENTS[client_key] = client_value }
  end

  def rp_cell_logout_credentials(client_id)
    token_response, _payload, local_session = sign_in_edit_rp
    install_operator_jwks_client!
    resource_type = OidcIssuer.resource_type_for_client(OidcClientRegistry.find!(client_id))
    { resource_type:, token_response:, local_session: }
  end

  def install_operator_jwks_client!
    jwks_uri = OidcIssuer.jwks_uri("operator").to_s
    issuer_id = OidcIssuer.jwt_issuer_id_for_resource_type("operator")
    OidcOpJwksClient::CLIENTS[jwks_uri] = OidcOpJwksClient.new(
      jwks_uri:, fetcher: -> { JitSecurityJwtRegistry.jwks_for(issuer_id).deep_stringify_keys },
    )
  end

  def assert_edit_authorization_redirect(client_id)
    assert_response :see_other
    location = URI.parse(response.location)
    client = OidcClientRegistry.find!(client_id)
    query = Rack::Utils.parse_nested_query(location.query.to_s)

    assert_equal URI.parse(OidcIssuer.authorization_endpoint("operator")).host, location.host
    assert_equal "/oauth/authorize", location.path
    assert_equal client_id, query.fetch("client_id")
    assert_equal "none", query.fetch("prompt")
    callback = URI.parse(query.fetch("redirect_uri"))

    assert_equal ENV.fetch("PUBLIC_EDIT_STAFF_URL"), callback.host
    assert_equal "/oidc/callback", callback.path
    assert_includes client.redirect_uris, callback.to_s
    assert_predicate query.fetch("state"), :present?
  end

  def submit_rp_cell_logout(credentials)
    revocation_calls = []
    revocation_result = Object.new
    revocation_result.define_singleton_method(:success?) { false }
    revocation_result.define_singleton_method(:outcome) { :network_unavailable }
    local_session = credentials.fetch(:local_session)

    OidcOpRevocationClient.stub(
      :revoke,
      ->(**arguments) {
        revocation_calls << arguments.merge(local_session_revoked: local_session.reload.revoked_at.present?)
        revocation_result
      },
    ) do
      post("/sign/out", params: { ri: "jp" })
    end

    { revocation_calls:, location: response.location }
  end

  def assert_rp_cell_logout_handoff(client_id, resource_type, credentials, outcome)
    assert_response :see_other, client_id
    location = URI.parse(outcome.fetch(:location))
    query = Rack::Utils.parse_nested_query(location.query.to_s)
    revocation = outcome.fetch(:revocation_calls).fetch(0)
    token_response = credentials.fetch(:token_response)

    assert_equal "/oidc/logout", location.path, client_id
    assert_equal URI.parse(OidcIssuer.end_session_endpoint(resource_type)).host, location.host, client_id
    assert_equal client_id, query.fetch("client_id"), client_id
    assert_equal token_response.fetch(:refresh_token), revocation.fetch(:token), client_id
    assert_equal resource_type, revocation.fetch(:resource_type), client_id
    assert revocation.fetch(:local_session_revoked)
    assert_not query.key?("id_token_hint"), client_id

    assert_predicate query.fetch("post_logout_redirect_uri"), :present?, client_id
    assert_predicate query.fetch("state"), :present?, client_id
  end

  def assert_rp_cell_logout_state(client_id, credentials)
    assert_predicate credentials.fetch(:local_session).reload.revoked_at, :present?, client_id
    assert_empty cookies[OidcRpBrowserCredentialContract::ACCESS_COOKIE].to_s, client_id
    assert_empty cookies[OidcRpBrowserCredentialContract::REFRESH_COOKIE].to_s, client_id
    assert_empty cookies[OidcRpBrowserCredentialContract::SESSION_COOKIE].to_s, client_id
  end
end
