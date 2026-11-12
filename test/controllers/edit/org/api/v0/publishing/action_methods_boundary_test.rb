# frozen_string_literal: true

require "test_helper"

# Routed requests stop at the unavailable authority callback; these direct calls exercise each
# action's own first rejection without bypassing its policy or reaching a query or mutation.
class Edit::Org::Api::V0::Publishing::EntriesActionMethodsBoundaryTest < ActionController::TestCase
  self.fixture_table_names = []
  tests Edit::Org::Api::V0::Publishing::EntriesController

  test "index denies an operator-less direct invocation" do
    @controller.params = ActionController::Parameters.new

    assert_raises(ActionPolicy::Unauthorized) { @controller.index }
  end

  test "show rejects a cell outside the fixed Publishing inventory before querying" do
    @controller.params = ActionController::Parameters.new(surface: "unknown", audience: "app", entry_ref: "entry-1")

    assert_raises(ActiveRecord::RecordNotFound) { @controller.show }
  end

  test "create denies an operator-less direct invocation" do
    @controller.params = ActionController::Parameters.new

    assert_raises(ActionPolicy::Unauthorized) { @controller.create }
  end

  test "update rejects a cell outside the fixed Publishing inventory before querying" do
    @controller.params = ActionController::Parameters.new(surface: "unknown", audience: "app", entry_ref: "entry-1")

    assert_raises(ActiveRecord::RecordNotFound) { @controller.update }
  end
end

class Edit::Org::Api::V0::Publishing::PublicationsActionMethodsBoundaryTest < ActionController::TestCase
  self.fixture_table_names = []
  tests Edit::Org::Api::V0::Publishing::PublicationsController

  test "create rejects a cell outside the fixed Publishing inventory before querying" do
    @controller.params = ActionController::Parameters.new(
      surface: "unknown", audience: "app", entry_entry_ref: "entry-1",
    )

    assert_raises(ActiveRecord::RecordNotFound) { @controller.create }
  end

  test "destroy rejects a cell outside the fixed Publishing inventory before querying" do
    @controller.params = ActionController::Parameters.new(
      surface: "unknown", audience: "app", entry_entry_ref: "entry-1", publication_ref: "publication-1",
    )

    assert_raises(ActiveRecord::RecordNotFound) { @controller.destroy }
  end
end

class Edit::Org::Api::V0::Publishing::ArchivesActionMethodsBoundaryTest < ActionController::TestCase
  self.fixture_table_names = []
  tests Edit::Org::Api::V0::Publishing::ArchivesController

  test "create rejects a cell outside the fixed Publishing inventory before querying" do
    @controller.params = ActionController::Parameters.new(
      surface: "unknown", audience: "app", entry_entry_ref: "entry-1",
    )

    assert_raises(ActiveRecord::RecordNotFound) { @controller.create }
  end

  test "destroy rejects a cell outside the fixed Publishing inventory before querying" do
    @controller.params = ActionController::Parameters.new(
      surface: "unknown", audience: "app", entry_entry_ref: "entry-1",
    )

    assert_raises(ActiveRecord::RecordNotFound) { @controller.destroy }
  end
end
