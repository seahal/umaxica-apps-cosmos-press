# typed: false
# frozen_string_literal: true

require "test_helper"

class StepUpRequirementTest < ActiveSupport::TestCase
  test "build normalizes and exposes every required step-up policy field" do
    attributes = {
      step_up_required: true,
      required_aal: "none",
      phishing_resistant_required: true,
      user_verification_required: true,
      full_reauthentication_required: false,
      allowed_methods: %w(Passkey totp TOTP),
      scope: :credential_change,
      session_binding: "session-1",
      token_binding: "token-1",
      ttl: 10.minutes,
      purpose: "step_up",
      audience: "edit-org-ww",
      require_session_binding: true,
      actor_ref: "operator-1",
      resource_ref: "resource-1",
      tenant_ref: "tenant-1",
    }

    requirement = StepUpRequirement.build(attributes)

    assert_predicate requirement, :step_up_required?
    assert_predicate requirement, :phishing_resistant_required?
    assert_predicate requirement, :user_verification_required?
    assert_not_predicate requirement, :full_reauthentication_required?
    assert_not_predicate requirement, :aal_required?
    assert_nil requirement.required_aal
    assert_equal %i(passkey totp), requirement.allowed_methods
    assert_equal "credential_change", requirement.scope
    assert_equal "session-1", requirement.session_binding
    assert_equal "token-1", requirement.token_binding
    assert_equal 10.minutes, requirement.ttl
    assert_equal "step_up", requirement.purpose
    assert_equal "edit-org-ww", requirement.audience
    assert requirement.require_session_binding
    assert_equal "operator-1", requirement.actor_ref
    assert_equal "resource-1", requirement.resource_ref
    assert_equal "tenant-1", requirement.tenant_ref
    assert requirement.method_allowed?("PASSKEY")
    assert_not requirement.method_allowed?("email")
    assert_not requirement.method_allowed?("")
    assert_equal(
      attributes.except(:required_aal, :allowed_methods).merge(
        allowed_methods: %i(passkey totp),
        scope: "credential_change",
      ),
      requirement.to_h,
    )
  end

  test "build accepts an existing requirement, keyword attributes, and a shorthand scope" do
    attributes = {
      step_up_required: true,
      phishing_resistant_required: false,
      user_verification_required: false,
      full_reauthentication_required: false,
      allowed_methods: [:totp],
      scope: "settings_email",
      session_binding: "session-1",
      token_binding: "token-1",
      ttl: 5.minutes,
      purpose: "step_up",
      audience: "edit-org-ww",
      require_session_binding: true,
      actor_ref: "operator-1",
      resource_ref: nil,
      tenant_ref: nil,
    }
    requirement = StepUpRequirement.build(nil, **attributes)

    assert_same requirement, StepUpRequirement.build(requirement)
    assert_equal requirement.to_h, StepUpRequirement.build(**attributes).to_h
    assert_equal "settings_email", StepUpRequirement.build("settings_email", **attributes.except(:scope)).scope
  end

  test "a disabled requirement has no step-up properties" do
    requirement = StepUpRequirement.build(step_up_required: false)

    assert_not_predicate requirement, :step_up_required?
    assert_equal({ step_up_required: false }, requirement.to_h)
    assert_empty requirement.allowed_methods
  end
end
