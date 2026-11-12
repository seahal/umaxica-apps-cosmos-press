# typed: false
# frozen_string_literal: true

require "test_helper"

class LayoutMetaTagsTest < ActiveSupport::TestCase
  LAYOUT_PATH = "app/views/layouts/edit/org/application.html.erb"

  test "Edit layout includes a charset and viewport" do
    content = Rails.root.join(LAYOUT_PATH).read

    assert_includes content, '<meta charset="utf-8">'
    assert_includes content, '<meta name="viewport" content="width=device-width,initial-scale=1">'
  end

  test "Edit layout delegates the page title to meta-tags" do
    content = Rails.root.join(LAYOUT_PATH).read

    assert_includes content, "display_meta_tags"
    assert_includes content, 'separator: "—"'
    assert_includes content, "reverse: true"
  end

  test "Edit document uses the application locale without unavailable preference state" do
    content = Rails.root.join(LAYOUT_PATH).read

    assert_includes content, 'lang="<%= I18n.locale %>"'
    assert_not_includes content, "theme_cookie_value"
    assert_not_includes content, "theme_html_class"
  end
end
