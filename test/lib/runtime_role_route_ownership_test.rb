# frozen_string_literal: true

require "test_helper"

# A process may serve only the application surfaces assigned to its runtime role.
class RuntimeRoleRouteOwnershipTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  test "every routed application controller has an owner" do
    unowned =
      routed_controllers.filter_map do |path|
        RuntimeRole.route_owner(path)
        nil
      rescue RuntimeRole::UnownedRoute
        path
      end

    assert_empty unowned
  end

  test "content and Edit controllers belong to their active owners" do
    %w(docs help info news).each do |surface|
      assert_equal "domain-publishing", RuntimeRole.route_owner("#{surface}/org/roots")
    end

    assert_equal "rp-edit-org-ww", RuntimeRole.route_owner("edit/org/roots")
    assert_equal "domain-publishing", RuntimeRole.route_owner("edit/org/api/v0/publishing/entries")
    assert_equal RuntimeRole::ANY_ROLE, RuntimeRole.route_owner("unknown_hosts")
  end

  test "retired controller families have no runtime owner" do
    %w(auth base core palm tech visa warp).each do |family|
      assert_raises(RuntimeRole::UnownedRoute) { RuntimeRole.route_owner("#{family}/org/roots") }
    end
  end

  test "the Edit RP process serves its own open surface and closed protocol routes" do
    with_browser_admission("open") do
      assert RuntimeRole.serves?("edit/org/roots", "rp-edit-org-ww")
      assert RuntimeRole.serves?("edit/org/oidc/closures", "rp-edit-org-ww")
      assert_not RuntimeRole.serves?("edit/org/roots", "domain-publishing")
    end

    with_browser_admission("closed") do
      assert RuntimeRole.serves?("edit/org/oidc/closures", "rp-edit-org-ww")
      assert RuntimeRole.serves?("edit/org/healths", "rp-edit-org-ww")
      assert_not RuntimeRole.serves?("edit/org/roots", "rp-edit-org-ww")
    end
  end

  test "the shared process serves assigned routes but refuses retired families" do
    assert RuntimeRole.serves?("docs/app/roots", RuntimeRole::SHARED)
    assert RuntimeRole.serves?("edit/org/roots", RuntimeRole::SHARED)
    assert_not RuntimeRole.serves?("base/app/roots", RuntimeRole::SHARED)
    assert_not RuntimeRole.serves?("unknown/app/roots", RuntimeRole::SHARED)
  end

  test "an Edit RP cell resolves only its own cell and key namespaces" do
    assert_equal "rp_edit_org", RuntimeRole.cell_connection("rp-edit-org-ww")
    assert_equal [
      "OIDC_CLIENT_EDIT_ORG_WW_PRIVATE_KEY",
      "JWT_EDIT_ORG_PRIVATE_KEY",
    ], RuntimeRole.rp_private_env_names("rp-edit-org-ww")
  end

  test "an RP cell refuses to guess its browser admission" do
    with_browser_admission("ajar") do
      assert_raises(RuntimeRole::UnknownRole) do
        RuntimeRole.serves?("edit/org/roots", "rp-edit-org-ww")
      end
    end
  end

  private

  def routed_controllers
    Rails.application.routes.routes.filter_map { |route| route.defaults[:controller] }.uniq
  end

  def with_browser_admission(value)
    previous = ENV["UMAXICA_RP_BROWSER_ADMISSION"]
    ENV["UMAXICA_RP_BROWSER_ADMISSION"] = value
    yield
  ensure
    previous.nil? ? ENV.delete("UMAXICA_RP_BROWSER_ADMISSION") : ENV["UMAXICA_RP_BROWSER_ADMISSION"] = previous
  end
end
