# frozen_string_literal: true

require "test_helper"

module Publishing
  class UnarchiveEntryOperationTest < ActiveSupport::TestCase
    test "clears every archive fact together" do
      entry = publishing_draft(audience: "app", surface: "docs", slug: "unarchive", title: "Unarchive")
      entry.update!(
        archived_at: Time.current,
        archive_reason: "superseded",
        archived_by_operator_public_id: "OPERATORPUBLICID1",
      )

      result = UnarchiveEntryOperation.call(entry:, operator_public_id: "OPERATORPUBLICID2")

      assert_predicate result, :ok?
      assert_same entry, result.entry
      assert_nil entry.reload.archived_at
      assert_nil entry.archive_reason
      assert_nil entry.archived_by_operator_public_id
    end

    test "refuses an entry that is not archived" do
      entry = publishing_draft(audience: "app", surface: "docs", slug: "active-entry", title: "Active")

      result = UnarchiveEntryOperation.call(entry:, operator_public_id: "OPERATORPUBLICID2")

      assert_not_predicate result, :ok?
      assert_equal "entry is not archived", result.errors.fetch(:base)
      assert_nil entry.reload.archived_at
    end
  end
end
