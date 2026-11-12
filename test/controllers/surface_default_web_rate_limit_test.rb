# typed: false
# frozen_string_literal: true

require "test_helper"

class SurfaceDefaultWebRateLimitTest < ActionDispatch::IntegrationTest
  rate_limit_counters!

  self.fixture_table_names = []

  DEFAULT_WEB_QUOTA = 300

  SURFACES = {
    "edit org" => ["PUBLIC_EDIT_STAFF_URL", :edit_org_dashboard_path],
  }.freeze

  setup { Rails.configuration.x.rate_limit.fetch(:store).clear }
  teardown { Rails.configuration.x.rate_limit.fetch(:store).clear }

  SURFACES.each do |surface, (host_env, helper)|
    test "#{surface} answers requests inside its default web quota and returns a retry hint after it" do
      host! ENV.fetch(host_env)

      DEFAULT_WEB_QUOTA.times { get public_send(helper, ri: "jp") }

      assert_not_equal 429, response.status,
                       "#{surface} refused a request inside its quota of #{DEFAULT_WEB_QUOTA}"

      get public_send(helper, ri: "jp")

      assert_response :too_many_requests
      assert_equal "60", response.headers["Retry-After"]
    end
  end
end
