# typed: false
# frozen_string_literal: true

require "test_helper"

class OwnedSurfaceStylesheetTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  test "Edit loads its own stylesheet without a JavaScript entrypoint" do
    path = Rails.root.join("app/views/layouts/edit/org/application.html.erb")
    contents = path.read

    assert_includes contents, 'vite_stylesheet_tag "~/styles/surfaces/edit_org.css"'
    assert_not_includes contents, "javascript_importmap_tags"
    assert_not_includes contents, "vite_typescript_tag"
  end
end
