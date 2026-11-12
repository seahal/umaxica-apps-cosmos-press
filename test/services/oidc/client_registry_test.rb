# typed: false
# frozen_string_literal: true

require "test_helper"

class PressOidcClientRegistryTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  test "Edit callback validation rejects foreign targets and wrong realms" do
    client = OidcClientRegistry.find!("edit-org-ww")
    uri = client.redirect_uris.fetch(0)

    assert OidcClientRegistry.valid_redirect_uri?(client.client_id, uri, resource_type: "operator")
    assert_not OidcClientRegistry.valid_redirect_uri?(client.client_id, uri, resource_type: "client")
    assert_not OidcClientRegistry.valid_redirect_uri?(client.client_id, "https://foreign.example.invalid/oidc/callback")
    assert_not OidcClientRegistry.valid_redirect_uri?("unknown", uri)
  end

  test "Edit client cache follows changes to its own public host" do
    original = ENV["PUBLIC_EDIT_STAFF_URL"]
    original_client = OidcClientRegistry.find!("edit-org-ww")
    ENV["PUBLIC_EDIT_STAFF_URL"] = "temporary-edit.example.invalid"

    assert OidcClientRegistry.find!("edit-org-ww").redirect_uris.any? { |uri|
      uri == "https://temporary-edit.example.invalid/oidc/callback"
    }
  ensure
    if original.nil?
      ENV.delete("PUBLIC_EDIT_STAFF_URL")
    else
      ENV["PUBLIC_EDIT_STAFF_URL"] = original
    end
    assert OidcClientRegistry.find!("edit-org-ww").redirect_uris.eql?(original_client.redirect_uris) if original_client
  end

  test "explicit public and private Edit callbacks remain bound to the operator realm" do
    original_public = ENV["PUBLIC_EDIT_STAFF_URL"]
    original_private = ENV["PRIVATE_EDIT_STAFF_URL"]
    ENV["PUBLIC_EDIT_STAFF_URL"] = "edit-public.example.invalid"
    ENV["PRIVATE_EDIT_STAFF_URL"] = "edit-private.example.invalid"
    client = OidcClientRegistry.find!("edit-org-ww")

    %w(edit-public.example.invalid edit-private.example.invalid).each do |host|
      uri = "https://#{host}/oidc/callback"

      assert OidcClientRegistry.valid_redirect_uri?(client.client_id, uri, resource_type: "operator")
      assert_not OidcClientRegistry.valid_redirect_uri?(client.client_id, uri, resource_type: "client")
    end
    ENV["PRIVATE_EDIT_STAFF_URL"] = "edit-private-changed.example.invalid"
    uri = "https://edit-private-changed.example.invalid/oidc/callback"

    assert OidcClientRegistry.valid_redirect_uri?(client.client_id, uri, resource_type: "operator")
    assert_not OidcClientRegistry.valid_redirect_uri?(client.client_id, uri, resource_type: "client")
  ensure
    if original_public.nil?
      ENV.delete("PUBLIC_EDIT_STAFF_URL")
    else
      ENV["PUBLIC_EDIT_STAFF_URL"] = original_public
    end
    if original_private.nil?
      ENV.delete("PRIVATE_EDIT_STAFF_URL")
    else
      ENV["PRIVATE_EDIT_STAFF_URL"] = original_private
    end
  end

  test "malformed own public host fails registered redirect construction" do
    original = ENV["PUBLIC_EDIT_STAFF_URL"]
    ENV["PUBLIC_EDIT_STAFF_URL"] = "["

    assert_raises(ArgumentError) { OidcClientStoresStaticClientStore.clients }
  ensure
    if original.nil?
      ENV.delete("PUBLIC_EDIT_STAFF_URL")
    else
      ENV["PUBLIC_EDIT_STAFF_URL"] = original
    end
  end

  test "backchannel logout resolves only the locally registered Edit client" do
    uri = OidcClientStoresStaticClientStore.backchannel_logout_uri("edit-org-ww")

    assert_equal "/oidc/closures", URI.parse(uri).path
    %w(core-app-jp core-org-jp base-app-ww tech-org-ww unknown).each do |client_id|
      assert_raises(KeyError) { OidcClientStoresStaticClientStore.backchannel_logout_uri(client_id) }
    end
  end

  test "Edit client secret authentication rejects missing credentials and incorrect secrets" do
    Rails.app.creds.stub(:option, nil) do
      assert_not OidcClientRegistry.authenticate("edit-org-ww", "synthetic-secret")
    end
    configured = ->(key, default: nil) { (key == :"OIDC_CLIENT_SECRETS_EDIT-ORG-WW") ? "synthetic-secret" : default }
    Rails.app.creds.stub(:option, configured) do
      assert OidcClientRegistry.authenticate("edit-org-ww", "synthetic-secret")
      assert_not OidcClientRegistry.authenticate("edit-org-ww", "wrong-secret")
      assert_not OidcClientRegistry.authenticate("edit-org-ww", "")
      assert_not OidcClientRegistry.authenticate("edit-org-ww", nil)
    end
  end
end
