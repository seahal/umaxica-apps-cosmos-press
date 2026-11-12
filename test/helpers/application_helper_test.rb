# typed: false
# frozen_string_literal: true

require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  setup do
    view.extend(ApplicationHelper)
  end

  test "page_title sets content and returns the current value" do
    view.content_for(:page_title, nil)

    assert_equal "Title", view.page_title("Title")
    assert_equal "Title", view.content_for(:page_title)
  end

  test "page_title returns blank when no title was set" do
    assert_predicate view.page_title, :blank?
  end
end
