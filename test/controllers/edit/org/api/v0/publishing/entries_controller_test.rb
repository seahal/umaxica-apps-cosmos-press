# frozen_string_literal: true

require "test_helper"

class Edit::Org::Api::V0::Publishing::EntriesControllerTest < ActionController::TestCase
  self.fixture_table_names = []

  test "all publishing cells refuse reads while governance authorization is unavailable" do
    %w(docs help info news).product(%w(app com org)).each do |surface, audience|
      get :index, params: { surface:, audience: }

      assert_response :service_unavailable
      assert_equal 503, response.parsed_body.fetch("status")
      assert_not response.parsed_body.key?("entries")
    end
  end

  test "unknown and empty publishing targets are excluded by the public route" do
    [["unknown", "app"], ["docs", "unknown"], ["", "app"], ["docs", ""]].each do |surface, audience|
      assert_raises(ActionController::UrlGenerationError) do
        get :index, params: { surface:, audience: }
      end
    end
  end
end
