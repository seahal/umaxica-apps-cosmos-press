# typed: false
# frozen_string_literal: true

require "test_helper"

# Browser pages on Edit's Sign-in path refuse outdated browsers with 406; its server-to-server
# Back-Channel Logout receiver is not gated on the browser version.
class SignInPathBrowserAllowlistTest < ActionDispatch::IntegrationTest
  self.fixture_table_names = []

  # Safari 16 is below the :modern floor (17.2).
  OUTDATED_BROWSER = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 " \
                     "(KHTML, like Gecko) Version/16.0 Safari/605.1.15"
  BOOT_HOSTS = Rails.configuration.x.boot_config.fetch(:hosts)

  test "Edit sign-in entry answers an outdated browser with 406" do
    host! BOOT_HOSTS.edit_staff.host
    https!

    get "/sign", params: { ri: "jp" }, headers: { "User-Agent" => OUTDATED_BROWSER }

    assert_equal 406, response.status
  end

  test "the Edit Back-Channel Logout receiver is not gated on the browser version" do
    host! BOOT_HOSTS.edit_staff.host
    https!

    post "/oidc/closures", params: { logout_token: "x" }, headers: { "User-Agent" => OUTDATED_BROWSER }

    assert_equal 400, response.status
  end
end
