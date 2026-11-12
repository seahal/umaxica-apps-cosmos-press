# typed: false
# frozen_string_literal: true

require "test_helper"

class LayoutControllerContractTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  CONTROLLERS = {
    "app/controllers/edit/org/application_controller.rb" => ["Edit::Org::ApplicationController",
                                                             "edit/org/application",],
  }.freeze

  test "application controllers declare literal layouts" do
    CONTROLLERS.each do |path, (controller_name, layout_name)|
      contents = Rails.root.join(path).read
      controller = controller_name.safe_constantize

      assert_predicate controller, :present?
      assert_equal layout_name, controller._layout
      assert_includes contents, %(layout "#{layout_name}"), "missing literal layout declaration in #{path}"
      assert_no_match(
        /\blayout\s*(?:->|do|proc|lambda|method)/, contents,
        "layout declaration in #{path} must stay literal",
      )
    end
  end
end
