# typed: false
# frozen_string_literal: true

require "test_helper"

class PublishingEntryPolicyTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  setup do
    @entry = Publishing::Docs::App::Entry.new(locale: "ja")
  end

  test "an authenticated local principal cannot replace unavailable governance authority" do
    principal = RpEditOrgPrincipal.new(disabled_at: nil)
    policy = PublishingEntryPolicy.new(@entry, user: principal, access_token_claims: { "authn_ctx" => "normal" })

    assert_raises(GovernanceUnavailableError) { policy.apply(:index?) }
    assert_raises(GovernanceUnavailableError) { policy.apply(:show?) }
    assert_raises(GovernanceUnavailableError) { policy.apply(:create?) }
    assert_raises(GovernanceUnavailableError) { policy.apply(:update?) }
    assert_raises(GovernanceUnavailableError) { policy.apply(:destroy?) }
  end

  test "a disabled local principal is denied" do
    principal = RpEditOrgPrincipal.new(disabled_at: Time.current)
    policy = PublishingEntryPolicy.new(@entry, user: principal, access_token_claims: { "authn_ctx" => "normal" })

    assert_not policy.apply(:index?)
    assert_not policy.apply(:show?)
    assert_not policy.apply(:create?)
    assert_not policy.apply(:update?)
    assert_not policy.apply(:destroy?)
  end

  test "an unknown actor cannot publish" do
    policy = PublishingEntryPolicy.new(@entry, user: Object.new, access_token_claims: { "authn_ctx" => "normal" })

    assert_not policy.apply(:index?)
    assert_not policy.apply(:show?)
    assert_not policy.apply(:create?)
    assert_not policy.apply(:update?)
    assert_not policy.apply(:destroy?)
  end

  test "an absent actor is denied rather than defaulted" do
    policy = PublishingEntryPolicy.new(@entry, user: nil, access_token_claims: { "authn_ctx" => "normal" })

    assert_not policy.apply(:index?)
    assert_not policy.apply(:update?)
  end
end
