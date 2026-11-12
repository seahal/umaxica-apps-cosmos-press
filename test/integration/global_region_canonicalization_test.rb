# frozen_string_literal: true

require "test_helper"

class GlobalRegionCanonicalizationTest < ActionDispatch::IntegrationTest
  self.fixture_table_names = []

  setup { host! ENV.fetch("PUBLIC_EDIT_STAFF_URL") }

  test "Edit root does not fabricate a missing Governance region on GET or HEAD" do
    get "/", params: { lx: "en", ct: "dr", marker: "retained" }

    assert_response :success
    assert_nil response.location
    assert_empty cookies.to_hash.keys.grep(/preference|theme|color_scheme/)

    head "/"

    assert_response :success
    assert_empty response.body
    assert_nil response.location
  end

  test "Edit root rejects invalid request regions without consulting Governance preferences" do
    ["", "xx", "j", "jpp", "0", ["jp"], { value: "jp" }].each do |region|
      get "/", params: { ri: region }

      assert_response :bad_request
      assert_nil response.location
      assert_empty cookies.to_hash.keys.grep(/preference|theme|color_scheme/)
    end
    %w(jp us).each do |region|
      get "/", params: { ri: region }

      assert_response :success
      assert_nil response.location
      assert_empty cookies.to_hash.keys.grep(/preference|theme|color_scheme/)
    end
  end
end
