# typed: false
# frozen_string_literal: true

require "test_helper"
# require "helpers/global_test_support"
# require "helpers/csrf_route_coverage_helper"

module Security
  class CsrfRouteCoverageTest < ActiveSupport::TestCase
    # include CsrfRouteCoverageHelper

    self.fixture_table_names = []

    NULL_SESSION_STRATEGY = ActionController::RequestForgeryProtection::ProtectionMethods::NullSession
    PROTOCOL_ENDPOINTS = [
      # Publishing authority is a bearer-token JSON API, with no browser session cookies.
      %r{\A/api/v0/publishing/},
    ].freeze

    test "state-changing application routes do not use null-session csrf handling" do
      violations =
        state_changing_application_route_targets.filter_map do |target|
          next if protocol_endpoint?(target)

          controller_class = target.fetch(:controller_class)
          next unless controller_class.respond_to?(:forgery_protection_strategy)
          next unless controller_class.forgery_protection_strategy == NULL_SESSION_STRATEGY

          "#{target.fetch(:verb)} #{target.fetch(:path)} -> " \
            "#{target.fetch(:controller)}##{target.fetch(:action)}"
        end

      assert_empty violations,
                   "State-changing routes must reject missing/invalid CSRF tokens instead of " \
                   "using null_session. Review:\n  #{violations.join("\n  ")}"
    end

    private

    def protocol_endpoint?(target)
      PROTOCOL_ENDPOINTS.any? { |pattern| pattern.match?(target.fetch(:path)) }
    end

    def state_changing_application_route_targets
      Rails.application.routes.routes.filter_map do |route|
        verbs = route_verbs(route)
        next if verbs.empty? || (verbs - %w(GET HEAD)).empty?

        controller = route.required_defaults[:controller].to_s
        action = route.required_defaults[:action].to_s
        next if controller.blank? || action.blank?

        controller_class = controller_class_for(controller)
        next unless controller_class

        {
          verb: verbs.join("|"),
          path: route.path.spec.to_s,
          controller: controller,
          action: action,
          controller_class: controller_class,
        }
      end
    end

    def route_verbs(route)
      route.verb.to_s.delete("^A-Z|").split("|")
    end

    def controller_class_for(controller)
      controller_class_name = "#{controller.camelize}Controller"
      return nil unless Rails.root.join("app/controllers/#{controller}_controller.rb").exist?

      Object.const_get(controller_class_name)
    rescue NameError
      nil
    end
  end
end
