# frozen_string_literal: true

require "test_helper"

module Publishing
  class VersionAndCurrentRevisionUniquenessTest < ActiveSupport::TestCase
    self.fixture_table_names = []

    ContentFamilies::CELL_BY_ENTRY.each_value do |cell|
      test "#{cell.fetch(:version).name} preflights source and sequence with DB uniqueness and immutable updates" do
        entry = cell.fetch(:entry).create!(locale: "en")
        metadata = {
          locale: "en", title: "Version", body: {}, schema_version: 1, content_digest: "d" * 64,
        }
        revision = cell.fetch(:revision).create!(metadata.merge(entry: entry, sequence: 1))
        other_revision = cell.fetch(:revision).create!(metadata.merge(entry: entry, sequence: 2))
        version = PromoteRevisionOperation.call(revision: revision)
        attributes = version.attributes.except("id", "public_id")
        duplicate_source = cell.fetch(:version).new(attributes.merge("sequence" => 2))

        assert_not duplicate_source.valid?
        assert duplicate_source.errors.of_kind?(:entry_revision_id, :taken)
        assert_raises(ActiveRecord::RecordInvalid) { duplicate_source.save! }
        error =
          assert_raises(ActiveRecord::RecordNotUnique) do
            PublishingRecord.transaction(requires_new: true) { duplicate_source.save!(validate: false) }
          end
        assert_match(/_ver_on_revision\z/, error.cause.result.error_field(PG::Result::PG_DIAG_CONSTRAINT_NAME))

        duplicate_sequence = cell.fetch(:version).new(attributes.merge("entry_revision_id" => other_revision.id))

        assert_not duplicate_sequence.valid?
        assert duplicate_sequence.errors.of_kind?(:sequence, :taken)
        assert_raises(ActiveRecord::RecordInvalid) { duplicate_sequence.save! }
        error =
          assert_raises(ActiveRecord::RecordNotUnique) do
            PublishingRecord.transaction(requires_new: true) { duplicate_sequence.save!(validate: false) }
          end
        assert_match(/_ver_seq\z/, error.cause.result.error_field(PG::Result::PG_DIAG_CONSTRAINT_NAME))

        independent_entry = cell.fetch(:entry).create!(locale: "en")
        independent_revision = cell.fetch(:revision).create!(metadata.merge(entry: independent_entry, sequence: 1))
        independent_version = PromoteRevisionOperation.call(revision: independent_revision)

        assert_equal 1, independent_version.reload.sequence
        assert_predicate version, :valid?
        assert_raises(ActiveRecord::ReadOnlyRecord) { version.update!(sequence: 2) }
        version.reload

        assert_raises(ActiveRecord::ReadOnlyRecord) { version.update!(entry_revision_id: other_revision.id) }
        assert_equal revision.id, version.reload.entry_revision_id
        assert_equal 1, version.sequence
      end

      test "#{cell.fetch(:entry).name} preflights occupied revisions and preserves NULL and owned FK rules" do
        entry = cell.fetch(:entry).create!(locale: "en")
        other_entry = cell.fetch(:entry).create!(locale: "en")
        revision = cell.fetch(:revision).create!(
          entry: entry, locale: "en", title: "Current", body: {},
          schema_version: 1, content_digest: "d" * 64, sequence: 1,
        )
        entry.update!(current_revision: revision)
        other_entry.assign_attributes(current_revision: revision)

        assert_not other_entry.valid?
        assert other_entry.errors.of_kind?(:current_revision_id, :taken)
        assert_raises(ActiveRecord::RecordInvalid) { other_entry.save! }
        error =
          assert_raises(ActiveRecord::RecordNotUnique) do
            PublishingRecord.transaction(requires_new: true) do
              cell.fetch(:entry).where(id: other_entry.id).update_all(current_revision_id: revision.id)
            end
          end
        assert_match(/_ent_current_rev\z/, error.cause.result.error_field(PG::Result::PG_DIAG_CONSTRAINT_NAME))
        assert_predicate entry, :valid?
        entry.update!(current_revision: nil)

        assert_nil entry.reload.current_revision_id
        assert_nil other_entry.reload.current_revision_id
        assert_predicate entry, :valid?
        assert_predicate other_entry, :valid?
        error =
          assert_raises(ActiveRecord::InvalidForeignKey) do
            PublishingRecord.transaction(requires_new: true) do
              cell.fetch(:entry).where(id: other_entry.id).update_all(current_revision_id: revision.id)
            end
          end
        assert_instance_of PG::ForeignKeyViolation, error.cause
        assert_nil other_entry.reload.current_revision_id
      end
    end
  end
end
