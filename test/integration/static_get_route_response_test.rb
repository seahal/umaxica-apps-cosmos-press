# typed: false
# frozen_string_literal: true

require "test_helper"

# Published static GET routes must reach an HTTP boundary without an unhandled exception on the host
# they are published for. Each route is requested on the first host its own host constraint lists,
# so a 404 means the route no longer answers on its host rather than that it was sent elsewhere.
class StaticGetRouteResponseTest < ActionDispatch::IntegrationTest
  SKIP = %r{/(callback|oauth|social|historical_location)\b}

  # Anonymous answers that are the route's own contract rather than a miss or a crash.
  EXPECTED_ANONYMOUS_STATUS = {
    # The sign-out completion is one-shot and answers 404 without a pending sign-out notice; see
    # OidcRpLogoutLauncher#complete_oidc_rp_logout!.
    [ENV.fetch("PUBLIC_EDIT_STAFF_URL"), "/sign/out"] => 404,
    [ENV.fetch("PUBLIC_EDIT_STAFF_URL"), "/sign/out/completion"] => 404,
  }.freeze

  test "static GET routes answer on their own host without a server error or a routing miss" do
    routes = static_get_routes_by_host

    assert_predicate routes, :any?, "no host-constrained static GET route was discovered"

    failures = []
    routes.each do |host, paths|
      host! host
      paths.each do |path|
        get(path)
        next if EXPECTED_ANONYMOUS_STATUS[[host, path]] == response.status

        failures << "GET #{host}#{path}: #{response.status}" if response.server_error? || response.not_found?
      rescue StandardError => e
        failures << "GET #{host}#{path}: #{e.class}: #{e.message}"
      end
    end

    assert_empty failures, failures.join("\n")
  end

  private

  def static_get_routes_by_host
    Rails.application.routes.routes
      .select { |route| route.verb == "GET" && route.constraints[:host].is_a?(Array) }
      .map { |route| [route.constraints[:host].first, route.path.spec.to_s.sub(/\(\.:format\)\z/, "")] }
      .reject { |_host, path| path.include?(":") || path.include?("*") || path.include?("(") || path.match?(SKIP) }
      .uniq
      .group_by(&:first)
      .transform_values { |pairs| pairs.map(&:last) }
  end
end
