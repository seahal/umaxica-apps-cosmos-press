# typed: false
# frozen_string_literal: true

require "test_helper"

class RoutingEntrypointsTest < ActiveSupport::TestCase
  test "retained Press routing entrypoints are loaded" do
    assert_nothing_raised { Rails.application.reload_routes! }

    %w(docs help info news).each do |surface|
      %w(app com org).each do |audience|
        host = "#{surface}.#{audience}.localhost"
        route = Rails.application.routes.recognize_path("http://#{host}/health", method: :get)

        assert_equal "#{surface}/#{audience}/healths", route.fetch(:controller), host
        assert_equal "show", route.fetch(:action), host
      end
    end

    edit_root = Rails.application.routes.recognize_path("http://edit.org.localhost/", method: :get)

    assert_equal "edit/org/roots", edit_root.fetch(:controller)
    assert_equal "index", edit_root.fetch(:action)
  end
end
