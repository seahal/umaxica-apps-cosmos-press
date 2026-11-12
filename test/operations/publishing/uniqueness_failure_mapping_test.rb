# frozen_string_literal: true

require "test_helper"

module Publishing
  class UniquenessFailureMappingTest < ActiveSupport::TestCase
    self.fixture_table_names = []

    ContentFamilies::CELL_BY_ENTRY.each_value do |cell|
      test "#{cell.fetch(:entry).name} maps only slug taken validation to the existing creation result" do
        original = CreateEntryOperation.call(
          entry_class: cell.fetch(:entry), locale: "en", slug: "taken-guide", title: "Guide",
          summary: "Summary", body: {}, operator_public_id: nil,
        )
        duplicate = CreateEntryOperation.call(
          entry_class: cell.fetch(:entry), locale: "en", slug: "taken-guide", title: "Duplicate",
          summary: "Summary", body: {}, operator_public_id: nil,
        )

        assert_predicate original, :ok?
        assert_not_predicate duplicate, :ok?
        assert_equal({ slug: "is already used by another entry in this locale" }, duplicate.errors)
        assert_equal 1, cell.fetch(:entry).count
        assert_equal 1, cell.fetch(:revision).count
        error =
          assert_raises(ActiveRecord::RecordInvalid) do
            CreateEntryOperation.call(
              entry_class: cell.fetch(:entry), locale: "en", slug: nil, title: "Missing slug",
              summary: "Summary", body: {}, operator_public_id: nil,
            )
          end
        assert_instance_of original.entry.slugs.klass, error.record
        assert_not error.record.errors.of_kind?(:slug, :taken)
        error =
          assert_raises(ActiveRecord::RecordInvalid) do
            CreateEntryOperation.call(
              entry_class: cell.fetch(:entry), locale: nil, slug: "taken-guide", title: "Missing locale",
              summary: "Summary", body: {}, operator_public_id: nil,
            )
          end
        assert_instance_of cell.fetch(:entry), error.record
        assert_equal 1, cell.fetch(:entry).count
      end

      test "#{cell.fetch(:version).name} returns the complete winner inserted between lookup and preflight" do
        entry = cell.fetch(:entry).create!(locale: "en")
        revision = cell.fetch(:revision).create!(
          entry: entry, locale: "en", title: "Promotion race", body: {},
          schema_version: 1, content_digest: "d" * 64, sequence: 1,
        )
        inserted = false
        winner = nil
        version_table = cell.fetch(:version).table_name
        observer =
          lambda do |event|
            sql = event.payload.fetch(:sql)
            next if inserted || !sql.start_with?("SELECT") || sql.exclude?(%("#{version_table}")) ||
              sql.exclude?(%q("entry_revision_id")) || sql.exclude?("LIMIT")

            inserted = true
            winner = cell.fetch(:version).create!(
              entry: entry, entry_revision: revision, locale: "en", title: "Promotion race", body: {},
              schema_version: 1, content_digest: "d" * 64, sequence: 1,
            )
          end
        result =
          ActiveSupport::Notifications.subscribed(observer, "sql.active_record") do
            PromoteRevisionOperation.call(revision: revision)
          end

        assert inserted
        assert_equal winner.id, result.id
        assert_equal [winner.id], cell.fetch(:version).where(entry_id: entry.id).pluck(:id)
      end

      test "#{cell.fetch(:version).name} never hides another validation error behind a promotion conflict" do
        entry = cell.fetch(:entry).create!(locale: "en")
        revision = cell.fetch(:revision).create!(
          entry: entry, locale: "en", title: "Invalid promotion", body: {},
          schema_version: 1, content_digest: "d" * 64, sequence: 1,
        )
        inserted = false
        version_table = cell.fetch(:version).table_name
        observer =
          lambda do |event|
            sql = event.payload.fetch(:sql)
            next if inserted || !sql.start_with?("SELECT") || sql.exclude?(%("#{version_table}")) ||
              sql.exclude?(%q("entry_revision_id")) || sql.exclude?("LIMIT")

            inserted = true
            cell.fetch(:version).create!(
              entry: entry, entry_revision: revision, locale: "en", title: "Invalid promotion", body: {},
              schema_version: 1, content_digest: "d" * 64, sequence: 1,
            )
          end
        error =
          assert_raises(ActiveRecord::RecordInvalid) do
            ActiveSupport::Notifications.subscribed(observer, "sql.active_record") do
              PromoteRevisionOperation.call(revision: revision, operator_public_id: "x" * 22)
            end
          end

        assert inserted
        assert_instance_of cell.fetch(:version), error.record
        assert error.record.errors.of_kind?(:entry_revision_id, :taken)
        assert error.record.errors.of_kind?(:created_by_operator_public_id, :too_long)
        assert_equal 0, cell.fetch(:version).where(entry_id: entry.id).count
      end
    end
  end
end
