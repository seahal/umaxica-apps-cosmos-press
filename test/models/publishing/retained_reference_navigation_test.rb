# frozen_string_literal: true

require "test_helper"

module Publishing
  class RetainedReferenceNavigationTest < ActiveSupport::TestCase
    self.fixture_table_names = []

    test "media identifies every retaining revision and version without deleting historical usage" do
      media = MediaFile.create!(
        storage_key: "retained-navigation", content_type: "image/png", byte_size: 1,
        digest_algorithm: "sha256", digest: "d" * 64,
      )
      expected_revision_usages = {}
      expected_version_usages = {}

      ContentFamilies::CELL_BY_ENTRY.each_value do |cell|
        entry = cell.fetch(:entry).create!(locale: "en")
        revision = cell.fetch(:revision).create!(
          entry: entry, locale: "en", title: "Retained media", body: {},
          schema_version: 1, content_digest: "d" * 64, sequence: 1,
        )
        usage = cell.fetch(:revision_media).create!(
          entry_revision: revision, media_file: media, role: "body", position: 0,
          field_path: "body", block_path: nil,
        )
        version = PromoteRevisionOperation.call(revision: revision)
        expected_revision_usages[cell.fetch(:revision_media)] = [usage.id]
        expected_version_usages[cell.fetch(:version_media)] =
          cell.fetch(:version_media).where(entry_version_id: version.id).pluck(:id)
      end

      media = MediaFile.includes(
        :docs_app_revision_media_usages, :docs_com_revision_media_usages, :docs_org_revision_media_usages,
        :help_app_revision_media_usages, :help_com_revision_media_usages, :help_org_revision_media_usages,
        :info_app_revision_media_usages, :info_com_revision_media_usages, :info_org_revision_media_usages,
        :news_app_revision_media_usages, :news_com_revision_media_usages, :news_org_revision_media_usages,
        :docs_app_version_media_usages, :docs_com_version_media_usages, :docs_org_version_media_usages,
        :help_app_version_media_usages, :help_com_version_media_usages, :help_org_version_media_usages,
        :info_app_version_media_usages, :info_com_version_media_usages, :info_org_version_media_usages,
        :news_app_version_media_usages, :news_com_version_media_usages, :news_org_version_media_usages,
      ).find(media.id)

      [
        media.docs_app_revision_media_usages, media.docs_com_revision_media_usages,
        media.docs_org_revision_media_usages, media.help_app_revision_media_usages,
        media.help_com_revision_media_usages, media.help_org_revision_media_usages,
        media.info_app_revision_media_usages, media.info_com_revision_media_usages,
        media.info_org_revision_media_usages, media.news_app_revision_media_usages,
        media.news_com_revision_media_usages, media.news_org_revision_media_usages,
      ].each do |usages|
        assert_equal expected_revision_usages.fetch(usages.klass), usages.pluck(:id)
      end
      [
        media.docs_app_version_media_usages, media.docs_com_version_media_usages,
        media.docs_org_version_media_usages, media.help_app_version_media_usages,
        media.help_com_version_media_usages, media.help_org_version_media_usages,
        media.info_app_version_media_usages, media.info_com_version_media_usages,
        media.info_org_version_media_usages, media.news_app_version_media_usages,
        media.news_com_version_media_usages, media.news_org_version_media_usages,
      ].each do |usages|
        assert_equal expected_version_usages.fetch(usages.klass), usages.pluck(:id)
      end

      assert_raises(ActiveRecord::DeleteRestrictionError) { media.destroy! }
      error =
        assert_raises(ActiveRecord::StatementInvalid) do
          PublishingRecord.transaction(requires_new: true) { MediaFile.where(id: media.id).delete_all }
        end
      assert_instance_of PG::RestrictViolation, error.cause
      assert_predicate media.reload, :persisted?
      expected_revision_usages.each { |model, ids| assert_equal ids, model.where(media_file_id: media.id).pluck(:id) }
      expected_version_usages.each { |model, ids| assert_equal ids, model.where(media_file_id: media.id).pluck(:id) }
    end

    test "taxonomy identifies its draft and immutable assignments without deleting history" do
      ContentFamilies::CELL_BY_ENTRY.each_value do |cell|
        single_vocabulary = cell.fetch(:vocabulary).create!(
          key: "retained_single", kind: TaxonomyKind::SINGLE_HIERARCHICAL, internal_name: "Single",
        )
        multiple_vocabulary = cell.fetch(:vocabulary).create!(
          key: "retained_multiple", kind: TaxonomyKind::MULTIPLE_ORDERED_FLAT, internal_name: "Multiple",
        )
        single_term = cell.fetch(:taxonomy_term).create!(
          vocabulary: single_vocabulary, vocabulary_kind: single_vocabulary.kind,
          locale: "en", slug: "single", name: "Single", depth: 0, position: 0,
        )
        multiple_term = cell.fetch(:taxonomy_term).create!(
          vocabulary: multiple_vocabulary, vocabulary_kind: multiple_vocabulary.kind,
          locale: "en", slug: "multiple", name: "Multiple", depth: 0, position: 0,
        )
        entry = cell.fetch(:entry).create!(locale: "en")
        revision = cell.fetch(:revision).create!(
          entry: entry, locale: "en", title: "Retained taxonomy", body: {},
          schema_version: 1, content_digest: "d" * 64, sequence: 1,
        )
        single_assignment = cell.fetch(:revision_single).create!(
          entry_revision: revision, vocabulary: single_vocabulary, vocabulary_kind: single_vocabulary.kind,
          taxonomy_term: single_term, locale: "en",
        )
        multiple_assignment = cell.fetch(:revision_multiple).create!(
          entry_revision: revision, vocabulary: multiple_vocabulary, vocabulary_kind: multiple_vocabulary.kind,
          taxonomy_term: multiple_term, locale: "en", position: 0,
        )
        version = PromoteRevisionOperation.call(revision: revision)
        single_snapshot_ids = cell.fetch(:version_single).where(entry_version_id: version.id).pluck(:id)
        multiple_snapshot_ids = cell.fetch(:version_multiple).where(entry_version_id: version.id).pluck(:id)

        [
          [single_vocabulary, [single_assignment.id], [], single_snapshot_ids, []],
          [single_term, [single_assignment.id], [], single_snapshot_ids, []],
          [multiple_vocabulary, [], [multiple_assignment.id], [], multiple_snapshot_ids],
          [multiple_term, [], [multiple_assignment.id], [], multiple_snapshot_ids],
        ].each do |owner, single_ids, multiple_ids, frozen_single_ids, frozen_multiple_ids|
          owner = owner.class.includes(
            :revision_single_taxonomy_assignments, :revision_multiple_taxonomy_assignments,
            :version_single_taxonomy_assignments, :version_multiple_taxonomy_assignments,
          ).find(owner.id)

          assert_equal single_ids, owner.revision_single_taxonomy_assignments.pluck(:id)
          assert_equal multiple_ids, owner.revision_multiple_taxonomy_assignments.pluck(:id)
          assert_equal frozen_single_ids, owner.version_single_taxonomy_assignments.pluck(:id)
          assert_equal frozen_multiple_ids, owner.version_multiple_taxonomy_assignments.pluck(:id)
          assert_raises(ActiveRecord::DeleteRestrictionError) { owner.destroy! }
          assert_predicate owner.reload, :persisted?
        end

        assert_raises(ActiveRecord::StatementInvalid) do
          PublishingRecord.transaction(requires_new: true) do
            cell.fetch(:vocabulary).where(id: single_vocabulary.id).delete_all
          end
        end
        assert_raises(ActiveRecord::StatementInvalid) do
          PublishingRecord.transaction(requires_new: true) do
            cell.fetch(:taxonomy_term).where(id: single_term.id).delete_all
          end
        end
        error =
          assert_raises(ActiveRecord::StatementInvalid) do
            PublishingRecord.transaction(requires_new: true) do
              cell.fetch(:revision_single).where(id: single_assignment.id)
                .update_all(taxonomy_term_id: 9_223_372_036_854_775_807)
            end
          end
        assert_instance_of PG::RestrictViolation, error.cause
        assert_equal single_term.id, single_assignment.reload.taxonomy_term_id
        assert_equal single_snapshot_ids, cell.fetch(:version_single).where(entry_version_id: version.id).pluck(:id)
        assert_equal multiple_snapshot_ids, cell.fetch(:version_multiple).where(entry_version_id: version.id).pluck(:id)

        unused_term = cell.fetch(:taxonomy_term).create!(
          vocabulary: single_vocabulary, vocabulary_kind: single_vocabulary.kind,
          locale: "en", slug: "unused", name: "Unused", depth: 0, position: 1,
        )
        assert_raises(ActiveRecord::StatementInvalid) do
          PublishingRecord.transaction(requires_new: true) { unused_term.destroy! }
        end
        assert_predicate unused_term.reload, :persisted?
      end
    end

    test "revisions identify current owners restorations and promoted versions without losing history" do
      ContentFamilies::CELL_BY_ENTRY.each_value do |cell|
        entry = cell.fetch(:entry).create!(locale: "en")
        original = cell.fetch(:revision).create!(
          entry: entry, locale: "en", title: "Original", body: {},
          schema_version: 1, content_digest: "d" * 64, sequence: 1,
        )
        entry.update!(current_revision: original)
        version = PromoteRevisionOperation.call(revision: original)
        restored = cell.fetch(:revision).create!(
          entry: entry, locale: "en", title: "Restored", body: {},
          schema_version: 1, content_digest: "e" * 64, sequence: 2,
          restored_from_revision: original,
        )
        original = cell.fetch(:revision).includes(
          :current_entries, :restored_revisions, :promoted_versions,
          :media_usages, :single_taxonomy_assignments, :multiple_taxonomy_assignments,
        ).find(original.id)
        restored = cell.fetch(:revision).includes(:current_entries, :restored_revisions, :promoted_versions)
          .find(restored.id)

        assert_equal [entry.id], original.current_entries.pluck(:id)
        assert_equal [restored.id], original.restored_revisions.pluck(:id)
        assert_equal [version.id], original.promoted_versions.pluck(:id)
        assert_empty restored.current_entries
        assert_empty restored.restored_revisions
        assert_empty restored.promoted_versions
        assert_raises(ActiveRecord::DeleteRestrictionError) { original.destroy! }
        assert_raises(ActiveRecord::StatementInvalid) do
          PublishingRecord.transaction(requires_new: true) { cell.fetch(:revision).where(id: original.id).delete_all }
        end
        assert_equal original.id, entry.reload.current_revision_id
        assert_equal original.id, restored.reload.restored_from_revision_id
        assert_equal original.id, version.reload.entry_revision_id
      end
    end

    test "versions identify restored drafts while retaining the immutable deletion refusal" do
      ContentFamilies::CELL_BY_ENTRY.each_value do |cell|
        entry = cell.fetch(:entry).create!(locale: "en")
        original = cell.fetch(:revision).create!(
          entry: entry, locale: "en", title: "Original version", body: {},
          schema_version: 1, content_digest: "d" * 64, sequence: 1,
        )
        version = PromoteRevisionOperation.call(revision: original)
        restored = cell.fetch(:revision).create!(
          entry: entry, locale: "en", title: "Restored version", body: {},
          schema_version: 1, content_digest: "e" * 64, sequence: 2,
          restored_from_version: version,
        )
        version = cell.fetch(:version).includes(:restored_revisions).find(version.id)

        assert_equal [restored.id], version.restored_revisions.pluck(:id)
        assert_raises(ActiveRecord::ReadOnlyRecord) { version.destroy! }
        assert_raises(ActiveRecord::StatementInvalid) do
          PublishingRecord.transaction(requires_new: true) { cell.fetch(:version).where(id: version.id).delete_all }
        end
        assert_equal version.id, restored.reload.restored_from_version_id
        assert_equal [restored.id], cell.fetch(:version).includes(:restored_revisions)
          .find(version.id).restored_revisions.pluck(:id)
      end
    end
  end
end
