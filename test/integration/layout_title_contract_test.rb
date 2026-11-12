# typed: false
# frozen_string_literal: true

require "test_helper"

class LayoutTitleContractTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  CANONICAL_LAYOUTS = {
    "app/views/layouts/edit/org/application.html.erb" => "ORG",
  }.freeze

  FORBIDDEN_SITE_WORDS = %w(Auth Base Core Edit Palm Tech Visa Warp Jump Global Rails API).freeze

  test "the retained layout hands the brand title contract to meta-tags" do
    CANONICAL_LAYOUTS.each do |path, tld|
      contents = Rails.root.join(path).read

      assert_includes contents, %(site: "\#{ENV.fetch("BRAND_NAME").upcase} (#{tld})"),
                      "missing the brand site title in #{path}"
      assert_includes contents, %(separator: "—"), "missing the EM DASH separator in #{path}"
      assert_includes contents, "reverse: true"
      assert_includes contents, "display_meta_tags"
    end
  end

  test "the site title excludes routing and runtime names" do
    CANONICAL_LAYOUTS.each_key do |path|
      site_title = Rails.root.join(path).read[/site: "([^"]*)"/, 1]

      assert_predicate site_title, :present?
      FORBIDDEN_SITE_WORDS.each do |word|
        assert_no_match(/\b#{word}\b/, site_title)
      end
    end
  end

  test "the retained layout does not define a local title abstraction" do
    CANONICAL_LAYOUTS.each_key do |path|
      contents = Rails.root.join(path).read

      assert_not_includes contents, "title_site"
      assert_not_includes contents, "surface ="
      assert_not_includes contents, "tld ="
    end
  end

  test "only the Edit organization application layout remains" do
    paths = Rails.root.glob("app/views/layouts/**/application.html.erb")

    assert_equal [Rails.root.join(CANONICAL_LAYOUTS.keys.first)], paths.sort
  end
end
