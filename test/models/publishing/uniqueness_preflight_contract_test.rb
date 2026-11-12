# frozen_string_literal: true

require "test_helper"

module Publishing
  class UniquenessPreflightContractTest < ActiveSupport::TestCase
    self.fixture_table_names = []

    ContentFamilies::CELL_BY_ENTRY.each do |entry_class, cell|
      test "#{entry_class.name} taxonomy preflights slug and sibling collisions while SQL stays authoritative" do
        vocabulary_class = cell.fetch(:vocabulary)
        term_class = cell.fetch(:taxonomy_term)
        [TaxonomyKind::SINGLE_HIERARCHICAL, TaxonomyKind::MULTIPLE_ORDERED_FLAT].each_with_index do |kind, index|
          vocabulary = vocabulary_class.create!(key: "preflight_#{index}", kind: kind, internal_name: "Contract")
          attributes = {
            vocabulary: vocabulary,
            vocabulary_kind: kind,
            locale: "ja",
            slug: "first",
            name: "First",
            depth: 0,
            position: 0,
          }
          first = term_class.create!(attributes)
          first.update!(archived_at: Time.utc(2026, 1, 1), archive_reason: "Reserved")
          [[attributes.merge(position: 1), :slug],
           [attributes.merge(slug: "second"), :position],].each do |values, attribute|
            duplicate = term_class.new(values)

            assert_not duplicate.valid?
            assert duplicate.errors.of_kind?(attribute, :taken)
            assert_raises(ActiveRecord::RecordInvalid) { duplicate.save! }
            assert_predicate duplicate, :new_record?
          end
          error =
            assert_raises(ActiveRecord::RecordNotUnique) do
              term_class.transaction(requires_new: true) {
                term_class.insert_all!([first.attributes.except("id").merge("public_id" => "t" * 21)])
              }
            end
          assert_instance_of PG::UniqueViolation, error.cause
          alternate_locale = term_class.create!(attributes.merge(locale: "en"))
          second = term_class.create!(attributes.merge(slug: "second", position: 1))

          assert_equal "en", alternate_locale.reload.locale
          assert_equal 1, second.reload.position
          assert_equal "first", first.reload.slug
          assert_predicate first, :archived?
          assert_predicate second, :valid?
        end
      end

      test "#{entry_class.name} revision assignments preflight ownership scopes and retain raw uniqueness" do
        vocabulary_class = cell.fetch(:vocabulary)
        term_class = cell.fetch(:taxonomy_term)
        single_class = cell.fetch(:revision_single)
        multiple_class = cell.fetch(:revision_multiple)
        category = vocabulary_class.create!(
          key: "preflight_category", kind: TaxonomyKind::SINGLE_HIERARCHICAL,
          internal_name: "Category",
        )
        tag = vocabulary_class.create!(
          key: "preflight_tag", kind: TaxonomyKind::MULTIPLE_ORDERED_FLAT,
          internal_name: "Tag",
        )
        first = term_class.create!(
          vocabulary: category, vocabulary_kind: category.kind, locale: "ja", slug: "first",
          name: "First", position: 0,
        )
        second = term_class.create!(
          vocabulary: category, vocabulary_kind: category.kind, locale: "ja", slug: "second",
          name: "Second", position: 1,
        )
        ruby = term_class.create!(
          vocabulary: tag, vocabulary_kind: tag.kind, locale: "ja", slug: "ruby", name: "Ruby",
          position: 0,
        )
        rails = term_class.create!(
          vocabulary: tag, vocabulary_kind: tag.kind, locale: "ja", slug: "rails",
          name: "Rails", position: 1,
        )
        entry = entry_class.create!(locale: "ja")
        revision = cell.fetch(:revision).create!(
          entry: entry, locale: "ja", title: "Preflight", body: {},
          schema_version: 1, content_digest: "d" * 64, sequence: 1,
        )
        single = single_class.create!(
          entry_revision: revision, vocabulary: category, vocabulary_kind: category.kind,
          taxonomy_term: first, locale: "ja",
        )
        multiple = multiple_class.create!(
          entry_revision: revision, vocabulary: tag, vocabulary_kind: tag.kind,
          taxonomy_term: ruby, locale: "ja", position: 0,
        )
        candidates = [
          [
            single_class.new(
              entry_revision: revision, vocabulary: category, vocabulary_kind: category.kind, taxonomy_term: second,
              locale: "ja",
            ), :vocabulary_id,
          ],
          [
            multiple_class.new(
              entry_revision: revision, vocabulary: tag, vocabulary_kind: tag.kind, taxonomy_term: ruby,
              locale: "ja", position: 1,
            ), :taxonomy_term_id,
          ],
          [
            multiple_class.new(
              entry_revision: revision, vocabulary: tag, vocabulary_kind: tag.kind, taxonomy_term: rails,
              locale: "ja", position: 0,
            ), :position,
          ],
        ]
        candidates.each do |candidate, attribute|
          assert_not candidate.valid?
          assert candidate.errors.of_kind?(attribute, :taken)
          assert_raises(ActiveRecord::RecordInvalid) { candidate.save! }
          assert_predicate candidate, :new_record?
        end
        [single, multiple].each do |record|
          attributes = record.attributes.except("id")
          rows =
            if record == single
              [[attributes.merge("taxonomy_term_id" => second.id), /_rs_owner\z/]]
            else
              [[attributes.merge("position" => 1), /_rm_term\z/],
               [attributes.merge("taxonomy_term_id" => rails.id), /_rm_pos\z/],]
            end
          rows.each do |row, index_pattern|
            error =
              assert_raises(ActiveRecord::RecordNotUnique) do
                record.class.transaction(requires_new: true) { record.class.insert_all!([row]) }
              end
            assert_instance_of PG::UniqueViolation, error.cause
            assert_match index_pattern, error.cause.result.error_field(PG::Result::PG_DIAG_CONSTRAINT_NAME)
          end
        end
        distinct = multiple_class.create!(
          entry_revision: revision, vocabulary: tag, vocabulary_kind: tag.kind,
          taxonomy_term: rails, locale: "ja", position: 1,
        )
        distinct.position = 0

        assert_not distinct.valid?
        assert distinct.errors.of_kind?(:position, :taken)
        assert_raises(ActiveRecord::RecordInvalid) { distinct.save! }
        assert_equal 1, distinct.reload.position
        other_revision = cell.fetch(:revision).create!(
          entry: entry, locale: "ja", title: "Other", body: {},
          schema_version: 1, content_digest: "d" * 64, sequence: 2,
        )
        other_single = single_class.create!(
          entry_revision: other_revision, vocabulary: category,
          vocabulary_kind: category.kind, taxonomy_term: first, locale: "ja",
        )
        other_multiple = multiple_class.create!(
          entry_revision: other_revision, vocabulary: tag,
          vocabulary_kind: tag.kind, taxonomy_term: ruby, locale: "ja", position: 0,
        )

        assert_equal other_revision.id, other_single.reload.entry_revision_id
        assert_equal other_revision.id, other_multiple.reload.entry_revision_id
        assert_predicate single, :valid?
        assert_predicate multiple, :valid?
      end

      test "#{entry_class.name} version assignments preflight creation and preserve SQL and update guards" do
        vocabulary_class = cell.fetch(:vocabulary)
        term_class = cell.fetch(:taxonomy_term)
        single_class = cell.fetch(:version_single)
        multiple_class = cell.fetch(:version_multiple)
        category = vocabulary_class.create!(
          key: "preflight_category", kind: TaxonomyKind::SINGLE_HIERARCHICAL,
          internal_name: "Category",
        )
        tag = vocabulary_class.create!(
          key: "preflight_tag", kind: TaxonomyKind::MULTIPLE_ORDERED_FLAT,
          internal_name: "Tag",
        )
        first = term_class.create!(
          vocabulary: category, vocabulary_kind: category.kind, locale: "ja", slug: "first",
          name: "First", position: 0,
        )
        second = term_class.create!(
          vocabulary: category, vocabulary_kind: category.kind, locale: "ja", slug: "second",
          name: "Second", position: 1,
        )
        ruby = term_class.create!(
          vocabulary: tag, vocabulary_kind: tag.kind, locale: "ja", slug: "ruby", name: "Ruby",
          position: 0,
        )
        rails = term_class.create!(
          vocabulary: tag, vocabulary_kind: tag.kind, locale: "ja", slug: "rails",
          name: "Rails", position: 1,
        )
        entry = entry_class.create!(locale: "ja")
        revision = cell.fetch(:revision).create!(
          entry: entry, locale: "ja", title: "Preflight", body: {},
          schema_version: 1, content_digest: "d" * 64, sequence: 1,
        )
        cell.fetch(:revision_single).create!(
          entry_revision: revision, vocabulary: category,
          vocabulary_kind: category.kind, taxonomy_term: first, locale: "ja",
        )
        cell.fetch(:revision_multiple).create!(
          entry_revision: revision, vocabulary: tag, vocabulary_kind: tag.kind,
          taxonomy_term: ruby, locale: "ja", position: 0,
        )
        version = PromoteRevisionOperation.call(revision: revision)
        single = single_class.find_by!(entry_version_id: version.id)
        multiple = multiple_class.find_by!(entry_version_id: version.id)
        candidates = [
          [
            single_class.new(
              entry_version: version, vocabulary: category, vocabulary_kind: category.kind,
              taxonomy_term: second, locale: "ja",
            ).apply_snapshot(
              vocabulary: category, term: second,
            ), :vocabulary_id,
          ],
          [
            multiple_class.new(
              entry_version: version, vocabulary: tag, vocabulary_kind: tag.kind,
              taxonomy_term: ruby, locale: "ja", position: 1,
            ).apply_snapshot(
              vocabulary: tag, term: ruby,
            ), :taxonomy_term_id,
          ],
          [
            multiple_class.new(
              entry_version: version, vocabulary: tag, vocabulary_kind: tag.kind,
              taxonomy_term: rails, locale: "ja", position: 0,
            ).apply_snapshot(
              vocabulary: tag, term: rails,
            ), :position,
          ],
        ]
        candidates.each do |candidate, attribute|
          assert_not candidate.valid?
          assert candidate.errors.of_kind?(attribute, :taken)
          assert_raises(ActiveRecord::RecordInvalid) { candidate.save! }
          assert_predicate candidate, :new_record?
        end
        [single, multiple].each do |record|
          attributes = record.attributes.except("id", "position_snapshot")
          rows =
            if record == single
              [[attributes.merge("taxonomy_term_id" => second.id), /_vs_owner\z/]]
            else
              [[attributes.merge("position" => 1), /_vm_term\z/],
               [attributes.merge("taxonomy_term_id" => rails.id), /_vm_pos\z/],]
            end
          rows.each do |row, index_pattern|
            error =
              assert_raises(ActiveRecord::RecordNotUnique) do
                record.class.transaction(requires_new: true) { record.class.insert_all!([row]) }
              end
            assert_instance_of PG::UniqueViolation, error.cause
            assert_match index_pattern, error.cause.result.error_field(PG::Result::PG_DIAG_CONSTRAINT_NAME)
          end
          record.term_name_snapshot = "Forbidden mutation"
          assert_raises(ActiveRecord::ReadOnlyRecord) { record.save! }
          assert_not_equal "Forbidden mutation", record.reload.term_name_snapshot
        end
      end

      test "#{entry_class.name} media preflights nullable placement tuples for revisions and immutable versions" do
        revision_usage_class = cell.fetch(:revision_media)
        version_usage_class = cell.fetch(:version_media)
        entry = entry_class.create!(locale: "ja")
        revision = cell.fetch(:revision).create!(
          entry: entry, locale: "ja", title: "Preflight", body: {},
          schema_version: 1, content_digest: "d" * 64, sequence: 1,
        )
        media = MediaFile.create!(
          storage_key: "preflight/media", content_type: "image/png", byte_size: 1,
          digest_algorithm: "sha256", digest: "d" * 64,
        )
        other_media = MediaFile.create!(
          storage_key: "preflight/other-media", content_type: "image/png", byte_size: 1,
          digest_algorithm: "sha256", digest: "d" * 64,
        )
        [["body", nil], [nil, "block"], ["body", "block"]].each do |field_path, block_path|
          usage = revision_usage_class.create!(
            entry_revision: revision, media_file: media, role: "body", position: 0,
            field_path: field_path, block_path: block_path,
          )
          duplicate = revision_usage_class.new(
            entry_revision: revision, media_file: other_media, role: "body",
            position: 0, field_path: field_path, block_path: block_path,
          )

          assert_not duplicate.valid?
          assert duplicate.errors.of_kind?(:position, :taken)
          assert_raises(ActiveRecord::RecordInvalid) { duplicate.save! }
          error =
            assert_raises(ActiveRecord::RecordNotUnique) do
              revision_usage_class.transaction(requires_new: true) {
                revision_usage_class.insert_all!(
                  [usage.attributes.except("id").merge(
                    "public_id" => "m" * 21,
                    "media_file_id" => other_media.id,
                  )],
                )
              }
            end
          assert_instance_of PG::UniqueViolation, error.cause
          distinct = revision_usage_class.create!(
            entry_revision: revision, media_file: media, role: "body",
            position: 1, field_path: field_path, block_path: block_path,
          )

          assert_equal 1, distinct.reload.position
          assert_predicate usage, :valid?
          distinct.position = 0

          assert_not distinct.valid?
          assert distinct.errors.of_kind?(:position, :taken)
          assert_raises(ActiveRecord::RecordInvalid) { distinct.save! }
          assert_equal 1, distinct.reload.position
        end
        version = PromoteRevisionOperation.call(revision: revision)
        snapshots = version_usage_class.where(entry_version_id: version.id).order(:id).to_a

        assert_equal 6, snapshots.size
        snapshots.each do |snapshot|
          duplicate = version_usage_class.new(
            snapshot.attributes.except(
              "id", "public_id", "created_at",
              "updated_at",
            ).merge("media_file_id" => other_media.id),
          )

          assert_not duplicate.valid?
          assert duplicate.errors.of_kind?(:position, :taken)
          assert_raises(ActiveRecord::RecordInvalid) { duplicate.save! }
          error =
            assert_raises(ActiveRecord::RecordNotUnique) do
              version_usage_class.transaction(requires_new: true) {
                version_usage_class.insert_all!(
                  [snapshot.attributes.except("id").merge(
                    "public_id" => "m" * 21,
                    "media_file_id" => other_media.id,
                  )],
                )
              }
            end
          assert_instance_of PG::UniqueViolation, error.cause
          snapshot.alt_text = "Forbidden mutation"
          assert_raises(ActiveRecord::ReadOnlyRecord) { snapshot.save! }
          assert_nil snapshot.reload.alt_text
        end
      end
    end
  end
end
