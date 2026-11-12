# typed: false
# frozen_string_literal: true

require "test_helper"

class OidcClientRegistryTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  test "Press registers only its independent Edit staff RP" do
    assert_equal ["edit-org-ww"], OidcClientRegistry.client_ids
    client = OidcClientRegistry.find!("edit-org-ww")

    assert_equal "edit-org-ww", client.client_id
    assert_equal "edit-org-ww", client.aud
    assert_equal "operator", client.resource_type
    assert_equal "EDIT_ORG_WW", client.jwt_namespace
    assert_predicate client, :confidential_client?
    assert_predicate client, :private_key_jwt_client?
    assert_not_predicate client, :public_client?
    assert client.redirect_uris.any? { |uri| URI.parse(uri).path == "/oidc/callback" }
    assert_equal ["operator"], client.redirect_uris_by_realm.keys
  end

  test "other repositories and public content surfaces have no local client registration" do
    %w(
      core-app-jp core-org-jp warp-app-jp warp-org-jp palm-app-jp
      base-app-ww base-org-ww tech-org-ww docs_app docs_org docs_com
      info_app news_org help_com unknown-client
    ).each do |client_id|
      assert_nil OidcClientRegistry.find(client_id), client_id
      assert_raises(OidcClientRegistry::ClientNotFound) { OidcClientRegistry.find!(client_id) }
    end
  end

  test "Edit logout registration accepts only the exact URI and operator realm" do
    client = OidcClientRegistry.find!("edit-org-ww")

    assert_equal ["/sign/out/completion"], client.post_logout_redirect_uris.map { |uri| URI.parse(uri).path }.uniq
    client.post_logout_redirect_uris.each do |uri|
      assert OidcClientRegistry.valid_post_logout_redirect_uri?(
        client_id: client.client_id, uri: uri, resource_type: "operator",
      )
      assert_not OidcClientRegistry.valid_post_logout_redirect_uri?(
        client_id: client.client_id, uri: uri, resource_type: "client",
      )
      assert_not OidcClientRegistry.valid_post_logout_redirect_uri?(
        client_id: client.client_id, uri: "#{uri}/extra", resource_type: "operator",
      )
    end
  end

  test "client assertion authentication refuses an unknown client without claims" do
    result = OidcClientRegistry.verify_client_assertion(
      "unknown-client", "untrusted-assertion", token_url: "https://issuer.example.invalid/oauth/token",
    )

    assert_not_predicate result, :authenticated?
    assert_nil result.client
    assert_equal :none, result.step_up_claims_state
    assert_nil result.step_up_expectation
    assert_not_predicate result, :step_up_claims_present?
    assert_not OidcClientRegistry.authenticate_assertion(
      "unknown-client", "untrusted-assertion", token_url: "https://issuer.example.invalid/oauth/token",
    )
  end

  test "Press audiences and authentication methods contain only its operator RP" do
    assert_empty OidcClientRegistry.audiences_for_resource_type("client")
    assert_equal ["edit-org-ww"], OidcClientRegistry.audiences_for_resource_type("staff")
    assert_empty OidcClientRegistry.revocation_endpoint_auth_methods_for("client")
    assert_equal ["private_key_jwt"], OidcClientRegistry.revocation_endpoint_auth_methods_for("operator")
    assert_raises(ArgumentError) { OidcClientRegistry.audiences_for_resource_type("unsupported") }
  end
end
