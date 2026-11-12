# frozen_string_literal: true

require "test_helper"

# R5-WU17 role ingress boundary: a role process answers 404 for a controller it does not own,
# before any controller callback runs, and serves its own and shared controllers normally.
class RuntimeRoleRouteGuardTest < ActionDispatch::IntegrationTest
  self.fixture_table_names = []

  test "the Edit RP process refuses another surface controller before any callback" do
    host = Rails.configuration.x.boot_config.fetch(:hosts).info_service.host
    with_runtime_role("rp-edit-org-ww") do
      host! host
      get "/health"
    end

    assert_response :not_found
    assert_empty response.body
    assert_nil response.headers["Set-Cookie"]
  end

  test "an RP role process serves the shared unknown-host response" do
    with_runtime_role("rp-edit-org-ww") do
      host! "base.app.localhost"
      get "/"
    end

    assert_response :not_found
    assert_equal({ "error" => "unknown_host" }, response.parsed_body)
  end

  test "the Edit RP role reaches its own page" do
    with_runtime_role("rp-edit-org-ww") do
      host! Rails.configuration.x.boot_config.fetch(:hosts).edit_staff.host
      get "/"
    end

    assert_not_equal 404, response.status
  end

  # R5-WU19: a closed cell keeps only its protocol receiver and health reachable.
  test "a closed Edit RP refuses browser entry and still reaches its back-channel logout receiver" do
    host = Rails.configuration.x.boot_config.fetch(:hosts).edit_staff.host
    with_runtime_role("rp-edit-org-ww", admission: "closed") do
      host! host
      get "/sign", params: { ri: "jp" }

      assert_response :not_found

      post "/oidc/closures", params: { logout_token: "not-a-jwt" }, headers: { "User-Agent" => "" }

      assert_response :bad_request
      assert_equal "no-store", response.headers["Cache-Control"]
    end
  end

  private

  # The role is process-wide configuration; each parallel worker is its own process.
  def with_runtime_role(name, admission: "open")
    previous = ENV.to_h.slice("UMAXICA_RUNTIME_ROLE", "UMAXICA_RP_BROWSER_ADMISSION")
    ENV["UMAXICA_RUNTIME_ROLE"] = name
    ENV["UMAXICA_RP_BROWSER_ADMISSION"] = admission
    yield
  ensure
    %w(UMAXICA_RUNTIME_ROLE UMAXICA_RP_BROWSER_ADMISSION).each do |key|
      previous.key?(key) ? ENV[key] = previous[key] : ENV.delete(key)
    end
  end
end
