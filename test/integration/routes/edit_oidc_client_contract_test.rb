# typed: false
# frozen_string_literal: true

require "test_helper"

class EditOidcClientContractTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  test "only Edit is registered as a Press OIDC client" do
    assert_equal ["edit-org-ww"], OidcClientRegistry.client_ids.sort
  end

  test "Edit's operator client registers its exact callback path" do
    client = OidcClientRegistry.find!("edit-org-ww")
    edit_host = ENV.fetch("PUBLIC_EDIT_STAFF_URL")
    edit_uri = URI.parse(edit_host.include?("://") ? edit_host : "https://#{edit_host}")
    registered_uri =
      client.redirect_uris_by_realm.fetch("operator").find do |uri|
        URI.parse(uri).host == edit_uri.host
      end

    assert_predicate registered_uri, :present?, "Edit's operator callback must be registered for its host"

    assert_equal "operator", client.resource_type
    assert_equal "edit-org-ww", client.aud
    assert_equal "/oidc/callback", URI.parse(registered_uri).path
    assert_equal edit_uri.host, URI.parse(registered_uri).host
  end
end
