# frozen_string_literal: true

require "test_helper"

module Publishing
  # These tests must observe real commits from real concurrent connections, so
  # they opt out of the transactional fixture wrapper. Without that, both
  # "threads" would share one connection and one transaction, and the race being
  # tested would never happen.
  class PromotionConcurrencyTest < ActiveSupport::TestCase
    self.use_transactional_tests = false

    setup do
      @category = publishing_category_vocabulary(audience: "app", surface: "docs")
      @tag = publishing_tag_vocabulary(audience: "app", surface: "docs")
      @guide = publishing_term(vocabulary: @category, locale: "ja", slug: "concurrency-guide", name: "Guide")
      @leaf = publishing_term(
        vocabulary: @category, locale: "ja", slug: "concurrency-leaf", name: "Leaf",
        parent: @guide,
      )
      @ruby = publishing_term(vocabulary: @tag, locale: "ja", slug: "concurrency-ruby", name: "Ruby")
      @entry = publishing_draft(audience: "app", surface: "docs", slug: "concurrency-entry", title: "Concurrency")
      create_single_assignment(
        entry_revision: @entry.current_revision, vocabulary: @category, vocabulary_kind: @category.kind,
        taxonomy_term: @leaf, locale: "ja",
      )
      create_multiple_assignment(
        entry_revision: @entry.current_revision, vocabulary: @tag, vocabulary_kind: @tag.kind,
        taxonomy_term: @ruby, locale: "ja", position: 0,
      )
    end

    teardown do
      destroy_publishing_fixtures
    end

    test "two concurrent promotions produce one complete version and both callers see it" do
      revision = @entry.current_revision
      results = concurrently(2) { PromoteRevisionOperation.call(revision: Docs::App::EntryRevision.find(revision.id)) }

      assert_equal 1, Docs::App::EntryVersion.where(entry_revision_id: revision.id).count
      assert_equal 1, results.map(&:id).uniq.size

      version = Docs::App::EntryVersion.find_by!(entry_revision_id: revision.id)

      assert_equal 1, version.single_taxonomy_assignments.count
      assert_equal 1, version.multiple_taxonomy_assignments.count
      assignment = Docs::App::VersionSingleTaxonomyAssignment.find_by!(entry_version_id: version.id)

      assert_equal "concurrency-leaf", assignment.term_slug_snapshot
    end

    private

    def concurrently(count, &block)
      threads =
        Array.new(count) do |index|
          Thread.new do
            PublishingRecord.connection_pool.with_connection { block.call(index) }
          rescue StandardError => e
            e
          end
        end
      threads.map(&:value)
    end

    def destroy_publishing_fixtures
      connection = PublishingRecord.lease_connection
      tables = connection.tables.grep(/\Apublishing_/).map { |table| connection.quote_table_name(table) }
      return if tables.empty?

      # Publishing versions are immutable even to DELETE. One TRUNCATE over the isolated publishing
      # test tables keeps PostgreSQL's foreign-key relation checks enabled and refuses any reference
      # from outside this table set.
      connection.execute("TRUNCATE TABLE #{tables.join(", ")}")
    end
  end
end
