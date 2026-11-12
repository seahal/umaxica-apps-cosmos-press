# typed: false
# frozen_string_literal: true

require "test_helper"

class CycleCloseAuthenticatedRootsTest < ActionDispatch::IntegrationTest
  ROOTS = [
    "PUBLIC_EDIT_STAFF_URL",
  ].freeze

  test "Edit root answers on its host and does not open-redirect" do
    ROOTS.each do |env_key|
      host = ENV.fetch(env_key)
      get "/", params: { ri: "jp" }, headers: { "Host" => host }

      assert_includes [200, 302, 303, 401], response.status, host
      next unless response.redirect?

      location = URI.parse(response.location)

      assert_not_equal "evil.example", location.host, host
      assert_not_includes location.to_s, "://evil.", host
    end
  end

  test "an unrecognized ri on Edit does not redirect off-host" do
    host = ENV.fetch("PUBLIC_EDIT_STAFF_URL")

    get "/", params: { ri: "https://evil.example" }, headers: { "Host" => host }

    assert_includes [200, 302, 303, 400], response.status
    if response.redirect?
      assert_not_includes response.location, "evil.example"
    end
  end
end
