# frozen_string_literal: true

require "test_helper"

class EditOrgPolicyRequestContextTest < ActionDispatch::IntegrationTest
  include RpCellSessionHelper

  self.fixture_table_names = []

  setup do
    @previous_jwks_clients = OidcOpJwksClient::CLIENTS.dup
    install_rp_cell_operator_jwks_client!
    host!(ENV.fetch("PUBLIC_EDIT_STAFF_URL"))
    https!
  end

  teardown do
    OidcOpJwksClient::CLIENTS.clear
    @previous_jwks_clients.each { |key, value| OidcOpJwksClient::CLIENTS[key] = value }
  end

  test "interleaved browsers keep Normal and Standby authority separate from a refused unknown JWT context" do
    normal = browser_with_context("normal")
    standby = browser_with_context("standby")
    unknown = browser_with_context("unrecognized")
    # A presented refresh credential would request recovery through the external OP; this case
    # verifies the definitive refusal of this signed but unsupported access credential itself.
    unknown.cookies.delete(OidcRpBrowserCredentialContract::REFRESH_COOKIE)

    normal.get("/dashboard", params: { ri: "jp" })

    assert_equal 200, normal.response.status
    standby.get("/dashboard", params: { ri: "jp" })

    assert_equal 200, standby.response.status
    unknown.get("/dashboard", params: { ri: "jp" }, headers: { "Accept" => "application/json" })

    assert_equal 401, unknown.response.status
    assert_empty unknown.cookies[OidcRpBrowserCredentialContract::ACCESS_COOKIE].to_s
    assert_empty unknown.cookies[OidcRpBrowserCredentialContract::SESSION_COOKIE].to_s
    normal.get("/dashboard", params: { ri: "jp" })

    assert_equal 200, normal.response.status
    standby.get("/dashboard", params: { ri: "jp" })

    assert_equal 200, standby.response.status
    unknown.get("/dashboard", params: { ri: "jp" }, headers: { "Accept" => "application/json" })

    assert_equal 401, unknown.response.status
  end

  test "anonymous request admission stays independent of missing domain-policy claims" do
    get "/sign"

    assert_response :success
    assert_nil session["oidc_pending_flows"]

    get "/dashboard", params: { ri: "jp" }

    assert_response :redirect
    assert_equal "/sign", URI.parse(response.location).path
    assert_nil session["oidc_pending_flows"]
  end

  private

  def browser_with_context(context)
    token_response, _payload, local_session = sign_in_edit_rp(
      subject: "operator:external-#{context}", authentication_context: context,
    )
    browser = open_session
    browser.host!(ENV.fetch("PUBLIC_EDIT_STAFF_URL"))
    browser.https!
    browser.cookies[OidcRpBrowserCredentialContract::ACCESS_COOKIE] = token_response.fetch(:access_token)
    browser.cookies[OidcRpBrowserCredentialContract::REFRESH_COOKIE] = token_response.fetch(:refresh_token)
    browser.cookies[OidcRpBrowserCredentialContract::SESSION_COOKIE] = local_session.public_id
    browser
  end
end
