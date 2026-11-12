# frozen_string_literal: true

require "test_helper"

module Publishing
  class IntegerStorageBoundsTest < ActiveSupport::TestCase
    self.fixture_table_names = []

    FAMILIES = [
      [Docs::App::Entry, Docs::App::EntryRevision, Docs::App::EntryVersion, Docs::App::RevisionMediaUsage, Docs::App::VersionMediaUsage],
      [Docs::Com::Entry, Docs::Com::EntryRevision, Docs::Com::EntryVersion, Docs::Com::RevisionMediaUsage, Docs::Com::VersionMediaUsage],
      [Docs::Org::Entry, Docs::Org::EntryRevision, Docs::Org::EntryVersion, Docs::Org::RevisionMediaUsage, Docs::Org::VersionMediaUsage],
      [Help::App::Entry, Help::App::EntryRevision, Help::App::EntryVersion, Help::App::RevisionMediaUsage, Help::App::VersionMediaUsage],
      [Help::Com::Entry, Help::Com::EntryRevision, Help::Com::EntryVersion, Help::Com::RevisionMediaUsage, Help::Com::VersionMediaUsage],
      [Help::Org::Entry, Help::Org::EntryRevision, Help::Org::EntryVersion, Help::Org::RevisionMediaUsage, Help::Org::VersionMediaUsage],
      [Info::App::Entry, Info::App::EntryRevision, Info::App::EntryVersion, Info::App::RevisionMediaUsage, Info::App::VersionMediaUsage],
      [Info::Com::Entry, Info::Com::EntryRevision, Info::Com::EntryVersion, Info::Com::RevisionMediaUsage, Info::Com::VersionMediaUsage],
      [Info::Org::Entry, Info::Org::EntryRevision, Info::Org::EntryVersion, Info::Org::RevisionMediaUsage, Info::Org::VersionMediaUsage],
      [News::App::Entry, News::App::EntryRevision, News::App::EntryVersion, News::App::RevisionMediaUsage, News::App::VersionMediaUsage],
      [News::Com::Entry, News::Com::EntryRevision, News::Com::EntryVersion, News::Com::RevisionMediaUsage, News::Com::VersionMediaUsage],
      [News::Org::Entry, News::Org::EntryRevision, News::Org::EntryVersion, News::Org::RevisionMediaUsage, News::Org::VersionMediaUsage],
    ].freeze

    FAMILIES.each do |entry_class, revision_class, version_class, revision_usage_class, version_usage_class|
      test "#{revision_class.name} and version enforce PostgreSQL schema version bounds before insertion" do
        entry = entry_class.create!(locale: "ja")
        revision = revision_class.create!(
          entry: entry, locale: "ja", title: "Integer storage", body: {},
          schema_version: 1, content_digest: "d" * 64, sequence: 1,
        )

        [revision_class, version_class].each do |model|
          [2_147_483_648, nil, "", -1, 0, 1.5].each do |value|
            candidate = model.new(
              entry: entry, locale: "ja", title: "Integer storage", body: {},
              schema_version: value, content_digest: "d" * 64, sequence: 2,
            )
            candidate.entry_revision = revision if model == version_class

            assert_not candidate.valid?, "#{model.name} must reject schema version #{value.inspect}"
            assert_not_empty candidate.errors.details[:schema_version]
            assert_raises(ActiveRecord::RecordInvalid) { candidate.save! }
            assert_predicate candidate, :new_record?
          end
        end

        [1, 2, 2_147_483_646, 2_147_483_647].each_with_index do |value, index|
          source = revision_class.create!(
            entry: entry, locale: "ja", title: "Integer storage", body: {},
            schema_version: value, content_digest: "d" * 64, sequence: index + 2,
          )
          version = PromoteRevisionOperation.new(revision: source).call

          assert_equal value, source.reload.schema_version
          assert_equal value, version.reload.schema_version
          version.title = "Forbidden mutation"
          assert_raises(ActiveRecord::ReadOnlyRecord) { version.save! }
          assert_equal "Integer storage", version.reload.title
        end
      end

      test "#{revision_usage_class.name} and version enforce PostgreSQL placement position bounds" do
        entry = entry_class.create!(locale: "ja")
        revision = revision_class.create!(
          entry: entry, locale: "ja", title: "Integer storage", body: {},
          schema_version: 1, content_digest: "d" * 64, sequence: 1,
        )
        media = MediaFile.create!(
          storage_key: "integer-storage/media", content_type: "image/png", byte_size: 1,
          digest_algorithm: "sha256", digest: "d" * 64,
        )
        [0, 1, 2, 2_147_483_646, 2_147_483_647].each do |position|
          usage = revision_usage_class.create!(
            entry_revision: revision, media_file: media, role: "body", field_path: "body", position: position,
          )

          assert_equal position, usage.reload.position
        end
        version = PromoteRevisionOperation.new(revision: revision).call

        assert_equal [0, 1, 2, 2_147_483_646, 2_147_483_647], version.media_usages.order(:position).pluck(:position)
        [revision_usage_class, version_usage_class].each do |model|
          [2_147_483_648, nil, "", -1, 1.5].each do |value|
            candidate = model.new(media_file: media, role: "body", field_path: "body", position: value)
            candidate.entry_revision = revision if model == revision_usage_class
            candidate.entry_version = version if model == version_usage_class

            assert_not candidate.valid?, "#{model.name} must reject position #{value.inspect}"
            assert_not_empty candidate.errors.details[:position]
            assert_raises(ActiveRecord::RecordInvalid) { candidate.save! }
            assert_predicate candidate, :new_record?
          end
        end
        snapshot = version_usage_class.where(entry_version_id: version.id).order(:position).first!
        snapshot.alt_text = "Forbidden mutation"
        assert_raises(ActiveRecord::ReadOnlyRecord) { snapshot.save! }
        assert_nil snapshot.reload.alt_text
      end

      test "#{entry_class.name} content and media integers reject SQL overflow independently of validation" do
        entry = entry_class.create!(locale: "ja")
        revision = revision_class.create!(
          entry: entry, locale: "ja", title: "Integer storage", body: {},
          schema_version: 1, content_digest: "d" * 64, sequence: 1,
        )
        media = MediaFile.create!(
          storage_key: "integer-storage/sql-media", content_type: "image/png", byte_size: 1,
          digest_algorithm: "sha256", digest: "d" * 64,
        )
        usage = revision_usage_class.create!(
          entry_revision: revision, media_file: media, role: "body", field_path: "body", position: 0,
        )
        version = PromoteRevisionOperation.new(revision: revision).call
        snapshot = version_usage_class.where(entry_version_id: version.id).first!

        [[revision, "schema_version", 1], [version, "schema_version", 1],
         [usage, "position", 0], [snapshot, "position", 0],].each do |record, attribute, expected|
          connection = record.class.lease_connection
          table = connection.quote_table_name(record.class.table_name)
          column = connection.quote_column_name(attribute)
          columns = (record.attributes.keys - ["id", attribute]).map { |name|
            connection.quote_column_name(name)
          }.join(", ")
          error =
            assert_raises(ActiveRecord::StatementInvalid) do
              connection.transaction(requires_new: true) do
                # INSERT reaches the integer storage boundary without immutable UPDATE callbacks.
                connection.execute(<<~SQL.squish)
                  INSERT INTO #{table} (#{columns}, #{column})
                  SELECT #{columns}, 2147483648 FROM #{table} WHERE id = #{connection.quote(record.id)}
                SQL
              end
            end
          assert_instance_of PG::NumericValueOutOfRange, error.cause
          assert_equal expected, record.reload[attribute]
        end
      end
    end
  end
end
