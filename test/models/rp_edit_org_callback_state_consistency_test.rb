# frozen_string_literal: true

require "test_helper"

class RpEditOrgCallbackStateConsistencyTest < ActiveSupport::TestCase
  test "Edit refuses duplicate callback state before persistence and retains PostgreSQL uniqueness" do
    attributes = {
      state_digest: Digest::SHA256.digest("edit-state"),
      browser_binding_digest: Digest::SHA256.digest("edit-browser"),
      nonce_digest: Digest::SHA256.digest("edit-nonce"),
      pkce_challenge: "challenge",
      pkce_verifier_ciphertext: "encrypted-verifier",
      issuer: "https://issuer.example.test",
      realm: "org",
      client_id: "edit-org-ww",
      expires_at: Time.utc(2030, 1, 1),
    }
    original = RpEditOrgCallbackState.create!(attributes)
    duplicate = RpEditOrgCallbackState.new(attributes)

    assert_not duplicate.valid?
    assert duplicate.errors.of_kind?(:state_digest, :taken)
    assert_raises(ActiveRecord::RecordInvalid) { duplicate.save! }
    assert_raises(ActiveRecord::RecordNotUnique) do
      RpEditOrgRecord.transaction(requires_new: true) do
        duplicate.save!(validate: false)
      end
    end
    assert_equal original.id, RpEditOrgCallbackState.find_by!(state_digest: attributes.fetch(:state_digest)).id

    original.update!(consumed_at: Time.utc(2029, 1, 1))

    assert_predicate original, :valid?
    assert_predicate original, :consumed?
    assert_not RpEditOrgCallbackState.new(attributes).valid?
    independent = RpEditOrgCallbackState.create!(attributes.merge(state_digest: Digest::SHA256.digest("other-state")))

    assert_not_equal original.id, independent.id
    assert_not_predicate independent, :consumed?
  end

  test "missing and empty callback digests are refused before persistence" do
    [nil, ""].each do |digest|
      callback = RpEditOrgCallbackState.new(state_digest: digest)

      assert_not callback.valid?
      assert callback.errors.of_kind?(:state_digest, :blank)
    end
  end
end
