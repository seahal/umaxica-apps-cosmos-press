# frozen_string_literal: true

require "test_helper"

class LayoutRenderedTitleSmokeTest < ActionDispatch::IntegrationTest
  BRAND = ENV.fetch("BRAND_NAME").upcase

  test "retained layouts render the expected brand site title" do
    cases = [
      [ENV.fetch("PUBLIC_EDIT_STAFF_URL"), :edit_org_root_path, "ORG"],
    ]

    cases.each do |host, path_helper, edition|
      host! host
      get public_send(path_helper, ri: "jp")

      assert_response :success
      assert_select "title", /#{Regexp.escape("#{BRAND} (#{edition})")}\z/
    end
  end
end
