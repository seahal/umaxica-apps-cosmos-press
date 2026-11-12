# frozen_string_literal: true

require "test_helper"

class PreferenceApiRouteContractTest < ActionDispatch::IntegrationTest
  HOST = ENV.fetch("PUBLIC_EDIT_STAFF_URL", "edit.org.localhost")

  test "Edit does not claim the unassigned browser preference API" do
    %w(theme cookie web_push).product(%i(get patch put)).each do |resource, method|
      path = "/api/v0/preferences/#{resource}"

      assert_raises(ActionController::RoutingError, "#{method} #{HOST}#{path}") do
        Rails.application.routes.recognize_path("https://#{HOST}#{path}", method: method)
      end
    end
  end
end
