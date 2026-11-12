# frozen_string_literal: true

require "test_helper"

module Publishing
  class MediaPlacementUniquenessTest < ActiveSupport::TestCase
    self.fixture_table_names = []

    FAMILIES = [
      [Docs::App::Entry, Docs::App::EntryRevision, Docs::App::RevisionMediaUsage, Docs::App::VersionMediaUsage],
      [Docs::Com::Entry, Docs::Com::EntryRevision, Docs::Com::RevisionMediaUsage, Docs::Com::VersionMediaUsage],
      [Docs::Org::Entry, Docs::Org::EntryRevision, Docs::Org::RevisionMediaUsage, Docs::Org::VersionMediaUsage],
      [Help::App::Entry, Help::App::EntryRevision, Help::App::RevisionMediaUsage, Help::App::VersionMediaUsage],
      [Help::Com::Entry, Help::Com::EntryRevision, Help::Com::RevisionMediaUsage, Help::Com::VersionMediaUsage],
      [Help::Org::Entry, Help::Org::EntryRevision, Help::Org::RevisionMediaUsage, Help::Org::VersionMediaUsage],
      [Info::App::Entry, Info::App::EntryRevision, Info::App::RevisionMediaUsage, Info::App::VersionMediaUsage],
      [Info::Com::Entry, Info::Com::EntryRevision, Info::Com::RevisionMediaUsage, Info::Com::VersionMediaUsage],
      [Info::Org::Entry, Info::Org::EntryRevision, Info::Org::RevisionMediaUsage, Info::Org::VersionMediaUsage],
      [News::App::Entry, News::App::EntryRevision, News::App::RevisionMediaUsage, News::App::VersionMediaUsage],
      [News::Com::Entry, News::Com::EntryRevision, News::Com::RevisionMediaUsage, News::Com::VersionMediaUsage],
      [News::Org::Entry, News::Org::EntryRevision, News::Org::RevisionMediaUsage, News::Org::VersionMediaUsage],
    ].freeze

    FAMILIES.each do |entry_class, revision_class, revision_usage_class, version_usage_class|
      test "#{revision_usage_class.name} and immutable snapshots reject duplicate nullable path tuples" do
        entry = entry_class.create!(locale: "en")
        revision = revision_class.create!(
          entry: entry, locale: "en", title: "Media placement", body: {},
          schema_version: 1, content_digest: "d" * 64, sequence: 1,
        )
        media = MediaFile.create!(
          storage_key: "placement-contract", content_type: "image/png", byte_size: 1,
          digest_algorithm: "sha256", digest: "d" * 64,
        )
        [["body", nil], [nil, "block"], ["body", "block"]].each do |field_path, block_path|
          usage = revision_usage_class.create!(
            entry_revision: revision, media_file: media, role: "body", position: 0,
            field_path: field_path, block_path: block_path,
          )
          error =
            assert_raises(ActiveRecord::RecordNotUnique) do
              revision_usage_class.transaction(requires_new: true) do
                revision_usage_class.insert_all!([usage.attributes.except("id").merge("public_id" => "x" * 21)])
              end
            end
          assert_match(/_rev_media_pos\z/, error.cause.result.error_field(PG::Result::PG_DIAG_CONSTRAINT_NAME))
          distinct = revision_usage_class.create!(
            entry_revision: revision, media_file: media, role: "body", position: 1,
            field_path: field_path, block_path: block_path,
          )

          assert_equal 1, distinct.reload.position
          assert_raises(ActiveRecord::RecordNotUnique) do
            revision_usage_class.transaction(requires_new: true) do
              revision_usage_class.where(id: distinct.id).update_all(position: 0)
            end
          end
        end
        version = PromoteRevisionOperation.call(revision: revision)

        assert_equal 6, version_usage_class.where(entry_version_id: version.id).count
        version_usage_class.where(entry_version_id: version.id).find_each do |usage|
          error =
            assert_raises(ActiveRecord::RecordNotUnique) do
              version_usage_class.transaction(requires_new: true) do
                version_usage_class.insert_all!([usage.attributes.except("id").merge("public_id" => "y" * 21)])
              end
            end
          assert_match(/_ver_media_pos\z/, error.cause.result.error_field(PG::Result::PG_DIAG_CONSTRAINT_NAME))
          assert_raises(ActiveRecord::StatementInvalid) do
            version_usage_class.transaction(requires_new: true) do
              version_usage_class.where(id: usage.id).update_all(position: 2)
            end
          end
        end
      end
    end
  end
end
