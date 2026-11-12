# typed: false
# frozen_string_literal: true

require "test_helper"

class SignInSequenceTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  test "exposes a live sequence and matches its actor" do
    travel_to Time.zone.parse("2026-11-12 12:00:00") do
      actor = RpEditOrgPrincipal.new(id: 123)
      sequence = SignInSequence.new(
        id: "sequence-1",
        surface: "edit",
        actor_type: actor.class.name,
        actor_id: "123",
        method: "passkey",
        state: "MFA_PENDING",
        participant: "guardrail",
        pt: "/edit/org",
        safe_return_path: "/edit/org/safe",
        mfa_challenge_id: "challenge-1",
        session_limit_gate_id: "gate-1",
        terminal_state: nil,
        created_at: "2026-11-12T11:59:00Z",
        updated_at: "2026-11-12T11:59:30Z",
        expires_at: "2026-11-12T12:05:00Z",
      )

      assert_predicate sequence, :present?
      assert_not_predicate sequence, :blank?
      assert_equal "sequence-1", sequence.id
      assert_equal "edit", sequence.surface
      assert_equal actor.class.name, sequence.actor_type
      assert_equal "123", sequence.actor_id
      assert_equal "passkey", sequence.method
      assert_equal "MFA_PENDING", sequence.state
      assert_equal "guardrail", sequence.participant
      assert_equal "/edit/org", sequence.pt
      assert_equal "/edit/org/safe", sequence.safe_pt_path
      assert_equal "challenge-1", sequence.mfa_challenge_id
      assert_equal "gate-1", sequence.session_limit_gate_id
      assert_equal Time.zone.parse("2026-11-12 11:59:00"), sequence.created_at
      assert_equal Time.zone.parse("2026-11-12 11:59:30"), sequence.updated_at
      assert_equal Time.zone.parse("2026-11-12 12:05:00"), sequence.expires_at
      assert_not_predicate sequence, :expired?
      assert_not_predicate sequence, :terminal?
      assert sequence.actor_matches?(actor)
      assert_not sequence.actor_matches?(RpEditOrgPrincipal.new(id: 456))
      assert sequence.valid_for?(surface: :edit, actor:, participant: :guardrail)
    end
  end

  test "missing sequence has no identity and an invalid timestamp fails closed" do
    sequence = SignInSequence.missing

    assert_predicate sequence, :blank?
    assert_not_predicate sequence, :present?
    assert_nil sequence.actor_type
    assert_nil sequence.actor_id
    assert_nil sequence.created_at
    assert_nil sequence.updated_at
    assert_nil sequence.expires_at
    assert_predicate sequence, :expired?
    assert_not sequence.actor_matches?(nil)
    assert_not sequence.valid_for?(surface: :edit, actor: RpEditOrgPrincipal.new(id: 123), participant: :guardrail)

    invalid_time = SignInSequence.new("expires_at" => "not-a-timestamp")

    assert_nil invalid_time.expires_at
  end
end
