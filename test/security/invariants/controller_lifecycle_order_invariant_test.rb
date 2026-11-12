# typed: false
# frozen_string_literal: true

require "test_helper"
# require "helpers/global_test_support"

module Security
  module Invariants
    class ControllerLifecycleOrderInvariantTest < ActiveSupport::TestCase
      self.fixture_table_names = []

      AUTHENTICATED_SURFACE_CONTROLLERS = [Edit::Org::ApplicationController].freeze

      REQUIRED_ORDER = %i(
        apply_default_no_store
        enforce_fqdn_availability!
        authenticate_browser_rp_unsafe_request!
        authenticate_browser_rp_safe_request!
        verify_jump_return_rt!
        enforce_access_policy!
      ).freeze

      test "the Edit browser RP keeps the reviewed lifecycle order" do
        violations =
          AUTHENTICATED_SURFACE_CONTROLLERS.filter_map do |controller|
            filters = before_filters_for(controller)
            required_order = REQUIRED_ORDER
            missing = required_order - filters
            out_of_order = out_of_order_filters(filters, required_order)
            next if missing.empty? && out_of_order.empty?

            "#{controller.name}: missing=#{missing.inspect}, out_of_order=#{out_of_order.inspect}"
          end

        assert_empty violations, "Authentication lifecycle callback order drifted:\n#{violations.join("\n")}"
      end

      test "Edit keeps request-local identity without retired global Actor lifecycle callbacks" do
        controller = Edit::Org::ApplicationController
        filters = controller._process_action_callbacks.map(&:filter)

        assert_not_includes filters, :with_actor_lifecycle
        assert_not_includes filters, :set_current_actor
        assert_not_includes filters, :set_preferences_cookie
        assert_not_includes filters, :enforce_verification_if_required
        assert_includes filters, :verify_authenticity_token
        assert_includes filters, :verify_private_action_authorized!
        assert_includes filters, :apply_authenticated_page_cache_policy!
      end

      private

      def before_filters_for(controller)
        controller._process_action_callbacks.filter_map do |callback|
          callback.filter if callback.kind == :before
        end
      end

      def out_of_order_filters(filters, required_order)
        positions =
          required_order.filter_map do |filter|
            index = filters.index(filter)
            [filter, index] if index
          end

        positions.each_cons(2).filter_map do |(left_filter, left_index), (right_filter, right_index)|
          next if left_index < right_index

          "#{left_filter} must run before #{right_filter}"
        end
      end
    end
  end
end
