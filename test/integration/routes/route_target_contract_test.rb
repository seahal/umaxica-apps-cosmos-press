# typed: false
# frozen_string_literal: true

require "test_helper"

class RouteTargetContractTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  PRESS_CONTROLLER_PREFIX = %r{\A(?:edit|docs|help|info|news)/}

  test "retained Press routes reference loadable controllers and routable actions" do
    missing_controllers = []
    missing_actions = []

    press_routes.each do |route|
      controller_path = route.defaults.fetch(:controller)
      action_name = route.defaults.fetch(:action).to_s
      controller_name = "#{controller_path.camelize}Controller"
      controller = controller_name.constantize

      missing_actions << "#{controller_path}##{action_name}" unless controller.action_methods.include?(action_name)
    rescue NameError
      missing_controllers << controller_name
    end

    assert_empty missing_controllers.uniq.sort,
                 "Retained Press routes reference missing controller classes"
    assert_empty missing_actions.uniq.sort,
                 "Retained Press routes reference controllers without routable actions"
  end

  test "retained Press route controllers declare authentication mode explicitly" do
    missing_authentication_modes =
      press_route_controllers.filter_map do |controller|
        controller.name unless controller.const_defined?(:AUTHENTICATION_MODE, false)
      end

    assert_empty missing_authentication_modes.uniq.sort,
                 "Retained Press route controllers must declare AUTHENTICATION_MODE on the concrete class"
  end

  private

  def press_routes
    Rails.application.routes.routes.select do |route|
      controller = route.defaults[:controller]
      action = route.defaults[:action]

      controller.present? && action.present? && controller.match?(PRESS_CONTROLLER_PREFIX)
    end
  end

  def press_route_controllers
    press_routes.map do |route|
      "#{route.defaults.fetch(:controller).camelize}Controller".constantize
    end.uniq
  end
end
