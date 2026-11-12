# typed: false
# frozen_string_literal: true

require "test_helper"

class JitSecurityJwtAnomalyReporterTest < ActiveSupport::TestCase
  test "reports authentication anomalies with bounded diagnostic data" do
    logs = []
    notifications = []
    notification = ->(*arguments) { notifications << arguments.last }

    ActiveSupport::Notifications.subscribed(notification, "jwt.anomaly.detected") do
      Rails.logger.stub(:info, ->(message) { logs << message }) do
        JitSecurityJwtAnomalyReporter.report_auth(
          resource_type: "operator",
          host: "staff.example.test",
          header: { "kid" => "key-1", "alg" => "RS256" },
          payload: { "iss" => "https://issuer.example.test", "aud" => ["edit-org-ww"], "jti" => "jti-1" },
          reason: "MISSING_SUB",
          error: ArgumentError.new("Missing required claim sub"),
        )
      end
    end

    event = notifications.fetch(0)

    assert_equal "AUTH_OPERATOR", event.fetch(:context)
    assert_equal "AUTH_OPERATOR_MISSING_SUB", event.fetch(:code)
    assert_equal ["edit-org-ww"], event.fetch(:aud)
    assert_equal 1, logs.length
    assert_not_includes logs.join, "access-token-secret"
  end

  test "reports preference anomalies and maps known or unknown missing claims" do
    logs = []
    Rails.logger.stub(:info, ->(message) { logs << message }) do
      JitSecurityJwtAnomalyReporter.report_preference(
        host: "org.example.test",
        header: { "typ" => "JWT" },
        payload: { "typ" => "JWT", "jti" => "preference-jti" },
        reason: "MISSING_PREFERENCE_TYPE",
      )
    end

    assert_equal 1, logs.length
    assert_includes logs.first, "ORG_PREFERENCE_MISSING_PREFERENCE_TYPE"
    assert_equal "MISSING_SUB", JitSecurityJwtAnomalyReporter.reason_for_missing_claim("Missing required claim sub")
    assert_equal "DECODE_ERROR", JitSecurityJwtAnomalyReporter.reason_for_missing_claim("invalid token")
  end
end
