# frozen_string_literal: true

require "test_helper"

module Publishing
  class RestorationReferenceIndexTest < ActiveSupport::TestCase
    self.fixture_table_names = []

    ContentFamilies::CELL_BY_ENTRY.each_value do |cell|
      test "#{cell.fetch(:revision).name} locates revision restorations through an indexed foreign reference" do
        entry = cell.fetch(:entry).create!(locale: "en")
        attributes = {
          entry: entry,
          locale: "en",
          title: "Restore revision",
          body: {},
          schema_version: 1,
          content_digest: "d" * 64,
        }
        source = cell.fetch(:revision).create!(attributes.merge(sequence: 1))
        restored = cell.fetch(:revision).create!(attributes.merge(sequence: 2, restored_from_revision: source))
        cell.fetch(:revision).create!(attributes.merge(sequence: 3))
        source = cell.fetch(:revision).includes(:restored_revisions).find(source.id)

        assert_equal [restored.id], source.restored_revisions.pluck(:id)
        PublishingRecord.transaction(requires_new: true) do
          connection = PublishingRecord.lease_connection
          connection.execute("SET LOCAL enable_seqscan = off")
          lookup = source.restored_revisions.where(restored_from_revision_id: source.id)
          plan = connection.select_values("EXPLAIN (COSTS OFF) #{lookup.to_sql}").join("\n")

          assert_match(/Index Cond:.*restored_from_revision_id.*=/, plan)
          assert_includes plan,
                          "idx_#{cell.fetch(:entry)::SURFACE}_#{cell.fetch(:entry)::AUDIENCE}_rev_restored_revision"
        end
        assert_equal source.id, restored.reload.restored_from_revision_id
      end

      test "#{cell.fetch(:version).name} locates version restorations through an indexed foreign reference" do
        entry = cell.fetch(:entry).create!(locale: "en")
        attributes = {
          entry: entry,
          locale: "en",
          title: "Restore version",
          body: {},
          schema_version: 1,
          content_digest: "d" * 64,
        }
        source = cell.fetch(:revision).create!(attributes.merge(sequence: 1))
        version = PromoteRevisionOperation.call(revision: source)
        restored = cell.fetch(:revision).create!(attributes.merge(sequence: 2, restored_from_version: version))
        cell.fetch(:revision).create!(attributes.merge(sequence: 3))
        version = cell.fetch(:version).includes(:restored_revisions).find(version.id)

        assert_equal [restored.id], version.restored_revisions.pluck(:id)
        PublishingRecord.transaction(requires_new: true) do
          connection = PublishingRecord.lease_connection
          connection.execute("SET LOCAL enable_seqscan = off")
          lookup = version.restored_revisions.where(restored_from_version_id: version.id)
          plan = connection.select_values("EXPLAIN (COSTS OFF) #{lookup.to_sql}").join("\n")

          assert_match(/Index Cond:.*restored_from_version_id.*=/, plan)
          assert_includes plan,
                          "idx_#{cell.fetch(:entry)::SURFACE}_#{cell.fetch(:entry)::AUDIENCE}_rev_restored_version"
        end
        assert_equal version.id, restored.reload.restored_from_version_id
      end
    end
  end
end
