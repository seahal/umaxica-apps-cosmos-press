# frozen_string_literal: true

require "test_helper"

class Edit::Org::RootsControllerTest < ActionDispatch::IntegrationTest
  self.fixture_table_names = []

  setup do
    host! ENV.fetch("PUBLIC_EDIT_STAFF_URL")
  end

  test "anonymous landing provides the Edit sign-in entry with region" do
    get edit_org_root_path(ri: "jp")

    assert_response :success
    assert_select "main#main h1", text: "UMAXICA Edit"
    assert_select "nav[aria-label=?] a[href=?]", I18n.t("ui_presentation.navigation.authentication"),
                  edit_org_dashboard_path(ri: "jp"), text: "Continue"
    assert_select "nav[aria-label=?] a", I18n.t("ui_presentation.navigation.authentication"), count: 1
    assert_select "html[lang='ja']"
    assert_equal "private, no-store", response.headers["Cache-Control"]
  end

  test "landing does not link to unresolved preferences ownership" do
    get edit_org_root_path(ri: "jp")

    assert_response :success
    assert_select "footer nav", count: 0
  end

  test "signed in operator sees the publishing dashboard entry without registration" do
    as_rp_cell("edit-org-ww") do
      install_rp_cell_operator_jwks_client!
      sign_in_edit_rp
      get edit_org_root_path(ri: "jp")

      assert_response :success
      assert_select "nav[aria-label=?] a[href=?]", I18n.t("ui_presentation.navigation.authentication"),
                    edit_org_dashboard_path(ri: "jp"), text: "Publishing"
      assert_select "nav[aria-label=?] a", I18n.t("ui_presentation.navigation.authentication"), count: 1
      assert_equal "private, no-store", response.headers["Cache-Control"]
    end
  end
end
