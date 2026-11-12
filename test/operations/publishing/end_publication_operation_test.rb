# frozen_string_literal: true

require "test_helper"

module Publishing
  class EndPublicationOperationTest < ActiveSupport::TestCase
    test "cancels a future window and records the operator and reason" do
      entry = publishing_draft(audience: "app", surface: "docs", slug: "cancel-window", title: "Cancel")
      version = PromoteRevisionOperation.call(revision: entry.current_revision)
      publication = entry.publications.create!(entry_version: version, effective_from: 1.hour.from_now)

      result = EndPublicationOperation.call(
        publication:,
        reason: "publication postponed",
        operator_public_id: "OPERATORPUBLICID1",
      )

      assert_predicate result, :ok?
      publication.reload

      assert_not_nil publication.cancelled_at
      assert_equal "publication postponed", publication.cancellation_reason
      assert_equal "OPERATORPUBLICID1", publication.ended_by_operator_public_id
      assert_nil publication.terminated_at
    end

    test "terminates a live window at the current time" do
      entry = publishing_draft(audience: "app", surface: "docs", slug: "terminate-window", title: "Terminate")
      version = PromoteRevisionOperation.call(revision: entry.current_revision)
      publication = entry.publications.create!(entry_version: version, effective_from: 1.hour.ago)

      result = EndPublicationOperation.call(
        publication:,
        reason: "replaced",
        operator_public_id: "OPERATORPUBLICID1",
      )

      assert_predicate result, :ok?
      publication.reload

      assert_equal publication.terminated_at, publication.effective_until
      assert_equal "replaced", publication.termination_reason
      assert_equal "OPERATORPUBLICID1", publication.ended_by_operator_public_id
    end
  end
end
