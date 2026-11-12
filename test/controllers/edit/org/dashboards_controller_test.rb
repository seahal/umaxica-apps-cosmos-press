# frozen_string_literal: true

require "test_helper"

class Edit::Org::DashboardsControllerTest < ActionDispatch::IntegrationTest
  self.fixture_table_names = []

  setup do
    @host = ENV.fetch("PUBLIC_EDIT_STAFF_URL")
    host! @host
  end

  test "shows a link to each publishing cell for a signed-in operator" do
    as_rp_cell("edit-org-ww") do
      install_rp_cell_operator_jwks_client!
      sign_in_edit_rp
      get edit_org_dashboard_path(ri: "jp")

      assert_response :success
      assert_select "a[href=?]", edit_org_publishing_docs_app_entries_path(ri: "jp")
      assert_select "a[href=?]", edit_org_publishing_help_org_entries_path(ri: "jp")
      assert_select "a[href=?]", edit_org_publishing_info_com_entries_path(ri: "jp")
      assert_select "a[href=?]", edit_org_publishing_news_app_entries_path(ri: "jp")
    end
  end

  # The protected page is not a second Sign entry: it points the browser at the passive GET /sign and
  # starts no OIDC flow itself (specs/sign-fqdn-integrated-plan/plan.md section 5).
  test "an unauthenticated HTML request is sent to the passive sign entry without starting a flow" do
    get edit_org_dashboard_path(ri: "jp")

    assert_response :redirect
    location = URI.parse(response.location)

    assert_equal @host, location.host
    assert_equal edit_org_sign_show_path, location.path
    # D-151: path only, no query.
    assert_equal edit_org_dashboard_path, Rack::Utils.parse_nested_query(location.query).fetch("target_link_uri")
    assert_nil session["oidc_pending_flows"]
  end

  test "an unauthenticated JSON request keeps the 401 without a redirect" do
    get edit_org_dashboard_path(ri: "jp", format: :json)

    assert_response :unauthorized
    assert_nil response.location
    assert_nil session["oidc_pending_flows"]
  end

  private
end
