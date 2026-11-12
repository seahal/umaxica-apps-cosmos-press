# frozen_string_literal: true

require "test_helper"

module Publishing
  class EntrySlugUniquenessPreflightTest < ActiveSupport::TestCase
    self.fixture_table_names = []

    ContentFamilies::CELL_BY_ENTRY.each_value do |cell|
      test "#{cell.fetch(:entry).name} preserves slug namespace and independent canonical and reserved slots" do
        entry = cell.fetch(:entry).create!(locale: "en")
        other_entry = cell.fetch(:entry).create!(locale: "en")
        slug_class = entry.slugs.klass
        canonicalized_at = Time.utc(2030, 1, 1)
        canonical = slug_class.create!(
          entry: entry, locale: "en", slug: "guide", state: "canonical", canonicalized_at: canonicalized_at,
        )
        duplicate_slug = slug_class.new(entry: other_entry, locale: "en", slug: "guide", state: "reserved")

        assert_not duplicate_slug.valid?
        assert duplicate_slug.errors.of_kind?(:slug, :taken)
        assert_raises(ActiveRecord::RecordInvalid) { duplicate_slug.save! }
        error =
          assert_raises(ActiveRecord::RecordNotUnique) do
            PublishingRecord.transaction(requires_new: true) { duplicate_slug.save!(validate: false) }
          end
        assert_match(/_slug_locale\z/, error.cause.result.error_field(PG::Result::PG_DIAG_CONSTRAINT_NAME))

        duplicate_canonical = slug_class.new(
          entry: entry, locale: "en", slug: "another-guide", state: "canonical", canonicalized_at: canonicalized_at,
        )

        assert_not duplicate_canonical.valid?
        assert duplicate_canonical.errors.of_kind?(:entry_id, :taken)
        assert_raises(ActiveRecord::RecordInvalid) { duplicate_canonical.save! }
        error =
          assert_raises(ActiveRecord::RecordNotUnique) do
            PublishingRecord.transaction(requires_new: true) { duplicate_canonical.save!(validate: false) }
          end
        assert_match(/_slug_canonical\z/, error.cause.result.error_field(PG::Result::PG_DIAG_CONSTRAINT_NAME))

        reserved = slug_class.create!(entry: entry, locale: "en", slug: "draft", state: "reserved")
        duplicate_reserved = slug_class.new(entry: entry, locale: "en", slug: "another-draft", state: "reserved")

        assert_not duplicate_reserved.valid?
        assert duplicate_reserved.errors.of_kind?(:entry_id, :taken)
        assert_raises(ActiveRecord::RecordInvalid) { duplicate_reserved.save! }
        error =
          assert_raises(ActiveRecord::RecordNotUnique) do
            PublishingRecord.transaction(requires_new: true) { duplicate_reserved.save!(validate: false) }
          end
        assert_match(/_slug_reserved\z/, error.cause.result.error_field(PG::Result::PG_DIAG_CONSTRAINT_NAME))

        redirects =
          %w(old-guide older-guide).map do |slug|
            slug_class.create!(
              entry: entry, locale: "en", slug: slug, state: "redirect",
              canonicalized_at: canonicalized_at, redirected_at: canonicalized_at + 1,
            )
          end
        translated_entry = cell.fetch(:entry).create!(locale: "ja")
        translated = slug_class.create!(entry: translated_entry, locale: "ja", slug: "guide", state: "reserved")

        assert_predicate canonical, :valid?
        assert_predicate reserved, :valid?
        assert_equal 2, redirects.length
        assert_equal "guide", translated.reload.slug
        redirects.first.assign_attributes(state: "canonical", redirected_at: nil)

        assert_not redirects.first.valid?
        assert redirects.first.errors.of_kind?(:entry_id, :taken)
        canonical.update!(state: "redirect", redirected_at: canonicalized_at + 1)
        redirects.first.save!

        assert_equal "canonical", redirects.first.reload.state
        assert_equal "reserved", reserved.reload.state
        assert_equal "redirect", canonical.reload.state
        assert_equal 4, slug_class.where(entry_id: entry.id).count
        assert_not duplicate_slug.valid?
        assert duplicate_slug.errors.of_kind?(:slug, :taken)
      end
    end
  end
end
