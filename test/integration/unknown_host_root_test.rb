# typed: false
# frozen_string_literal: true

require "test_helper"

# Host Authorization can admit more hostnames than the router serves. A hostname is reachable only
# when a retained surface route claims it. Rails' development welcome page previously answered 200
# for an unclaimed root, making an unavailable surface appear alive.
class UnknownHostRootTest < ActionDispatch::IntegrationTest
  self.fixture_table_names = []

  # An unserved product hostname confirms that an unclaimed host cannot reach the framework welcome
  # page.
  UNSERVED_HOST = "palm-jp.umaxica.com"

  test "a host no surface claims does not answer 200 on root" do
    host! UNSERVED_HOST

    get "/"

    assert_response :not_found
    assert_equal "unknown_host", response.parsed_body["error"]
  end

  test "the framework welcome page is unreachable" do
    recognized = Rails.application.routes.recognize_path("http://#{UNSERVED_HOST}/", method: :get)

    assert_equal "unknown_hosts", recognized[:controller]
    assert_not_equal "rails/welcome", recognized[:controller]
  end

  test "claiming root for unknown hosts does not take it from the surfaces that own one" do
    {
      ENV.fetch("PUBLIC_EDIT_STAFF_URL") => "edit/org/roots",
    }.each do |host, controller|
      recognized = Rails.application.routes.recognize_path("http://#{host}/", method: :get)

      assert_equal controller, recognized[:controller],
                   "#{host} lost its own root to the unknown-host fallback"
    end
  end

  # Host Authorization is not enabled in the test environment, so this reaches routing and lands
  # on the same fallback. In development and production the same request is refused earlier, with
  # 403, because the hostname is not in `config.hosts` at all. Either way it is not a 200.
  test "an arbitrary host reaches no surface" do
    host! "nonsense.invalid"

    get "/"

    assert_response :not_found
    assert_equal "unknown_host", response.parsed_body["error"]
  end
end
