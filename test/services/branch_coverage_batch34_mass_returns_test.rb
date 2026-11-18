# typed: false
# frozen_string_literal: true

require "test_helper"

class BranchCoverageBatch34MassReturnsTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  test "JumpRtReturnPolicy normalize_origin rejection arms" do
    assert_nil JumpRtReturnPolicy.normalize_origin("ftp://x")
    assert_nil JumpRtReturnPolicy.normalize_origin("not a uri")
    assert_nil JumpRtReturnPolicy.normalize_origin("http://user:pass@example.test")
    assert_nil JumpRtReturnPolicy.normalize_origin("")
    assert_kind_of String, JumpRtReturnPolicy.normalize_origin("https://www.umaxica.app")
  end

  test "Publishing promote revision missing entry" do
    revision = Object.new
    revision.define_singleton_method(:id) { 1 }
    revision.define_singleton_method(:entry) { nil }

    assert_raises(Publishing::PromoteRevisionOperation::RevisionMismatchError) do
      Publishing::PromoteRevisionOperation.new(revision: revision).call
    end
  end
end
