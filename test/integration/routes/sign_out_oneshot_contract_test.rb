# typed: false
# frozen_string_literal: true

require "test_helper"

class SignOutOneshotContractTest < ActionDispatch::IntegrationTest
  test "Edit exposes a GET-only OIDC logout return route" do
    host = Rails.configuration.x.boot_config.fetch(:hosts).edit_staff.host
    route = Rails.application.routes.recognize_path("https://#{host}/sign/out/completion", method: :get)

    assert_equal "edit/org/sign/outs", route.fetch(:controller)
    assert_equal "show", route.fetch(:action)
    assert_raises(ActionController::RoutingError) do
      Rails.application.routes.recognize_path("https://#{host}/sign/out/completion", method: :post)
    end
    assert_raises(ActionController::RoutingError) do
      Rails.application.routes.recognize_path("https://#{host}/sign/out", method: :delete)
    end
  end

  test "the obsolete sign-out completion path is unroutable" do
    assert_raises(ActionController::RoutingError) do
      Rails.application.routes.recognize_path("https://edit.org.localhost/sign/out/complete", method: :get)
    end

    assert_equal 5.minutes, Valkey::AuthState::SignOutNoticeStore::TTL
  end
end
