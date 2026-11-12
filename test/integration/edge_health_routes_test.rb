# typed: false
# frozen_string_literal: true

require "test_helper"
# require "helpers/global_test_support"

class EdgeHealthRoutesTest < ActionDispatch::IntegrationTest
  RETAINED_SURFACE_HOSTS =
    begin
      hosts = Rails.configuration.x.boot_config.fetch(:hosts)
      %i(
        edit_staff
        info_service info_corporate info_staff
        news_service news_corporate news_staff
        help_service help_corporate help_staff
        docs_service docs_corporate docs_staff
      ).map { |surface| hosts.public_send(surface).host }.freeze
    end

  test "legacy edge health routes are not routed" do
    RETAINED_SURFACE_HOSTS.each do |host|
      assert_raises(ActionController::RoutingError) do
        Rails.application.routes.recognize_path("http://#{host}/edge/v0/health", method: :get)
      end
    end
  end

  test "legacy sign web health routes are not routed" do
    RETAINED_SURFACE_HOSTS.each do |host|
      assert_raises(ActionController::RoutingError) do
        Rails.application.routes.recognize_path("http://#{host}/web/v0/health", method: :get)
      end
    end
  end

  # The probe contract was unified on /health/liveness and /health/readiness.
  # The former /health/live and /health/ready paths were removed outright (no
  # compatibility shim); guard against their reintroduction on any retained surface.
  test "removed legacy probe paths are not routed" do
    RETAINED_SURFACE_HOSTS.each do |host|
      %w(/health/live /health/ready).each do |path|
        assert_raises(ActionController::RoutingError, "#{host}#{path} should not be routed") do
          Rails.application.routes.recognize_path("http://#{host}#{path}", method: :get)
        end
      end
    end
  end

  # The machine endpoints carry the literal ".json" as a path segment (`format: false`). The
  # bare paths and any other API version must not resolve.
  test "machine health and revision endpoints exist only at the exact /api/v0/*.json paths" do
    host = Rails.configuration.x.boot_config.fetch(:hosts).edit_staff.host

    %w(
      /api/v0/health /api/v0/revision /api/v1/health.json /api/v1/revision.json
      /api/v0/liveness.json /health.json/liveness
    ).each do |path|
      assert_raises(ActionController::RoutingError, "#{host}#{path} should not be routed") do
        Rails.application.routes.recognize_path("http://#{host}#{path}", method: :get)
      end
    end
  end
end
