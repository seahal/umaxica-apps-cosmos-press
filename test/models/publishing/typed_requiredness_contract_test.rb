# frozen_string_literal: true

require "test_helper"

module Publishing
  class TypedRequirednessContractTest < ActiveSupport::TestCase
    self.fixture_table_names = []

    FAMILIES = [
      [Docs::App::Entry, Docs::App::EntryRevision, Docs::App::EntryVersion, Docs::App::Publication],
      [Docs::Com::Entry, Docs::Com::EntryRevision, Docs::Com::EntryVersion, Docs::Com::Publication],
      [Docs::Org::Entry, Docs::Org::EntryRevision, Docs::Org::EntryVersion, Docs::Org::Publication],
      [Help::App::Entry, Help::App::EntryRevision, Help::App::EntryVersion, Help::App::Publication],
      [Help::Com::Entry, Help::Com::EntryRevision, Help::Com::EntryVersion, Help::Com::Publication],
      [Help::Org::Entry, Help::Org::EntryRevision, Help::Org::EntryVersion, Help::Org::Publication],
      [Info::App::Entry, Info::App::EntryRevision, Info::App::EntryVersion, Info::App::Publication],
      [Info::Com::Entry, Info::Com::EntryRevision, Info::Com::EntryVersion, Info::Com::Publication],
      [Info::Org::Entry, Info::Org::EntryRevision, Info::Org::EntryVersion, Info::Org::Publication],
      [News::App::Entry, News::App::EntryRevision, News::App::EntryVersion, News::App::Publication],
      [News::Com::Entry, News::Com::EntryRevision, News::Com::EntryVersion, News::Com::Publication],
      [News::Org::Entry, News::Org::EntryRevision, News::Org::EntryVersion, News::Org::Publication],
    ].freeze

    FAMILIES.each do |entry_class, revision_class, version_class, publication_class|
      test "#{revision_class.name} distinguishes missing body from nonobject shape with one unchanged message" do
        I18n.with_locale(:en) do
          entry = entry_class.create!(locale: "ja")
          revision = revision_class.create!(
            entry: entry, locale: "ja", title: "Typed requiredness", body: {},
            schema_version: 1, content_digest: "d" * 64, sequence: 1,
          )

          [revision_class, version_class].each do |model|
            [nil, [], [nil], ["text"], false, true, 0, 1.5, "", "text"].each do |body|
              candidate = model.new(
                entry: entry, locale: "ja", title: "Typed requiredness", body: body,
                schema_version: 1, content_digest: "d" * 64, sequence: 2,
              )
              candidate.entry_revision = revision if model == version_class

              assert_not candidate.valid?, "#{model.name} must reject #{body.inspect}"
              assert_equal ["must be a JSON object"], candidate.errors[:body]
              assert_equal ["Body must be a JSON object"], candidate.errors.full_messages
              expected_kind = body.nil? ? :exclusion : "must be a JSON object"

              assert_equal [expected_kind], candidate.errors.details.fetch(:body).map { |error| error.fetch(:error) }
              assert_raises(ActiveRecord::RecordInvalid) { candidate.save! }
              assert_predicate candidate, :new_record?
            end
          end
        end
      end

      test "#{revision_class.name} empty and nested objects save and promote while version mutation stays forbidden" do
        entry = entry_class.create!(locale: "ja")
        [{}, { "blocks" => [{ "text" => "Body" }] }].each_with_index do |body, index|
          revision = revision_class.create!(
            entry: entry, locale: "ja", title: "Typed requiredness", body: body,
            schema_version: 1, content_digest: "d" * 64, sequence: index + 1,
          )
          version = PromoteRevisionOperation.new(revision: revision).call

          assert_equal body, revision.reload.body
          assert_equal body, version.reload.body
          version.body = { "changed" => true }
          assert_raises(ActiveRecord::ReadOnlyRecord) { version.save! }
          assert_equal body, version.reload.body
        end
      end

      test "#{publication_class.name} required start rejects typed absence without duplicate or changed messages" do
        I18n.with_locale(:en) do
          entry = entry_class.create!(locale: "ja")
          revision = revision_class.create!(
            entry: entry, locale: "ja", title: "Typed requiredness", body: {},
            schema_version: 1, content_digest: "d" * 64, sequence: 1,
          )
          version = PromoteRevisionOperation.new(revision: revision).call

          [nil, "", " ", "not-a-datetime", false, []].each do |value|
            candidate = publication_class.new(entry: entry, entry_version: version, effective_from: value)

            assert_not candidate.valid?, "#{publication_class.name} must reject #{value.inspect}"
            assert_equal ["can't be blank"], candidate.errors[:effective_from]
            assert_equal ["Publication start can't be blank"], candidate.errors.full_messages
            assert_equal [:exclusion], candidate.errors.details.fetch(:effective_from).map { |error|
              error.fetch(:error)
            }
            assert_raises(ActiveRecord::RecordInvalid) { candidate.save! }
            assert_predicate candidate, :new_record?
          end
        end
      end

      test "#{publication_class.name} rejects nonempty values that are not timestamps before persistence" do
        entry = entry_class.create!(locale: "ja")
        revision = revision_class.create!(
          entry: entry, locale: "ja", title: "Typed requiredness", body: {},
          schema_version: 1, content_digest: "d" * 64, sequence: 1,
        )
        version = PromoteRevisionOperation.new(revision: revision).call

        [0, true, [1], [nil]].each do |value|
          candidate = publication_class.new(entry: entry, entry_version: version, effective_from: value)

          assert_not candidate.valid?, "#{publication_class.name} must reject #{value.inspect}"
          assert_equal [:invalid], candidate.errors.details.fetch(:effective_from).map { |error| error.fetch(:error) }
          assert_raises(ActiveRecord::RecordInvalid) { candidate.save! }
          assert_predicate candidate, :new_record?
        end
      end

      test "#{publication_class.name} persists supported timestamp classes and precision" do
        starts_at = Time.utc(2026, 1, 1, 0, 0, 0, 1)
        [starts_at, starts_at.in_time_zone, Date.new(2024, 2, 29), DateTime.new(2026, 1, 1),
         Float::INFINITY, -Float::INFINITY,].each do |value|
          entry = entry_class.create!(locale: "ja")
          revision = revision_class.create!(
            entry: entry, locale: "ja", title: "Typed requiredness", body: {},
            schema_version: 1, content_digest: "d" * 64, sequence: 1,
          )
          version = PromoteRevisionOperation.new(revision: revision).call
          publication = publication_class.new(entry: entry, entry_version: version, effective_from: value)
          expected = publication.effective_from
          publication.save!

          assert_equal expected, publication.reload.effective_from
          next if value.is_a?(Float)

          assert_equal value.year, publication.effective_from.year
          assert_equal value.month, publication.effective_from.month
          assert_equal value.day, publication.effective_from.day
        end
      end

      test "#{publication_class.name} valid datetime and projected updates preserve the stored required start" do
        entry = entry_class.create!(locale: "ja")
        revision = revision_class.create!(
          entry: entry, locale: "ja", title: "Typed requiredness", body: {},
          schema_version: 1, content_digest: "d" * 64, sequence: 1,
        )
        version = PromoteRevisionOperation.new(revision: revision).call
        starts_at = Time.utc(2026, 1, 1)
        publication = publication_class.create!(entry: entry, entry_version: version, effective_from: starts_at.iso8601)

        assert_equal starts_at, publication.reload.effective_from
        publication.update!(effective_from: starts_at + 1)
        projected = publication_class.select(:id, :public_id, :entry_id, :entry_version_id).find(publication.id)
        projected.update!(effective_until: starts_at + 3600)

        assert_equal starts_at + 1, publication.reload.effective_from
        assert_equal starts_at + 3600, publication.effective_until
        assert_nil publication.cancelled_at
      end
    end
  end
end
