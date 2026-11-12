# typed: false
# frozen_string_literal: true

require "test_helper"

# D-31 / D-118: the receiver lives at POST /oidc/closures, answers only on the RP's registered
# host, needs no browser or cookie, and the former path does not route.
class OidcClosuresReceiverGatingTest < ActionDispatch::IntegrationTest
  self.fixture_table_names = []

  test "the former back-channel logout path is not routable" do
    host = URI.parse(OidcClientStoresStaticClientStore.backchannel_logout_uri("edit-org-ww")).host

    assert_raises(ActionController::RoutingError) do
      Rails.application.routes.recognize_path("https://#{host}/oidc/backchannel-logout", method: :post)
    end
  end

  test "a request without a browser User-Agent or cookies reaches the token check" do
    host! URI.parse(OidcClientStoresStaticClientStore.backchannel_logout_uri("edit-org-ww")).host
    https!

    post "/oidc/closures", params: { logout_token: "not-a-jwt" }, headers: { "User-Agent" => "" }

    assert_response :bad_request
    assert_equal "no-store", response.headers["Cache-Control"]
  end

  test "a request from a host other than the registered RP is rejected before verification" do
    host! "unregistered.example.test"
    https!
    verifier = ->(**) { flunk("an unregistered host must not reach token verification") }

    OidcOpLogoutTokenVerifier.stub(:new, verifier) do
      post "/oidc/closures", params: { logout_token: "signed-token" }, headers: { "User-Agent" => "" }
    end

    assert_response :not_found
  end

  test "unavailable logout signing keys produce a retryable no-store response" do
    host! URI.parse(OidcClientStoresStaticClientStore.backchannel_logout_uri("edit-org-ww")).host
    https!
    verification = OidcOpLogoutTokenVerifier::Result.new(
      success: false, payload: nil, error: "key_unavailable",
    )
    verifier = Object.new
    verifier.define_singleton_method(:call) { verification }

    OidcOpLogoutTokenVerifier.stub(:new, ->(**) { verifier }) do
      post "/oidc/closures", params: { logout_token: "signed-token" }, headers: { "User-Agent" => "" }
    end

    assert_response :service_unavailable
    assert_equal "no-store", response.headers["Cache-Control"]
  end

  test "a verified logout returns success only after its cell revocation commits" do
    host! URI.parse(OidcClientStoresStaticClientStore.backchannel_logout_uri("edit-org-ww")).host
    https!
    payload = { "iss" => "https://issuer.example.test", "jti" => "event-1", "sid" => "session-1" }
    verification = OidcOpLogoutTokenVerifier::Result.new(success: true, payload:, error: nil)
    verifier = Object.new
    verifier.define_singleton_method(:call) { verification }
    revocations = []

    OidcOpLogoutTokenVerifier.stub(:new, ->(**) { verifier }) do
      RpCellSessionRevoker.stub(:call, ->(**options) { revocations << options }) do
        post "/oidc/closures", params: { logout_token: "signed-token" }, headers: { "User-Agent" => "" }
      end
    end

    assert_response :ok
    assert_equal "no-store", response.headers["Cache-Control"]
    assert_equal 1, revocations.length
    assert_equal "edit-org-ww", revocations.sole.fetch(:cell).client_id
    assert_equal payload, revocations.sole.fetch(:payload)
  end

  test "a cell persistence failure returns a retryable no-store response" do
    host! URI.parse(OidcClientStoresStaticClientStore.backchannel_logout_uri("edit-org-ww")).host
    https!
    payload = { "iss" => "https://issuer.example.test", "jti" => "event-2", "sid" => "session-2" }
    verification = OidcOpLogoutTokenVerifier::Result.new(success: true, payload:, error: nil)
    verifier = Object.new
    verifier.define_singleton_method(:call) { verification }

    OidcOpLogoutTokenVerifier.stub(:new, ->(**) { verifier }) do
      RpCellSessionRevoker.stub(:call, ->(**) { raise ActiveRecord::RecordNotSaved }) do
        post "/oidc/closures", params: { logout_token: "signed-token" }, headers: { "User-Agent" => "" }
      end
    end

    assert_response :service_unavailable
    assert_equal "no-store", response.headers["Cache-Control"]
  end
end
