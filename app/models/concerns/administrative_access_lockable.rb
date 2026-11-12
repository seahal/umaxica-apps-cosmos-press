# typed: false
# frozen_string_literal: true

# Historical access-state and reason vocabulary retained by AccountAccessEvent audit validation.
# The principal-side administrative locking implementation belongs outside Press.
module AdministrativeAccessLockable
  ACCESS_STATE_ENABLED = "enabled"
  ACCESS_STATE_ADMIN_LOCKED = "admin_locked"
  ACCESS_STATES = [ACCESS_STATE_ENABLED, ACCESS_STATE_ADMIN_LOCKED].freeze

  ADMIN_LOCK_REASON_CODES = %w(
    abuse
    security_incident
    chargeback
    terms_violation
    support_request
    legal_hold
    operator_error_recovery
    other
  ).freeze
end
