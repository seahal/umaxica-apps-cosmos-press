# typed: false
# frozen_string_literal: true

require "test_helper"

class BranchCoverageBatch33PreciseArmsTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  test "Publishing create entry operation easy guard" do
    error = assert_raises(ArgumentError) { Publishing::CreateEntryOperation.new }

    assert_match(/missing keyword/, error.message)
  end
end
