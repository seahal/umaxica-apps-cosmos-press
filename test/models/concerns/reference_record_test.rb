# typed: false
# frozen_string_literal: true

require "test_helper"

class ReferenceRecordTest < ActiveSupport::TestCase
  test "record_timestamps is false" do
    assert_not ClientChronicleLevel.record_timestamps
  end

  test "nothing_id returns NOTHING constant" do
    assert_equal ClientChronicleLevel::NOTHING, ClientChronicleLevel.nothing_id
  end
end
