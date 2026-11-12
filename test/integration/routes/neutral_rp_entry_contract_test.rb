# typed: false
# frozen_string_literal: true

require "test_helper"

class NeutralRpEntryContractTest < ActionDispatch::IntegrationTest
  HOST = ENV.fetch("PUBLIC_EDIT_STAFF_URL", "edit.org.localhost")

  test "Edit keeps its neutral sign entry and OIDC callback routes" do
    sign_get = Rails.application.routes.recognize_path("https://#{HOST}/sign", method: :get)
    sign_post = Rails.application.routes.recognize_path("https://#{HOST}/sign", method: :post)
    callback = Rails.application.routes.recognize_path("https://#{HOST}/oidc/callback", method: :get)

    assert_equal "edit/org/sign/entries", sign_get.fetch(:controller)
    assert_equal "show", sign_get.fetch(:action)
    assert_equal "edit/org/sign/entries", sign_post.fetch(:controller)
    assert_equal "create", sign_post.fetch(:action)
    assert_equal "edit/org/oidc/callbacks", callback.fetch(:controller)
    assert_equal "show", callback.fetch(:action)
  end

  test "Edit registration keeps the existing client ID and callback path" do
    client = OidcClientRegistry.find!("edit-org-ww")
    callback_uris = client.redirect_uris_by_realm.fetch("operator")

    assert_equal "edit-org-ww", client.client_id
    assert_equal "operator", client.resource_type
    assert_equal ["/oidc/callback"], callback_uris.map { |uri| URI.parse(uri).path }.uniq
  end

  test "Edit exposes no obsolete authorization controller or legacy sign-in route" do
    controller_directory = Rails.root.join("app/controllers/edit/org/oidc")
    obsolete_controller = controller_directory.join("authorizations_controller.rb")

    assert_not obsolete_controller.exist?

    %w(/oidc/authorization /sign/in /sign/in/callback /sign/callback).each do |path|
      assert_raises(ActionController::RoutingError, "#{path} must remain unroutable on Edit") do
        Rails.application.routes.recognize_path("https://#{HOST}#{path}", method: :get)
      end
    end
  end
end
