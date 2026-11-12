# frozen_string_literal: true

require "test_helper"

class RpCellBindingTest < ActiveSupport::TestCase
  test "the public connection catalog and client lookup share fixed bindings" do
    assert_equal ["rp_edit_org"], RpCellBinding.connections
    assert_equal RpCellBinding::CELLS.keys, RpCellBinding.connections
    RpCellBinding::CELLS.each do |connection, cell|
      assert_equal cell, RpCellBinding.fetch(connection)
    end

    edit = RpCellBinding.fetch("rp_edit_org")

    assert_equal edit, RpCellBinding.for_client(edit.client_id)
  end

  test "unknown connections and client IDs are rejected" do
    assert_raises(RpCellBinding::UnknownCell) { RpCellBinding.fetch("missing") }
    assert_raises(RpCellBinding::UnknownCell) { RpCellBinding.for_client("missing") }
    assert_raises(RpCellBinding::UnknownCell) { RpCellBinding.for_client("core-app-jp") }
    assert_raises(RpCellBinding::UnknownCell) { RpCellBinding.fetch("rp_core_app") }
  end
end
