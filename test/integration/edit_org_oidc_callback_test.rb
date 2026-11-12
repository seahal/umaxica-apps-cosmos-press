# frozen_string_literal: true

require "test_helper"

class EditOrgOidcCallbackTest < ActionDispatch::IntegrationTest
  include RpCellSessionHelper

  setup do
    host!("edit.umaxica.org")
    https!
    @previous_jwks_clients = OidcOpJwksClient::CLIENTS.dup
    install_rp_cell_operator_jwks_client!
    @client = OidcClientRegistry.find!("edit-org-ww")
    @issuer = OidcIssuer.for_client(@client)
  end

  teardown do
    OidcOpJwksClient::CLIENTS.clear
    @previous_jwks_clients.each { |key, value| OidcOpJwksClient::CLIENTS[key] = value }
  end

  test "external code flow sends PKCE and commits only the verified identity into Edit" do
    authorization = start_flow
    tokens = token_response(authorization)
    calls = []
    result = OidcOpTokenClient::Result.new(outcome: :success, token_response: tokens, error: nil)
    assert_difference("RpEditOrgSession.count", 1) do
      OidcOpTokenClient.stub(
        :authorization_code, ->(**args) {
                               calls << args
                               result
                             },
      ) do
        complete_flow(authorization)
      end
    end

    assert_response :found
    assert_equal "/dashboard", URI.parse(response.location).path
    assert_equal 1, calls.length
    assert_equal "edit-org-ww", calls.first.fetch(:client_id)
    assert_equal "external-code", calls.first.fetch(:code)
    assert_equal authorization.fetch("redirect_uri"), calls.first.fetch(:redirect_uri)
    assert_equal authorization.fetch("code_challenge"), OidcPkce.challenge_for(calls.first.fetch(:code_verifier))
    assert_equal tokens.fetch(:access_token), cookies[OidcRpBrowserCredentialContract::ACCESS_COOKIE]
    assert_equal tokens.fetch(:refresh_token), cookies[OidcRpBrowserCredentialContract::REFRESH_COOKIE]
    assert_predicate cookies[OidcRpBrowserCredentialContract::SESSION_COOKIE], :present?
    assert_nil session["oidc_pending_flows"]
  end

  test "wrong authorization response issuer stops before code exchange and persists no session" do
    authorization = start_flow
    assert_no_difference("RpEditOrgSession.count") do
      OidcOpTokenClient.stub(:authorization_code, ->(**) { flunk("issuer must precede code exchange") }) do
        complete_flow(authorization, issuer: "https://untrusted.example")
      end
    end

    assert_interrupted_without_credentials
  end

  test "wrong ID token nonce refuses the external response without creating a local session" do
    authorization = start_flow
    tokens = token_response(authorization, nonce: "another-browser-nonce")
    result = OidcOpTokenClient::Result.new(outcome: :success, token_response: tokens, error: nil)
    assert_no_difference("RpEditOrgSession.count") do
      OidcOpTokenClient.stub(:authorization_code, ->(**) { result }) { complete_flow(authorization) }
    end

    assert_interrupted_without_credentials
  end

  test "callback from another browser cannot consume this browser flow or exchange code" do
    authorization = start_flow
    other_browser = open_session
    other_browser.host!("edit.umaxica.org")
    other_browser.https!
    assert_no_difference("RpEditOrgSession.count") do
      OidcOpTokenClient.stub(:authorization_code, ->(**) { flunk("browser binding must precede exchange") }) do
        other_browser.get(
          "/oidc/callback",
          params: { state: authorization.fetch("state"), iss: @issuer, code: "stolen-code" },
        )
      end
    end

    assert_equal 303, other_browser.response.status
    assert_equal "/sign/interruption", URI.parse(other_browser.response.location).path
    assert_predicate session["oidc_pending_flows"], :present?
  end

  test "replayed callback cannot exchange the code twice or create another local session" do
    authorization = start_flow
    tokens = token_response(authorization)
    result = OidcOpTokenClient::Result.new(outcome: :success, token_response: tokens, error: nil)
    OidcOpTokenClient.stub(:authorization_code, ->(**) { result }) { complete_flow(authorization) }

    assert_response :found
    existing_session = cookies[OidcRpBrowserCredentialContract::SESSION_COOKIE]
    assert_no_difference("RpEditOrgSession.count") do
      OidcOpTokenClient.stub(:authorization_code, ->(**) { flunk("state replay must not exchange code") }) do
        complete_flow(authorization)
      end
    end

    assert_response :see_other
    assert_equal "/sign/interruption", URI.parse(response.location).path
    assert_equal existing_session, cookies[OidcRpBrowserCredentialContract::SESSION_COOKIE]
  end

  test "neutral sign form does not create a region preference when the request omits it" do
    get "/sign"

    assert_response :success
    assert_select "form[action]" do |forms|
      assert_equal 1, forms.length
      query = Rack::Utils.parse_nested_query(URI.parse(forms.first["action"]).query.to_s)

      assert_not query.key?("ri")
    end
  end

  test "sign initiation without a region does not fabricate a region preference" do
    post "/sign", params: { target_link_uri: "/dashboard" }

    assert_response :see_other
    query = Rack::Utils.parse_nested_query(URI.parse(response.location).query.to_s)

    assert_not query.key?("ri")
    assert_predicate query.fetch("state"), :present?
  end

  test "sign initiation carries either explicitly supplied region after case normalization" do
    %w(jp us JP US).each do |region|
      post "/sign", params: { ri: region, target_link_uri: "/dashboard" }

      assert_response :see_other
      query = Rack::Utils.parse_nested_query(URI.parse(response.location).query.to_s)

      assert_equal region.downcase, query.fetch("ri")
      assert_predicate query.fetch("state"), :present?
    end
  end

  test "unsupported region inputs fail before creating a pending authorization or exchanging credentials" do
    ["", "unknown", " jp ", 0, false, [], ["jp"], {}, { selected: "jp" }].each do |region|
      OidcOpTokenClient.stub(:authorization_code, ->(**) { flunk("invalid region must not exchange credentials") }) do
        post "/sign", params: { ri: region }, as: :json
      end

      assert_response :bad_request
      assert_nil session["oidc_pending_flows"]
      assert_empty cookies[OidcRpBrowserCredentialContract::ACCESS_COOKIE].to_s
      assert_empty cookies[OidcRpBrowserCredentialContract::SESSION_COOKIE].to_s
    end
  end

  private

  def start_flow
    post("/sign", params: { ri: "jp", target_link_uri: "/dashboard" })

    assert_response :see_other
    authorization = URI.parse(response.location)

    assert_equal "/oauth/authorize", authorization.path
    query = Rack::Utils.parse_nested_query(authorization.query.to_s)

    assert_equal "S256", query.fetch("code_challenge_method")
    query
  end

  def token_response(authorization, nonce: authorization.fetch("nonce"))
    subject = "operator:external-callback-reference"
    sid = SecureRandom.urlsafe_base64(24)
    response = rp_cell_test_token_response("edit-org-ww", subject:, sid:)
    response.merge(
      id_token: oidc_id_token_for_test(
        client: @client, resource_type: "operator", nonce:, issuer: @issuer, subject:, sid:,
        issuer_id: OidcIssuer.jwt_issuer_id_for_client(@client), auth_time: 1.minute.ago,
      ),
    )
  end

  def complete_flow(authorization, issuer: @issuer)
    get("/oidc/callback", params: { state: authorization.fetch("state"), iss: issuer, code: "external-code" })
  end

  def assert_interrupted_without_credentials
    assert_response :see_other
    assert_equal "/sign/interruption", URI.parse(response.location).path
    assert_empty cookies[OidcRpBrowserCredentialContract::ACCESS_COOKIE].to_s
    assert_empty cookies[OidcRpBrowserCredentialContract::REFRESH_COOKIE].to_s
    assert_empty cookies[OidcRpBrowserCredentialContract::SESSION_COOKIE].to_s
  end
end
