# typed: false
# frozen_string_literal: true

require "test_helper"

module Security
  module Invariants
    class PrivateAuthorizationPostconditionInvariantTest < ActiveSupport::TestCase
      self.fixture_table_names = []

      test "Edit verifies resource authorization after private actions" do
        controller = Rails.root.join("app/controllers/edit/org/application_controller.rb").read
        authentication = Rails.root.join("app/controllers/concerns/browser_rp_authentication.rb").read

        assert_includes controller, "after_action :verify_private_action_authorized!"
        assert_includes authentication, "self.class.authentication_mode_for(action_name) == :private"
        assert_includes authentication, "verify_authorized"
      end

      test "authorization postcondition bypass APIs are absent from application controllers" do
        offenders =
          Rails.root.glob("app/controllers/**/*.rb").filter do |path|
            path.read.match?(/skip_verify_authorized|skip_after_action\s+:verify_private_action_authorized/)
          end

        assert_empty offenders
      end
    end
  end
end
