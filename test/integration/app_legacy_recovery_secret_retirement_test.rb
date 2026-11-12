# frozen_string_literal: true

require "test_helper"

class AppLegacyRecoverySecretRetirementTest < ActionDispatch::IntegrationTest
  test "retired app recovery reveal has no anonymous GET HEAD or OPTIONS entry" do
    host!(ENV.fetch("PUBLIC_BASE_SERVICE_URL"))

    get "/identity/recovery-secret?ri=jp", env: { "action_dispatch.show_exceptions" => :all }

    assert_response :not_found

    head "/identity/recovery-secret?ri=jp", env: { "action_dispatch.show_exceptions" => :all }

    assert_response :not_found
    assert_empty response.body

    options "/identity/recovery-secret?ri=jp", env: { "action_dispatch.show_exceptions" => :all }

    assert_response :not_found
  end
end
