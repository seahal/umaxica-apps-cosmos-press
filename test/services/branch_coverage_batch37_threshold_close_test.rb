# typed: false
# frozen_string_literal: true

require "test_helper"

# Focused arms that close the remaining ~0.5-1.2 branch points to the 90% floor.
# Prefer calling real methods; stubs only fill collaborators.
class BranchCoverageBatch37ThresholdCloseTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  test "Publishing ArchiveEntryOperation refuses active publications" do
    publications = Object.new
    publications.define_singleton_method(:active) { publications }
    publications.define_singleton_method(:exists?) { true }

    entry = Object.new
    entry.define_singleton_method(:archived?) { false }
    entry.define_singleton_method(:publications) { publications }
    entry.define_singleton_method(:with_lock) { |&block| block.call }

    result = Publishing::ArchiveEntryOperation.new(
      entry: entry,
      reason: "cleanup",
      operator_public_id: "op-1",
    ).call

    assert_not result.ok?
    assert_match(/published entry cannot be archived/i, result.errors[:base].to_s)
  end
end
