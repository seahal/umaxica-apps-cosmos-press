# frozen_string_literal: true

require "test_helper"

class JumpDirectedHandoffsTest < ActionDispatch::IntegrationTest
  self.fixture_table_names = []

  test "Edit sign POST keeps its existing same-site authorization admission pending separate RP review" do
    host! "edit.umaxica.org"
    https!
    post "/sign", params: { ri: "jp" }

    assert_response :see_other
    target = URI.parse(response.location)

    assert_equal "https", target.scheme
    assert_equal "visa.umaxica.org", target.host # WU-02: the OP is on Visa
    assert_equal "/oauth/authorize", target.path
    assert_equal "edit-org-ww", Rack::Utils.parse_nested_query(target.query).fetch("client_id")
  end
end
