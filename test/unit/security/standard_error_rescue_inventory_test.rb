# frozen_string_literal: true

require "test_helper"

class StandardErrorRescueInventoryTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  test "controllers preserve explicit dependency failures instead of broadly rescuing StandardError" do
    offenders =
      Rails.root.glob("app/controllers/**/*.rb").flat_map do |path|
        path.readlines.each_with_index.filter_map do |line, index|
          next if line.lstrip.start_with?("#")
          next unless line.match?(/\brescue\s+StandardError\b/)

          "#{path.relative_path_from(Rails.root)}:#{index + 1}"
        end
      end

    assert_empty offenders
  end
end
