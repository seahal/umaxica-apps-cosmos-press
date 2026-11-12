# typed: false
# frozen_string_literal: true

require "test_helper"

class EditSignOutCompletionRouteTest < ActionDispatch::IntegrationTest
  HOST = ENV.fetch("PUBLIC_EDIT_STAFF_URL", "edit.org.localhost")

  test "Edit keeps the OIDC completion route GET-only" do
    route = Rails.application.routes.recognize_path("https://#{HOST}/sign/out/completion", method: :get)

    assert_equal "edit/org/sign/outs", route.fetch(:controller)
    assert_equal "show", route.fetch(:action)
    assert_raises(ActionController::RoutingError) do
      Rails.application.routes.recognize_path("https://#{HOST}/sign/out/completion", method: :post)
    end
  end
end
