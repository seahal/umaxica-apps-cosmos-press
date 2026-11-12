# frozen_string_literal: true

require "test_helper"

module Publishing
  class GeneratedTaxonomyPositionContractTest < ActiveSupport::TestCase
    self.fixture_table_names = []

    ContentFamilies::CELL_BY_ENTRY.each do |entry_class, cell|
      test "#{entry_class.name} model rejects every supplied generated position and accepts omission" do
        vocabulary = cell.fetch(:vocabulary).create!(
          key: "generated_input", kind: TaxonomyKind::MULTIPLE_ORDERED_FLAT, internal_name: "Generated input",
        )
        term = cell.fetch(:taxonomy_term).create!(
          vocabulary: vocabulary, vocabulary_kind: vocabulary.kind, locale: "en",
          slug: "input", name: "Input", depth: 0, position: 0,
        )
        entry = entry_class.create!(locale: "en")
        revision = cell.fetch(:revision).create!(
          entry: entry, locale: "en", title: "Generated input", body: {}, schema_version: 1,
          content_digest: "e" * 64, sequence: 1,
        )
        cell.fetch(:revision_multiple).create!(
          entry_revision: revision, vocabulary: vocabulary, vocabulary_kind: vocabulary.kind,
          taxonomy_term: term, locale: "en", position: 0,
        )
        version = cell.fetch(:version).create!(
          entry: entry, entry_revision: revision, locale: "en", title: "Generated input", body: {},
          schema_version: 1, content_digest: "e" * 64, sequence: 1,
        )
        [999, 0, nil, "", "invalid", [], {}, false, 0.5].each do |supplied|
          snapshot = cell.fetch(:version_multiple).new(
            entry_version: version, vocabulary: vocabulary, vocabulary_kind: vocabulary.kind,
            taxonomy_term: term, locale: "en", position: 0, position_snapshot: supplied,
          )
          snapshot.apply_snapshot(vocabulary: vocabulary, term: term)
          error = assert_raises(ActiveRecord::RecordInvalid) { snapshot.save! }
          assert_equal [{ error: :invalid }], error.record.errors.details.fetch(:position_snapshot)
          assert_equal 1, error.record.errors.full_messages.length
          assert_not snapshot.persisted?
          assert_equal 0, cell.fetch(:version_multiple).where(entry_version_id: version.id).count
        end

        snapshot = cell.fetch(:version_multiple).new(
          entry_version: version, vocabulary: vocabulary, vocabulary_kind: vocabulary.kind,
          taxonomy_term: term, locale: "en", position: 0,
        )
        snapshot.apply_snapshot(vocabulary: vocabulary, term: term)
        snapshot.save!

        assert_equal 0, snapshot.reload.position_snapshot
        connection = PublishingRecord.lease_connection
        connection.execute("SET CONSTRAINTS ALL IMMEDIATE")
        assert_raises(ActiveRecord::ReadOnlyRecord) { snapshot.update!(position_snapshot: 0) }
        assert_equal 0, snapshot.reload.position_snapshot
        connection.execute("SET CONSTRAINTS ALL DEFERRED")
      end

      test "#{entry_class.name} snapshot position is database derived and refuses supplied values" do
        vocabulary = cell.fetch(:vocabulary).create!(
          key: "generated_position", kind: TaxonomyKind::MULTIPLE_ORDERED_FLAT, internal_name: "Generated position",
        )
        first_term = cell.fetch(:taxonomy_term).create!(
          vocabulary: vocabulary, vocabulary_kind: vocabulary.kind, locale: "en",
          slug: "first", name: "First", depth: 0, position: 0,
        )
        second_term = cell.fetch(:taxonomy_term).create!(
          vocabulary: vocabulary, vocabulary_kind: vocabulary.kind, locale: "en",
          slug: "second", name: "Second", depth: 0, position: 1,
        )
        entry = entry_class.create!(locale: "en")
        revision = cell.fetch(:revision).create!(
          entry: entry, locale: "en", title: "Generated position", body: {}, schema_version: 1,
          content_digest: "d" * 64, sequence: 1,
        )
        [[first_term, 0], [second_term, 2_147_483_647]].each do |term, position|
          cell.fetch(:revision_multiple).create!(
            entry_revision: revision, vocabulary: vocabulary, vocabulary_kind: vocabulary.kind,
            taxonomy_term: term, locale: "en", position: position,
          )
        end
        version = cell.fetch(:version).create!(
          entry: entry, entry_revision: revision, locale: "en", title: "Generated position", body: {},
          schema_version: 1, content_digest: "d" * 64, sequence: 1,
        )
        connection = PublishingRecord.lease_connection
        table = connection.quote_table_name(cell.fetch(:version_multiple).table_name)
        error =
          assert_raises(ActiveRecord::StatementInvalid) do
            PublishingRecord.transaction(requires_new: true) do
              connection.execute(<<~SQL.squish)
                INSERT INTO #{table}
                  (entry_version_id, vocabulary_id, vocabulary_kind, taxonomy_term_id,
                   locale, position, position_snapshot, created_at, updated_at)
                VALUES (#{connection.quote(version.id)},
                        #{connection.quote(vocabulary.id)}, #{connection.quote(vocabulary.kind)},
                        #{connection.quote(first_term.id)}, 'en', 0, 999, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
              SQL
            end
          end
        assert_instance_of PG::GeneratedAlways, error.cause
        assert_equal 0, cell.fetch(:version_multiple).where(entry_version_id: version.id).count

        [[first_term, 0], [second_term, 2_147_483_647]].each do |term, position|
          connection.execute(<<~SQL.squish)
            INSERT INTO #{table}
              (entry_version_id, vocabulary_id, vocabulary_kind, taxonomy_term_id,
               locale, position, created_at, updated_at)
            VALUES (#{connection.quote(version.id)},
                    #{connection.quote(vocabulary.id)}, #{connection.quote(vocabulary.kind)},
                    #{connection.quote(term.id)}, 'en', #{connection.quote(position)},
                    CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
          SQL
        end
        connection.execute("SET CONSTRAINTS ALL IMMEDIATE")
        snapshots = cell.fetch(:version_multiple).where(entry_version_id: version.id).order(:position).to_a

        assert_equal [0, 2_147_483_647], snapshots.map(&:position_snapshot)
        assert_equal first_term.public_id, snapshots.first.as_public_json.fetch("public_id")
        assert_raises(ActiveRecord::ReadOnlyRecord) { snapshots.first.update!(position: 9) }
        error =
          assert_raises(ActiveRecord::StatementInvalid) do
            PublishingRecord.transaction(requires_new: true) do
              connection.execute("UPDATE #{table} SET position = 9 WHERE id = #{connection.quote(snapshots.first.id)}")
            end
          end
        assert_instance_of PG::RaiseException, error.cause
        assert_equal 0, snapshots.first.reload.position_snapshot
        connection.execute("SET CONSTRAINTS ALL DEFERRED")
      end
    end
  end
end
