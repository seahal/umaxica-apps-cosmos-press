# frozen_string_literal: true

require "test_helper"

class PublishingManagementEntrySerializerTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  Revision = Data.define(:title, :sequence, :public_id, :summary, :body)
  Slug = Data.define(:slug)
  Entry =
    Data.define(
      :current_revision,
      :public_id,
      :locale,
      :canonical_slug,
      :archived,
      :active_publication,
      :updated_at,
      :archive_reason,
      :revisions,
      :versions,
      :lock_version,
      :publications,
    ) do
      def archived? = archived
    end
  Page = Data.define(:entries, :number, :per_page, :total, :has_more)

  test "summary detail and page expose the allowlisted staff entry shape" do
    revision = Revision.new("Guide", 3, "revision-public-id", "Summary", { "text" => "Body" })
    entry = Entry.new(
      revision,
      "entry-public-id",
      "ja",
      Slug.new("guide"),
      false,
      nil,
      Time.zone.parse("2026-11-12 12:00:00"),
      nil,
      [revision],
      [Object.new],
      4,
      Publishing::Info::App::Publication.none,
    )

    summary = PublishingManagementEntrySerializer.summary(entry)
    detail = PublishingManagementEntrySerializer.detail(entry)
    page = PublishingManagementEntrySerializer.page(Page.new([entry], 1, 20, 1, false))

    assert_equal "entry-public-id", summary.fetch("public_id")
    assert_equal "Guide", summary.fetch("title")
    assert_equal "active", summary.fetch("archive_state")
    assert_equal "draft", summary.fetch("publication_state")
    assert_equal 3, summary.fetch("revision_sequence")
    assert_equal "Body", detail.fetch("body").fetch("text")
    assert_equal "revision-public-id", detail.fetch("current_revision_public_id")
    assert_equal 1, detail.fetch("revision_count")
    assert_equal 1, detail.fetch("version_count")
    assert_equal 4, detail.fetch("lock_version")
    assert_empty detail.fetch("scheduled_publications")
    assert_equal [summary], page.fetch("entries")
    assert_equal 1, page.fetch("number")
    assert_equal 20, page.fetch("per_page")
    assert_equal 1, page.fetch("total")
    assert_not page.fetch("has_more")
  end
end
